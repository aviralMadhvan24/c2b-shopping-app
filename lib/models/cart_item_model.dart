class CartItem {
  final String productId;
  final String variantId;
  final String productName;
  final String productImage;
  final double price;
  final String currencyCode;
  final int quantity; // 1..99

  const CartItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.currencyCode,
    required this.quantity,
  });

  String get itemKey => '${productId}_$variantId';
  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'currencyCode': currencyCode,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String,
      variantId: map['variantId'] as String,
      productName: map['productName'] as String,
      productImage: map['productImage'] as String,
      price: (map['price'] as num).toDouble(),
      currencyCode: map['currencyCode'] as String,
      quantity: map['quantity'] as int,
    );
  }

  CartItem copyWith({
    String? productId,
    String? variantId,
    String? productName,
    String? productImage,
    double? price,
    String? currencyCode,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.productId == productId &&
        other.variantId == variantId &&
        other.productName == productName &&
        other.productImage == productImage &&
        other.price == price &&
        other.currencyCode == currencyCode &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return Object.hash(
      productId,
      variantId,
      productName,
      productImage,
      price,
      currencyCode,
      quantity,
    );
  }
}
