import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A catalog section (what the storefront calls a category), stored at
/// `sections/{sectionId}`.
///
/// Products join a section by its [name], not its document id — the customer
/// app queries `products.where('category', isEqualTo: 'Clothes')`. That is why
/// renaming a section has to rewrite every product in it; see
/// `SectionService.rename`.
class StoreSection {
  final String id;
  final String name;
  final String iconKey;
  final String? imageUrl;
  final int sortOrder;
  final bool active;
  final DateTime? createdAt;

  const StoreSection({
    required this.id,
    required this.name,
    this.iconKey = 'category',
    this.imageUrl,
    this.sortOrder = 0,
    this.active = true,
    this.createdAt,
  });

  IconData get icon => SectionIcons.resolve(iconKey);

  Map<String, dynamic> toMap() => {
        'name': name,
        'iconKey': iconKey,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'active': active,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory StoreSection.fromMap(String id, Map<String, dynamic> map) =>
      StoreSection(
        id: id,
        name: map['name'] as String? ?? '',
        iconKey: map['iconKey'] as String? ?? 'category',
        imageUrl: map['imageUrl'] as String?,
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        active: map['active'] as bool? ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  StoreSection copyWith({
    String? name,
    String? iconKey,
    String? imageUrl,
    bool clearImage = false,
    int? sortOrder,
    bool? active,
  }) =>
      StoreSection(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
        sortOrder: sortOrder ?? this.sortOrder,
        active: active ?? this.active,
        createdAt: createdAt,
      );
}

/// Icons are stored as short string keys rather than raw codepoints because
/// Flutter tree-shakes icon fonts: a dynamically constructed `IconData` would
/// render as a blank box in a release web build. Everything selectable here is
/// referenced statically, so it survives the shake.
class SectionIcons {
  static const Map<String, IconData> all = {
    'category': Icons.category_outlined,
    'checkroom': Icons.checkroom,
    'laptop': Icons.laptop_mac,
    'print': Icons.print_outlined,
    'phone': Icons.smartphone,
    'headphones': Icons.headphones,
    'watch': Icons.watch,
    'shoe': Icons.ice_skating,
    'bag': Icons.shopping_bag_outlined,
    'home': Icons.chair_outlined,
    'kitchen': Icons.kitchen_outlined,
    'book': Icons.menu_book_outlined,
    'toy': Icons.toys_outlined,
    'sports': Icons.sports_basketball_outlined,
    'beauty': Icons.spa_outlined,
    'grocery': Icons.local_grocery_store_outlined,
    'tv': Icons.tv,
    'camera': Icons.photo_camera_outlined,
    'tools': Icons.build_outlined,
    'gift': Icons.card_giftcard,
  };

  static IconData resolve(String key) => all[key] ?? Icons.category_outlined;

  static List<String> get keys => all.keys.toList();
}
