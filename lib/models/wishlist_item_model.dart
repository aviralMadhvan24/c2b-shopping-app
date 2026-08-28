class WishlistItem {
  final String productId;
  final String? variantId;
  final DateTime addedAt;

  const WishlistItem({
    required this.productId,
    required this.addedAt,
    this.variantId,
  });

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistItem.fromMap(Map<String, Object?> map) {
    return WishlistItem(
      productId: map['productId'] as String,
      variantId: map['variantId'] as String?,
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem &&
        other.productId == productId &&
        other.variantId == variantId &&
        other.addedAt == addedAt;
  }

  @override
  int get hashCode {
    return Object.hash(productId, variantId, addedAt);
  }
}
