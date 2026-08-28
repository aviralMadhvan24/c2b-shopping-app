import 'package:cloud_firestore/cloud_firestore.dart';

/// A catalog product, stored at `products/{productId}`.
///
/// The first block of fields is the contract the customer app's
/// `Product.fromMap` reads — renaming or dropping any of them breaks the
/// storefront. Everything after `--- admin-only ---` is extra bookkeeping the
/// customer app simply ignores (its parser skips unknown keys), which is what
/// lets the console track stock and publish state without a storefront change.
class AdminProduct {
  final String id;
  final String name;
  final String image;
  final double price;
  final String currencyCode;
  final String category;
  final double rating;
  final String description;
  final List<AdminVariant> variants;
  final double? mrp;
  final int? discountPercent;

  // --- admin-only ---
  /// Every uploaded photo. `image` is always `images.first`, kept as a
  /// separate scalar because that is the field the storefront reads.
  final List<String> images;
  final int stock;
  final bool active;
  final String? sku;
  final String? brand;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.currencyCode = 'INR',
    required this.category,
    this.rating = 0,
    this.description = '',
    this.variants = const [],
    this.mrp,
    this.discountPercent,
    this.images = const [],
    this.stock = 0,
    this.active = true,
    this.sku,
    this.brand,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminProduct.empty() => const AdminProduct(
        id: '',
        name: '',
        image: '',
        price: 0,
        category: '',
      );

  bool get hasDiscount => mrp != null && mrp! > price;
  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;

  /// Stock at or below this is surfaced on the dashboard as "running low".
  static const int lowStockThreshold = 5;

  /// Discount derived from MRP, so the badge never contradicts the prices.
  int get computedDiscountPercent {
    if (!hasDiscount) return 0;
    return (((mrp! - price) / mrp!) * 100).round();
  }

  Map<String, dynamic> toMap() {
    return {
      // Storefront contract
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'currencyCode': currencyCode,
      'category': category,
      'rating': rating,
      'description': description,
      'variants': variants.map((v) => v.toMap()).toList(),
      'mrp': mrp,
      'discountPercent': hasDiscount ? computedDiscountPercent : null,
      // Admin-only
      'images': images,
      'stock': stock,
      'active': active,
      'sku': sku,
      'brand': brand,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AdminProduct.fromMap(String id, Map<String, dynamic> map) {
    final images = (map['images'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
    final primary = map['image'] as String? ?? '';
    return AdminProduct(
      id: id,
      name: map['name'] as String? ?? '',
      image: primary,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currencyCode: map['currencyCode'] as String? ?? 'INR',
      category: map['category'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => AdminVariant.fromMap(Map<String, dynamic>.from(v as Map)))
              .toList() ??
          const [],
      mrp: (map['mrp'] as num?)?.toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toInt(),
      // Products seeded before the console existed have no `images` array;
      // fall back to the single storefront image so they still render.
      images: images.isNotEmpty ? images : (primary.isEmpty ? const <String>[] : [primary]),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
      sku: map['sku'] as String?,
      brand: map['brand'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  AdminProduct copyWith({
    String? id,
    String? name,
    String? image,
    double? price,
    String? currencyCode,
    String? category,
    double? rating,
    String? description,
    List<AdminVariant>? variants,
    double? mrp,
    bool clearMrp = false,
    int? discountPercent,
    List<String>? images,
    int? stock,
    bool? active,
    String? sku,
    String? brand,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      variants: variants ?? this.variants,
      mrp: clearMrp ? null : (mrp ?? this.mrp),
      discountPercent: discountPercent ?? this.discountPercent,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      active: active ?? this.active,
      sku: sku ?? this.sku,
      brand: brand ?? this.brand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// A purchasable option of a product — a clothing size, a laptop RAM tier.
class AdminVariant {
  final String id;
  final String title;
  final double price;
  final String currencyCode;
  final bool availableForSale;
  final int? quantityAvailable;
  final Map<String, String> selectedOptions;
  final String? image;

  const AdminVariant({
    required this.id,
    required this.title,
    required this.price,
    this.currencyCode = 'INR',
    this.availableForSale = true,
    this.quantityAvailable,
    this.selectedOptions = const {},
    this.image,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'price': price,
        'currencyCode': currencyCode,
        'availableForSale': availableForSale,
        'quantityAvailable': quantityAvailable,
        'selectedOptions': Map<String, String>.from(selectedOptions),
        'image': image,
      };

  factory AdminVariant.fromMap(Map<String, dynamic> map) => AdminVariant(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        currencyCode: map['currencyCode'] as String? ?? 'INR',
        availableForSale: map['availableForSale'] as bool? ?? true,
        quantityAvailable: (map['quantityAvailable'] as num?)?.toInt(),
        selectedOptions:
            Map<String, String>.from(map['selectedOptions'] as Map? ?? const {}),
        image: map['image'] as String?,
      );

  AdminVariant copyWith({
    String? title,
    double? price,
    bool? availableForSale,
    int? quantityAvailable,
    bool clearQuantity = false,
  }) {
    return AdminVariant(
      id: id,
      title: title ?? this.title,
      price: price ?? this.price,
      currencyCode: currencyCode,
      availableForSale: availableForSale ?? this.availableForSale,
      quantityAvailable:
          clearQuantity ? null : (quantityAvailable ?? this.quantityAvailable),
      selectedOptions: selectedOptions,
      image: image,
    );
  }
}
