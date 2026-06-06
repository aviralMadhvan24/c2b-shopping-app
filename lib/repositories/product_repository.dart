import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();

  Future<List<Product>> fetchProductsByCategory(String category);

  Future<Product?> fetchProductById(String id);
}
