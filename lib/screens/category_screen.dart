import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../repositories/app_repositories.dart';
import '../widgets/product_card.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final AppRepositories repositories;
  final Function(Product)? onToggleWishlist;
  final Function(Product)? onAddToCart;
  final bool Function(Product)? isWishlisted;
  final bool Function(Product)? isInCart;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.repositories,
    this.onToggleWishlist,
    this.onAddToCart,
    this.isWishlisted,
    this.isInCart,
  });

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return GridView.builder(
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.67,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return ProductCard(
                  product: product,
                  isWishlisted: isWishlisted?.call(product) ?? false,
                  isInCart: isInCart?.call(product) ?? false,
                  onFavoriteTap: () => onToggleWishlist?.call(product),
                  onAddToCartTap: () => onAddToCart?.call(product),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
