import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/models/paginated_result.dart';
import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/providers/analytics_provider.dart';
import 'package:fashion_store/providers/auth_providers.dart';
import 'package:fashion_store/providers/cart_provider.dart';
import 'package:fashion_store/providers/pagination_provider.dart';
import 'package:fashion_store/providers/wishlist_provider.dart';
import 'package:fashion_store/repositories/app_repositories.dart';
import 'package:fashion_store/repositories/auth_repository.dart';
import 'package:fashion_store/repositories/product_repository.dart';
import 'package:fashion_store/repositories/user_data_repository.dart';
import 'package:fashion_store/screens/home_screen.dart';
import 'package:fashion_store/services/analytics_service.dart';

// --- Mocks ---

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

/// A guest-mode WishlistNotifier that never touches Firestore.
class FakeWishlistNotifier extends WishlistNotifier {
  FakeWishlistNotifier()
      : super(
          firestore: _FakeFirestore(),
          userId: null,
        );
}

/// A guest-mode CartNotifier that never touches Firestore.
class TestCartNotifier extends CartNotifier {
  TestCartNotifier() : super(firestore: _FakeFirestore(), userId: null);
}

class _FakeFirestore extends Fake implements FirebaseFirestore {}

void main() {
  late MockAnalyticsService mockAnalytics;
  late MockProductRepository mockProductRepo;
  late MockAuthRepository mockAuthRepo;
  late MockUserDataRepository mockUserDataRepo;
  late AppRepositories testRepositories;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
    mockProductRepo = MockProductRepository();
    mockAuthRepo = MockAuthRepository();
    mockUserDataRepo = MockUserDataRepository();

    when(() => mockProductRepo.fetchProducts(
          cursor: any(named: 'cursor'),
          first: any(named: 'first'),
        )).thenAnswer(
        (_) async => PaginatedResult<Product>(items: [], hasNextPage: false));
    when(() => mockAuthRepo.currentUser).thenReturn(null);

    testRepositories = AppRepositories(
      productRepository: mockProductRepo,
      authRepository: mockAuthRepo,
      userDataRepository: mockUserDataRepo,
    );
  });

  group('Cart Screen', () {
    testWidgets('increase button increments quantity by 1', (tester) async {
      final testCartNotifier = TestCartNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream<User?>.value(null),
            ),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
            wishlistProvider.overrideWith((ref) => FakeWishlistNotifier()),
            cartProvider.overrideWith((ref) => testCartNotifier),
          ],
          child: MaterialApp(
            home: HomeScreen(repositories: testRepositories),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add item to cart after widget is built
      await testCartNotifier.addItem(
        productId: 'prod-1',
        variantId: 'variant-1',
        price: 25.00,
        productName: 'Test Shirt',
        productImage: '',
        currencyCode: 'USD',
      );
      await tester.pumpAndSettle();

      // Open the CartScreen from the app bar cart icon
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Verify initial quantity is 1
      expect(find.text('1'), findsWidgets); // "1" also appears in item count
      // More specifically, look for the quantity text between +/- buttons
      expect(find.text('Test Shirt'), findsOneWidget);

      // Tap the increment button (Icons.add)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Quantity should now be 2
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('decrease button decrements quantity by 1', (tester) async {
      final testCartNotifier = TestCartNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream<User?>.value(null),
            ),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
            wishlistProvider.overrideWith((ref) => FakeWishlistNotifier()),
            cartProvider.overrideWith((ref) => testCartNotifier),
          ],
          child: MaterialApp(
            home: HomeScreen(repositories: testRepositories),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add item and increment to quantity 2
      await testCartNotifier.addItem(
        productId: 'prod-1',
        variantId: 'variant-1',
        price: 25.00,
        productName: 'Test Shirt',
        productImage: '',
        currencyCode: 'USD',
      );
      await testCartNotifier.incrementQuantity('prod-1_variant-1');
      await tester.pumpAndSettle();

      // Open the CartScreen from the app bar cart icon
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Verify initial quantity is 2
      expect(find.text('2'), findsWidgets);

      // Tap the decrement button (Icons.remove)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      // Quantity should now be 1 (check the item is still there with quantity 1)
      expect(find.text('Test Shirt'), findsOneWidget);
      // The "2" should no longer appear as the quantity
      expect(find.text('2'), findsNothing);
    });

    testWidgets('remove button eliminates item from the list', (tester) async {
      final testCartNotifier = TestCartNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream<User?>.value(null),
            ),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
            wishlistProvider.overrideWith((ref) => FakeWishlistNotifier()),
            cartProvider.overrideWith((ref) => testCartNotifier),
          ],
          child: MaterialApp(
            home: HomeScreen(repositories: testRepositories),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add item to cart
      await testCartNotifier.addItem(
        productId: 'prod-1',
        variantId: 'variant-1',
        price: 25.00,
        productName: 'Test Shirt',
        productImage: '',
        currencyCode: 'USD',
      );
      await tester.pumpAndSettle();

      // Open the CartScreen from the app bar cart icon
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Verify item is displayed
      expect(find.text('Test Shirt'), findsOneWidget);

      // Tap the delete button (Icons.delete_outline)
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Item should be removed - the empty cart state should show
      expect(find.text('Test Shirt'), findsNothing);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });
  });
}
