import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../screens/product_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'product_image.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final bool isWishlisted;
  final VoidCallback? onFavoriteTap;

  const ProductCard({
    super.key,
    required this.product,
    this.isWishlisted = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    
    // Find cart item for this product
    final cartItem = cartState.items.values
        .where((item) => item.productId == product.id)
        .firstOrNull;
    final isInCart = cartItem != null;
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: product,
              isWishlisted: isWishlisted,
              isInCart: isInCart,
              onToggleWishlist: onFavoriteTap,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.card,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: ProductImage(
                      source: product.image,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercent}% OFF',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.redAccent : AppColors.textDark,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flexible so the title gives up its second line in tight
                    // grid cells instead of overflowing the card.
                    Flexible(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Sale price
                    Text(
                      CurrencyFormatter.formatINR(product.price),
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    // MRP and discount row
                    if (product.hasDiscount)
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.formatINR(product.mrp!),
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Add to Cart button or Quantity selector
                    _buildCartButton(context, ref, isInCart, quantity),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context, WidgetRef ref, bool isInCart, int quantity) {
    if (isInCart) {
      // Show quantity selector (- qty +)
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Decrement button
            GestureDetector(
              onTap: () {
                final itemKey = '${product.id}_${product.id}';
                ref.read(cartProvider.notifier).decrementQuantity(itemKey);
              },
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Icon(
                  quantity <= 1 ? Icons.delete_outline : Icons.remove,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
              ),
            ),
            // Quantity display
            Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Increment button
            GestureDetector(
              onTap: () {
                final itemKey = '${product.id}_${product.id}';
                ref.read(cartProvider.notifier).incrementQuantity(itemKey);
              },
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show Add button
      return GestureDetector(
        onTap: () {
          ref.read(cartProvider.notifier).addItem(
            productId: product.id,
            variantId: product.id,
            price: product.price,
            productName: product.name,
            productImage: product.image,
            currencyCode: product.currencyCode,
          );
        },
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.onPrimary, size: 16),
              SizedBox(width: 4),
              Text(
                'ADD',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
