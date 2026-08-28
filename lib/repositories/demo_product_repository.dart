import '../data/products.dart';
import '../models/paginated_result.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

class DemoProductRepository implements ProductRepository {
  const DemoProductRepository();

  @override
  Future<PaginatedResult<Product>> fetchProducts({String? cursor, int first = 20}) async {
    return PaginatedResult(
      items: products,
      nextCursor: null,
      hasNextPage: false,
    );
  }

  @override
  Future<List<Product>> fetchProductsByCategory(String category) async {
    return products.where((product) => product.category == category).toList();
  }

  @override
  Future<Product> fetchProductById(String id) async {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }

    throw Exception('Product not found: $id');
  }
}
