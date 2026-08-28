import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/section_model.dart';
import '../providers/pagination_provider.dart';
import '../providers/section_provider.dart';
import '../providers/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class CategoriesScreenNew extends ConsumerStatefulWidget {
  const CategoriesScreenNew({super.key});

  @override
  ConsumerState<CategoriesScreenNew> createState() => _CategoriesScreenNewState();
}

class _CategoriesScreenNewState extends ConsumerState<CategoriesScreenNew> {
  /// The section being browsed, by name. Null means "All".
  ///
  /// Deliberately a name rather than an index: the section list is live now,
  /// so an index would silently point at the wrong section the moment the shop
  /// reorders or removes one. A name that disappears just falls back to All.
  String? _selectedSection;
  String _searchQuery = '';

  void _toggleWishlist(Product product) {
    final wishlistState = ref.read(wishlistProvider);
    if (wishlistState.items.containsKey(product.id)) {
      ref.read(wishlistProvider.notifier).removeItem(product.id);
    } else {
      ref.read(wishlistProvider.notifier).addItem(product.id);
    }
  }

  bool _isWishlisted(Product product) {
    final wishlistState = ref.watch(wishlistProvider);
    return wishlistState.items.containsKey(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final paginationState = ref.watch(paginationProvider);
    final products = paginationState.items;
    final sections = ref.watch(sectionsProvider).valueOrNull ?? const <StoreSection>[];
    final filteredProducts = _getFilteredProducts(products);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'Search in categories...',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.textDark),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Body: sidebar + products
        Expanded(
          child: Row(
            children: [
              // Left sidebar
              Container(
                width: 90,
                color: AppColors.surface,
                child: ListView.builder(
                  // Index 0 is the built-in "All"; the rest are live sections.
                  itemCount: sections.length + 1,
                  itemBuilder: (context, index) {
                    final name = index == 0 ? null : sections[index - 1].name;
                    final label = index == 0 ? 'All' : sections[index - 1].name;
                    final icon =
                        index == 0 ? Icons.apps : sections[index - 1].icon;
                    final isSelected = name == _selectedSection;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSection = name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.card : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? AppColors.gold : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              icon,
                              color: isSelected ? AppColors.gold : AppColors.textLight,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? AppColors.gold : AppColors.textGrey,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Right side - Products
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, color: AppColors.textLight, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No products found',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ProductCard(
                            product: product,
                            isWishlisted: _isWishlisted(product),
                            onFavoriteTap: () => _toggleWishlist(product),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Filter by section
    final section = _selectedSection;
    if (section != null) {
      filtered = filtered.where((p) => p.category == section).toList();
    }

    // Filter by search
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}
