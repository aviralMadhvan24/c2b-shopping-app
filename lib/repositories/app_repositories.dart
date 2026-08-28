import 'firebase_product_repository.dart';
import 'product_repository.dart';
import 'auth_repository.dart';
import 'user_data_repository.dart';

class AppRepositories {
  AppRepositories({
    ProductRepository? productRepository,
    AuthRepository? authRepository,
    UserDataRepository? userDataRepository,
  }) : productRepository = productRepository ?? FirebaseProductRepository(),
       authRepository = authRepository ?? AuthRepository(),
       userDataRepository = userDataRepository ?? UserDataRepository();

  final ProductRepository productRepository;
  final AuthRepository authRepository;
  final UserDataRepository userDataRepository;
}
