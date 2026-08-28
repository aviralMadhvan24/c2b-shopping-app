import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/providers/analytics_provider.dart';
import 'package:fashion_store/providers/auth_providers.dart';
import 'package:fashion_store/providers/cart_provider.dart';
import 'package:fashion_store/providers/pagination_provider.dart';
import 'package:fashion_store/providers/wishlist_provider.dart';
import 'package:fashion_store/models/paginated_result.dart';
import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/repositories/app_repositories.dart';
import 'package:fashion_store/repositories/auth_repository.dart';
import 'package:fashion_store/repositories/product_repository.dart';
import 'package:fashion_store/repositories/user_data_repository.dart';
import 'package:fashion_store/services/analytics_service.dart';
import 'package:fashion_store/widgets/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Mocks ---

class MockUser extends Mock implements User {}

class MockProductRepository extends Mock implements ProductRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class _FakeFirestore extends Fake implements FirebaseFirestore {}

/// A guest-mode WishlistNotifier that never touches Firestore.
class FakeWishlistNotifier extends WishlistNotifier {
  FakeWishlistNotifier()
      : super(
          firestore: _FakeFirestore(),
          userId: null,
        );
}

/// A guest-mode CartNotifier that never touches Firestore.
class FakeCartNotifier extends CartNotifier {
  FakeCartNotifier() : super(firestore: _FakeFirestore(), userId: null);
}

void main() {
  late MockProductRepository mockProductRepo;
  late MockAuthRepository mockAuthRepo;
  late MockUserDataRepository mockUserDataRepo;
  late MockAnalyticsService mockAnalytics;
  late AppRepositories testRepositories;

  setUp(() {
    mockProductRepo = MockProductRepository();
    mockAuthRepo = MockAuthRepository();
    mockUserDataRepo = MockUserDataRepository();
    mockAnalytics = MockAnalyticsService();

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

  group('Authentication Flow Integration', () {
    testWidgets(
        'successful sign-in navigates to HomeScreen, sign-out navigates back to LoginScreen',
        (tester) async {
      // Use a StreamController to simulate auth state transitions
      final authController = StreamController<User?>();

      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('integration-test-uid');
      when(() => mockUser.email).thenReturn('user@example.com');
      when(() => mockUser.displayName).thenReturn('Integration Test User');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => authController.stream,
            ),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
            wishlistProvider.overrideWith((ref) => FakeWishlistNotifier()),
            cartProvider.overrideWith((ref) => FakeCartNotifier()),
          ],
          child: MaterialApp(
            home: AuthGate(repositories: testRepositories),
          ),
        ),
      );

      // Step 1: Initially in loading state (stream hasn't emitted yet)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Step 2: Emit null to indicate unauthenticated — should show LoginScreen
      authController.add(null);
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Step 3: Simulate successful Google Sign-In by emitting a User
      authController.add(mockUser);
      await tester.pumpAndSettle();

      // Should now show HomeScreen (identified by BottomNavigationBar)
      expect(find.text('Welcome'), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Step 4: Simulate sign-out by emitting null again
      authController.add(null);
      await tester.pumpAndSettle();

      // Should navigate back to LoginScreen
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      await authController.close();
    });

    testWidgets(
        'sign-in after timeout still navigates to HomeScreen when auth state changes',
        (tester) async {
      final authController = StreamController<User?>();

      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('delayed-uid');
      when(() => mockUser.email).thenReturn('delayed@example.com');
      when(() => mockUser.displayName).thenReturn('Delayed User');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => authController.stream,
            ),
            analyticsServiceProvider.overrideWithValue(mockAnalytics),
            productRepositoryProvider.overrideWithValue(mockProductRepo),
            wishlistProvider.overrideWith((ref) => FakeWishlistNotifier()),
            cartProvider.overrideWith((ref) => FakeCartNotifier()),
          ],
          child: MaterialApp(
            home: AuthGate(repositories: testRepositories),
          ),
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for timeout (10s) — should show LoginScreen
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Welcome'), findsOneWidget);

      // Now emit an authenticated user — AuthGate should react to stream data
      authController.add(mockUser);
      await tester.pumpAndSettle();

      // Should show HomeScreen after auth state change
      expect(find.text('Welcome'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await authController.close();
    });
  });
}
