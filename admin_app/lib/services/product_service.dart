import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

/// Read and write the `products` collection the storefront serves from.
class ProductService {
  final FirebaseFirestore _firestore;

  ProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  /// The whole catalog, newest first.
  ///
  /// A shop this size has tens to low hundreds of products, so the console
  /// streams the lot and filters in memory — that keeps search, section
  /// filtering and the stock counters instant and consistent, with no
  /// composite index per filter combination. Revisit with paging if the
  /// catalog ever runs into the thousands.
  Stream<List<AdminProduct>> watchAll() {
    return _products.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AdminProduct.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        // Seeded products predate createdAt; sort those to the bottom by name
        // rather than letting a null shuffle the list on every rebuild.
        if (at == null && bt == null) return a.name.compareTo(b.name);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Stream<AdminProduct?> watchOne(String id) => _products.doc(id).snapshots().map(
        (d) => d.exists ? AdminProduct.fromMap(d.id, d.data()!) : null,
      );

  /// Creates a product and returns its generated id.
  ///
  /// The document id is also written into the `id` field because the
  /// storefront's seeded products carry one, and its `Product.fromMap` falls
  /// back to it — keeping both in sync avoids a class of "product not found"
  /// bugs when a document is copied around.
  Future<String> create(AdminProduct product) async {
    final ref = _products.doc();
    await ref.set(product.copyWith(id: ref.id).toMap());
    return ref.id;
  }

  Future<void> update(AdminProduct product) async {
    if (product.id.isEmpty) {
      throw ArgumentError('Cannot update a product with no id.');
    }
    await _products.doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String id) => _products.doc(id).delete();

  /// Publish / unpublish without opening the editor.
  Future<void> setActive(String id, bool active) => _products.doc(id).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Stock correction from the products table. Clamped at zero so a mistyped
  /// adjustment cannot push the catalog into negative inventory.
  Future<void> setStock(String id, int stock) => _products.doc(id).update({
        'stock': stock < 0 ? 0 : stock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Moves every product in [from] to [to]. Used when a section is renamed,
  /// because products reference their section by name.
  Future<int> reassignSection({required String from, required String to}) async {
    final snap = await _products.where('category', isEqualTo: from).get();
    if (snap.docs.isEmpty) return 0;

    // Firestore caps a batch at 500 writes; chunk so a large section rename
    // does not fail halfway.
    const chunkSize = 400;
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      for (final doc in snap.docs.skip(i).take(chunkSize)) {
        batch.update(doc.reference, {
          'category': to,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
    return snap.docs.length;
  }

  /// How many products sit in a section — the guard before deleting one.
  Future<int> countInSection(String sectionName) async {
    final snap =
        await _products.where('category', isEqualTo: sectionName).count().get();
    return snap.count ?? 0;
  }
}
