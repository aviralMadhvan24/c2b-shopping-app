import 'package:flutter/material.dart';

/// A catalog section — the categories shoppers browse.
///
/// Stored at `sections/{id}` and owned entirely by the admin console
/// (`admin_app/`). The app only reads them, so there is no `toMap` here.
///
/// A product joins a section by [name], not by id: `Product.category` holds
/// the section's name. That is why renaming a section in the console rewrites
/// every product in it.
class StoreSection {
  final String id;
  final String name;
  final String iconKey;
  final String? imageUrl;
  final int sortOrder;
  final bool active;

  const StoreSection({
    required this.id,
    required this.name,
    this.iconKey = 'category',
    this.imageUrl,
    this.sortOrder = 0,
    this.active = true,
  });

  IconData get icon => SectionIcons.resolve(iconKey);

  factory StoreSection.fromMap(String id, Map<String, dynamic> map) =>
      StoreSection(
        id: id,
        name: map['name'] as String? ?? '',
        iconKey: map['iconKey'] as String? ?? 'category',
        imageUrl: map['imageUrl'] as String?,
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        active: map['active'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreSection &&
        other.id == id &&
        other.name == name &&
        other.iconKey == iconKey &&
        other.imageUrl == imageUrl &&
        other.sortOrder == sortOrder &&
        other.active == active;
  }

  @override
  int get hashCode => Object.hash(id, name, iconKey, imageUrl, sortOrder, active);
}

/// Icons keyed by short strings rather than raw codepoints, because Flutter
/// tree-shakes icon fonts — a dynamically built `IconData` renders as a blank
/// box in a release build. Every icon here is referenced statically.
///
/// This map must stay in step with `SectionIcons` in
/// `admin_app/lib/models/store_section.dart`: the console writes these keys.
/// An unknown key falls back to a generic icon rather than breaking the row,
/// so the two drifting apart degrades instead of crashing.
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
}
