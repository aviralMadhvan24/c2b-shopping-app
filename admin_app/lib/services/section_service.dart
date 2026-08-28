import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store_section.dart';
import 'product_service.dart';

/// Manages the `sections` collection — the store's catalog sections.
///
/// The storefront currently hardcodes its three sections. This collection is
/// the shared source of truth going forward: [ensureSeeded] plants those same
/// three on first run so the console and the app agree from day one, and
/// wiring the app to read from here is a one-line repository change.
class SectionService {
  final FirebaseFirestore _firestore;
  final ProductService _products;

  SectionService({FirebaseFirestore? firestore, ProductService? productService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _products = productService ??
            ProductService(firestore: firestore ?? FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _sections =>
      _firestore.collection('sections');

  /// The sections the storefront ships with today. Seeded once, then owned
  /// entirely by the console.
  static const List<({String name, String icon})> _defaults = [
    (name: 'Clothes', icon: 'checkroom'),
    (name: 'Second-hand Laptops', icon: 'laptop'),
    (name: 'Second-hand Printers', icon: 'print'),
  ];

  Stream<List<StoreSection>> watchAll() {
    return _sections.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => StoreSection.fromMap(d.id, d.data())).toList();
      list.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Future<List<StoreSection>> fetchAll() async {
    final snap = await _sections.get();
    final list =
        snap.docs.map((d) => StoreSection.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Creates the default sections if the collection is empty. Safe to call on
  /// every launch: it no-ops the moment even one section exists, so a shop
  /// that deleted "Clothes" on purpose does not get it back.
  Future<void> ensureSeeded() async {
    final existing = await _sections.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (var i = 0; i < _defaults.length; i++) {
      final d = _defaults[i];
      batch.set(_sections.doc(), {
        'name': d.name,
        'iconKey': d.icon,
        'imageUrl': null,
        'sortOrder': i,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> create(StoreSection section) => _sections.doc().set(section.toMap());

  Future<void> update(StoreSection section) =>
      _sections.doc(section.id).set(section.toMap(), SetOptions(merge: true));

  /// Renames a section and carries its products across, because a product
  /// stores its section by name. Returns how many products moved.
  ///
  /// The products are moved *before* the section document changes: if the
  /// batch fails partway, some products point at the new name while the
  /// section still holds the old one — visible and fixable by retrying. The
  /// other order would strand products under a name no section claims.
  Future<int> rename(StoreSection section, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == section.name) return 0;

    final moved =
        await _products.reassignSection(from: section.name, to: trimmed);
    await update(section.copyWith(name: trimmed));
    return moved;
  }

  /// Deletes a section. Refuses while products still reference it — an
  /// orphaned product would vanish from every storefront listing while
  /// staying live at its direct link.
  Future<void> delete(StoreSection section) async {
    final count = await _products.countInSection(section.name);
    if (count > 0) {
      throw SectionNotEmptyException(section.name, count);
    }
    await _sections.doc(section.id).delete();
  }

  Future<void> setActive(String id, bool active) =>
      _sections.doc(id).update({'active': active});

  /// Persists a new display order after a drag-and-drop reorder.
  Future<void> reorder(List<StoreSection> ordered) async {
    final batch = _firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_sections.doc(ordered[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }
}

class SectionNotEmptyException implements Exception {
  SectionNotEmptyException(this.sectionName, this.productCount);

  final String sectionName;
  final int productCount;

  @override
  String toString() => '"$sectionName" still has $productCount '
      '${productCount == 1 ? 'product' : 'products'}. Move or delete them first.';
}
