import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/repositories/demo_product_repository.dart';

void main() {
  const repository = DemoProductRepository();

  test('fetches demo products', () async {
    final result = await repository.fetchProducts();

    expect(result.items, isNotEmpty);
    expect(result.items.every((product) => product.id.isNotEmpty), isTrue);
  });

  test('fetches products by category', () async {
    final products = await repository.fetchProductsByCategory('Men');

    expect(products, isNotEmpty);
    expect(products.every((product) => product.category == 'Men'), isTrue);
  });

  test('fetches product by ID', () async {
    final product = await repository.fetchProductById('demo-men-hoodie');

    expect(product, isNotNull);
    expect(product.name, 'Men Hoodie');
  });
}
