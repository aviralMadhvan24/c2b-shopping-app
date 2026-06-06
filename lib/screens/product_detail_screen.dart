import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final bool isWishlisted;
  final bool isInCart;
  final VoidCallback? onToggleWishlist;
  final VoidCallback? onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isWishlisted = false,
    this.isInCart = false,
    this.onToggleWishlist,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  product.image,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: onToggleWishlist,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isInCart
                              ? Icons.shopping_cart
                              : Icons.add_shopping_cart,
                          color: Colors.white,
                        ),
                        onPressed: onAddToCart,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 5),
                      Text(
                        product.rating.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    product.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "\$${product.price}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: onAddToCart,
                      child: Text(
                        isInCart ? "Added to Cart" : "Add To Cart",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
