import '../models/paginated_result.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<PaginatedResult<Product>> fetchProducts({String? cursor, int first = 20});

  Future<List<Product>> fetchProductsByCategory(String category);

  Future<Product> fetchProductById(String id);
}

/// Exception thrown when a product is not found by its ID.
class ProductNotFoundException implements Exception {
  ProductNotFoundException(this.productId);

  final String productId;

  @override
  String toString() => 'Product not found: $productId';
}
