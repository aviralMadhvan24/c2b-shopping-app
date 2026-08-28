import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../providers/analytics_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/variant_selector.dart';
import 'cart_screen.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  final bool isWishlisted;
  final bool isInCart;
  final VoidCallback? onToggleWishlist;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isWishlisted = false,
    this.isInCart = false,
    this.onToggleWishlist,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late String _displayImage;

  @override
  void initState() {
    super.initState();
    _displayImage = widget.product.image;

    // If product has variants, set image from pre-selected variant
    if (widget.product.hasVariants) {
      final defaultVariant = preselectVariant(widget.product.variants);
      if (defaultVariant?.image != null && defaultVariant!.image!.isNotEmpty) {
        _displayImage = defaultVariant.image!;
      }
    }

    // Log product viewed analytics event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logProductViewed(
            widget.product.id,
            widget.product.category,
          );
    });
  }

  void _onVariantChanged(ProductVariant? variant) {
    if (variant?.image != null && variant!.image!.isNotEmpty) {
      setState(() {
        _displayImage = variant.image!;
      });
    } else {
      setState(() {
        _displayImage = widget.product.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    
    // Find cart item for this product
    final cartItem = cartState.items.values
        .where((item) => item.productId == widget.product.id)
        .firstOrNull;
    final isInCart = cartItem != null;
    final quantity = cartItem?.quantity ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      ProductImage(
                        source: _displayImage,
                        height: 360,
                        width: double.infinity,
                        placeholderIconSize: 64,
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: AppColors.textGrey,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      // Cart & Wishlist buttons
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.textGrey,
                              child: IconButton(
                                icon: Icon(
                                  widget.isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isWishlisted
                                      ? Colors.redAccent
                                      : AppColors.textDark,
                                ),
                                onPressed: widget.onToggleWishlist,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.textGrey,
                                  child: IconButton(
                                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textDark),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const CartScreen()),
                                      );
                                    },
                                  ),
                                ),
                                if (cartState.distinctItemCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                      child: Text(
                                        '${cartState.distinctItemCount}',
                                        style: const TextStyle(
                                          color: AppColors.onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Discount badge
                      if (widget.product.hasDiscount)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 60,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.product.discountPercent}% OFF',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Rating
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.product.rating.toString(),
                                    style: const TextStyle(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, color: AppColors.textDark, size: 14),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(widget.product.rating * 127).toInt()} ratings',
                              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Price section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatINR(widget.product.price),
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.product.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                CurrencyFormatter.formatINR(widget.product.mrp!),
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 18,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.product.discountPercent}% off',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inclusive of all taxes',
                          style: TextStyle(color: AppColors.textLight, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        // Delivery info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.local_shipping, color: AppColors.success, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Express Delivery',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Within 1-2 hours • Free above ₹499',
                                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.description,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Variant selector for products with variants
                        if (widget.product.hasVariants)
                          VariantSelector(
                            product: widget.product,
                            onVariantChanged: _onVariantChanged,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Add to Cart / Quantity selector
          _buildBottomBar(isInCart, quantity),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isInCart, int quantity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: isInCart
            ? Row(
                children: [
                  // Quantity selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrement
                        GestureDetector(
                          onTap: () {
                            final itemKey = '${widget.product.id}_${widget.product.id}';
                            ref.read(cartProvider.notifier).decrementQuantity(itemKey);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              quantity <= 1 ? Icons.delete_outline : Icons.remove,
                              color: quantity <= 1 ? AppColors.danger : AppColors.gold,
                              size: 22,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Increment
                        GestureDetector(
                          onTap: () {
                            final itemKey = '${widget.product.id}_${widget.product.id}';
                            ref.read(cartProvider.notifier).incrementQuantity(itemKey);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.add, color: AppColors.gold, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Go to Cart button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'GO TO CART',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(
                      productId: widget.product.id,
                      variantId: widget.product.id,
                      price: widget.product.price,
                      productName: widget.product.name,
                      productImage: widget.product.image,
                      currencyCode: widget.product.currencyCode,
                    );

                    // Log analytics
                    ref.read(analyticsServiceProvider).logAddToCart(
                      widget.product.id,
                      widget.product.id,
                      widget.product.price,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to cart'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
