import '../data/products.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

class DemoProductRepository implements ProductRepository {
  const DemoProductRepository();

  @override
  Future<List<Product>> fetchProducts() async {
    return products;
  }

  @override
  Future<List<Product>> fetchProductsByCategory(String category) async {
    return products.where((product) => product.category == category).toList();
  }

  @override
  Future<Product?> fetchProductById(String id) async {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }
}
