class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String currencyCode;
  final String category;
  final double rating;
  final String description;
  final List<ProductVariant> variants;
  final double? mrp;
  final int? discountPercent;

  /// Whether the admin console publishes this product to the storefront.
  ///
  /// Defaults to true so products created before the console existed — which
  /// carry no `active` field at all — keep showing rather than vanishing.
  final bool active;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.currencyCode = 'INR',
    required this.category,
    required this.rating,
    required this.description,
    this.variants = const [],
    this.mrp,
    this.discountPercent,
    this.active = true,
  });

  bool get hasDiscount => mrp != null && mrp! > price;

  Map<String, dynamic> toMap() {
    return {
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
      'discountPercent': discountPercent,
      'active': active,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, [String? id]) {
    return Product(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currencyCode: map['currencyCode'] ?? 'INR',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      mrp: map['mrp'] != null ? (map['mrp'] as num).toDouble() : null,
      discountPercent: map['discountPercent'] as int?,
      active: map['active'] as bool? ?? true,
    );
  }

  bool get hasVariants => variants.isNotEmpty;

  ProductVariant? get defaultVariant {
    if (variants.isEmpty) {
      return null;
    }

    return variants.firstWhere(
      (variant) => variant.availableForSale,
      orElse: () => variants.first,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Product) return false;
    return other.id == id &&
        other.name == name &&
        other.image == image &&
        other.price == price &&
        other.currencyCode == currencyCode &&
        other.category == category &&
        other.rating == rating &&
        other.description == description &&
        other.mrp == mrp &&
        other.discountPercent == discountPercent &&
        other.active == active &&
        _listEquals(other.variants, variants);
  }

  @override
  int get hashCode {
    return Object.hash(
      id, name, image, price, currencyCode, category, rating, description,
      mrp, discountPercent, active,
    );
  }

  static bool _listEquals(List<ProductVariant> a, List<ProductVariant> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ProductVariant {
  final String id;
  final String title;
  final double price;
  final String currencyCode;
  final bool availableForSale;
  final int? quantityAvailable;
  final Map<String, String> selectedOptions;
  final String? image;

  const ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    this.currencyCode = 'INR',
    this.availableForSale = true,
    this.quantityAvailable,
    this.selectedOptions = const {},
    this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'currencyCode': currencyCode,
      'availableForSale': availableForSale,
      'quantityAvailable': quantityAvailable,
      'selectedOptions': Map<String, String>.from(selectedOptions),
      'image': image,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currencyCode: map['currencyCode'] ?? 'INR',
      availableForSale: map['availableForSale'] ?? true,
      quantityAvailable: map['quantityAvailable'],
      selectedOptions: Map<String, String>.from(map['selectedOptions'] ?? {}),
      image: map['image'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductVariant) return false;
    return other.id == id &&
        other.title == title &&
        other.price == price &&
        other.currencyCode == currencyCode &&
        other.availableForSale == availableForSale &&
        other.quantityAvailable == quantityAvailable &&
        other.image == image &&
        _mapEquals(other.selectedOptions, selectedOptions);
  }

  @override
  int get hashCode {
    return Object.hash(
      id, title, price, currencyCode, availableForSale, quantityAvailable, image,
    );
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
