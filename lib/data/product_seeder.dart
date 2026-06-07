import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductSeeder {
  static Future<void> seedProducts() async {
    final firestore = FirebaseFirestore.instance;
    final productsCollection = firestore.collection('products');

    // Check if products already exist to avoid duplicates
    final existing = await productsCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      debugPrint('Products already exist in Firestore. Skipping seed.');
      return;
    }

    final demoProducts = [
      {
        'name': 'Urban Oversized Hoodie',
        'description': 'Premium heavy cotton blend hoodie with a modern oversized fit. Perfect for street style.',
        'price': 45.00,
        'category': 'Clothing',
        'image': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&q=80&w=1000',
        'rating': 4.8,
        'currencyCode': 'USD',
      },
      {
        'name': 'Classic Canvas Sneakers',
        'description': 'Comfortable and durable canvas sneakers for everyday wear.',
        'price': 35.00,
        'category': 'Shoes',
        'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&q=80&w=1000',
        'rating': 4.5,
        'currencyCode': 'USD',
      },
      {
        'name': 'Vintage Denim Jacket',
        'description': 'Authentic wash denim jacket with silver-tone buttons and four pockets.',
        'price': 79.99,
        'category': 'Outerwear',
        'image': 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?auto=format&fit=crop&q=80&w=1000',
        'rating': 4.9,
        'currencyCode': 'USD',
      },
      {
        'name': 'Minimalist Leather Watch',
        'description': 'Sleek black dial with a genuine brown leather strap. Water-resistant.',
        'price': 120.00,
        'category': 'Accessories',
        'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&q=80&w=1000',
        'rating': 4.7,
        'currencyCode': 'USD',
      },
    ];

    debugPrint('Starting to seed products...');
    for (final product in demoProducts) {
      await productsCollection.add(product);
      debugPrint('Added: ${product['name']}');
    }
    debugPrint('Seeding complete!');
  }
}
