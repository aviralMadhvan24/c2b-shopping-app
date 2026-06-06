import 'demo_product_repository.dart';
import 'product_repository.dart';

class AppRepositories {
  const AppRepositories({
    this.productRepository = const DemoProductRepository(),
  });

  final ProductRepository productRepository;
}
