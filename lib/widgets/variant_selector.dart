import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../providers/analytics_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

/// Extracts all option groups from a list of variants.
///
/// Returns a map where keys are option names (e.g., "Size", "Color")
/// and values are the distinct option values for that group in list order.
Map<String, List<String>> extractOptionGroups(List<ProductVariant> variants) {
  final groups = <String, List<String>>{};
  for (final variant in variants) {
    for (final entry in variant.selectedOptions.entries) {
      groups.putIfAbsent(entry.key, () => []);
      if (!groups[entry.key]!.contains(entry.value)) {
        groups[entry.key]!.add(entry.value);
      }
    }
  }
  return groups;
}

/// Resolves the variant that matches all currently selected options.
///
/// Returns null if no variant matches the full combination.
ProductVariant? resolveVariant(
  List<ProductVariant> variants,
  Map<String, String> selectedOptions,
) {
  for (final variant in variants) {
    bool matches = true;
    for (final entry in selectedOptions.entries) {
      if (variant.selectedOptions[entry.key] != entry.value) {
        matches = false;
        break;
      }
    }
    if (matches) return variant;
  }
  return null;
}

/// Returns the pre-selected (default) variant: first available-for-sale,
/// or the first variant if none are available.
ProductVariant? preselectVariant(List<ProductVariant> variants) {
  if (variants.isEmpty) return null;
  for (final variant in variants) {
    if (variant.availableForSale) return variant;
  }
  return variants.first;
}

/// A widget that displays product variant options grouped by option name
/// and allows users to select variant combinations.
///
/// Handles price/availability display, Add to Cart, and image updates.
/// Hides itself entirely when the product has no variants.
class VariantSelector extends ConsumerStatefulWidget {
  const VariantSelector({
    super.key,
    required this.product,
    this.onVariantChanged,
  });

  final Product product;

  /// Callback fired when the resolved variant changes (for image updates).
  final void Function(ProductVariant? variant)? onVariantChanged;

  @override
  ConsumerState<VariantSelector> createState() => _VariantSelectorState();
}

class _VariantSelectorState extends ConsumerState<VariantSelector> {
  late Map<String, String> _selectedOptions;
  late Map<String, List<String>> _optionGroups;

  @override
  void initState() {
    super.initState();
    _optionGroups = extractOptionGroups(widget.product.variants);
    final defaultVariant = preselectVariant(widget.product.variants);
    _selectedOptions = defaultVariant != null
        ? Map<String, String>.from(defaultVariant.selectedOptions)
        : {};
  }

  ProductVariant? get _resolvedVariant =>
      resolveVariant(widget.product.variants, _selectedOptions);

  void _onOptionSelected(String optionName, String optionValue) {
    setState(() {
      _selectedOptions[optionName] = optionValue;
    });
    widget.onVariantChanged?.call(_resolvedVariant);
  }

  Future<void> _onAddToCart() async {
    final variant = _resolvedVariant;
    if (variant == null || !variant.availableForSale) return;

    await ref.read(cartProvider.notifier).addItem(
          productId: widget.product.id,
          variantId: variant.id,
          price: variant.price,
          productName: widget.product.name,
          productImage: variant.image ?? widget.product.image,
          currencyCode: variant.currencyCode,
        );

    // Log add_to_cart analytics event
    ref.read(analyticsServiceProvider).logAddToCart(
          widget.product.id,
          variant.id,
          variant.price,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.product.hasVariants) {
      return const SizedBox.shrink();
    }

    final resolvedVariant = _resolvedVariant;
    final isAvailable = resolvedVariant?.availableForSale ?? false;
    final displayPrice = resolvedVariant?.price ?? widget.product.price;
    final displayCurrency =
        resolvedVariant?.currencyCode ?? widget.product.currencyCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price and availability
        Row(
          children: [
            Text(
              '$displayCurrency ${displayPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            if (!isAvailable)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sold Out',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Option groups
        ..._optionGroups.entries.map((group) {
          return _buildOptionGroup(group.key, group.value);
        }),

        const SizedBox(height: 24),

        // Add to Cart button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? AppColors.textDark : Colors.grey.shade700,
              foregroundColor: isAvailable ? AppColors.onPrimary : AppColors.textGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: isAvailable ? _onAddToCart : null,
            child: Text(
              isAvailable ? 'Add To Cart' : 'Sold Out',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionGroup(String optionName, List<String> values) {
    final selectedValue = _selectedOptions[optionName];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            optionName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: values.map((value) {
              final isSelected = selectedValue == value;
              return GestureDetector(
                onTap: () => _onOptionSelected(optionName, value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD4AF37)
                        : AppColors.textDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isSelected ? AppColors.onPrimary : AppColors.textDark,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
