import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../providers/wishlist_provider.dart';
import '../repositories/app_repositories.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';

class CategoryScreen extends ConsumerWidget {
  final String category;
  final AppRepositories repositories;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.repositories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Product>>(
          future: repositories.productRepository.fetchProductsByCategory(
            category,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredProducts = snapshot.data ?? [];

            if (filteredProducts.isEmpty) {
              return const Center(
                child: Text(
                  "No products available",
                  style: TextStyle(color: AppColors.textDark),
                ),
              );
            }

            return GridView.builder(
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final wishlistState = ref.watch(wishlistProvider);
                final isWishlisted = wishlistState.items.containsKey(product.id);
                
                return ProductCard(
                  product: product,
                  isWishlisted: isWishlisted,
                  onFavoriteTap: () {
                    if (isWishlisted) {
                      ref.read(wishlistProvider.notifier).removeItem(product.id);
                    } else {
                      ref.read(wishlistProvider.notifier).addItem(product.id);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
