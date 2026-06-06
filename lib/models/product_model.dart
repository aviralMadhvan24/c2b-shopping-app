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

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.currencyCode = 'USD',
    required this.category,
    required this.rating,
    required this.description,
    this.variants = const [],
  });

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
}

class ProductVariant {
  final String id;
  final String title;
  final double price;
  final String currencyCode;
  final bool availableForSale;
  final int? quantityAvailable;
  final Map<String, String> selectedOptions;

  const ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    this.currencyCode = 'USD',
    this.availableForSale = true,
    this.quantityAvailable,
    this.selectedOptions = const {},
  });
}
