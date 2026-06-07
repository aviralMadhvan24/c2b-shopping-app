import 'firebase_product_repository.dart';
import 'product_repository.dart';
import 'auth_repository.dart';

class AppRepositories {
  AppRepositories({
    ProductRepository? productRepository,
    AuthRepository? authRepository,
  })  : productRepository = productRepository ?? FirebaseProductRepository(),
        authRepository = authRepository ?? AuthRepository();

  final ProductRepository productRepository;
  final AuthRepository authRepository;
}
