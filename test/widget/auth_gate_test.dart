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
import 'package:fashion_store/repositories/app_repositories.dart';
import 'package:fashion_store/repositories/product_repository.dart';
import 'package:fashion_store/repositories/auth_repository.dart';
import 'package:fashion_store/repositories/user_data_repository.dart';
import 'package:fashion_store/services/analytics_service.dart';
import 'package:fashion_store/widgets/auth_gate.dart';
import 'package:fashion_store/models/paginated_result.dart';
import 'package:fashion_store/models/product_model.dart';
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
  FakeWishlistNotifier() : super(firestore: _FakeFirestore(), userId: null);
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
    )).thenAnswer((_) async => PaginatedResult<Product>(items: [], hasNextPage: false));
    when(() => mockAuthRepo.currentUser).thenReturn(null);

    testRepositories = AppRepositories(
      productRepository: mockProductRepo,
      authRepository: mockAuthRepo,
      userDataRepository: mockUserDataRepo,
    );
  });

  Widget buildTestWidget({
    required List<Override> overrides,
  }) {
    return ProviderScope(
      // AuthGate reads analyticsServiceProvider, which would otherwise build a
      // real AnalyticsService and require an initialized Firebase app.
      overrides: [
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
        // HomeScreen watches these, and their real implementations reach for
        // FirebaseFirestore.instance, which needs an initialized Firebase app.
        productRepositoryProvider.overrideWithValue(mockProductRepo),
        cartProvider.overrideWith((ref) => FakeCartNotifier()),
        wishlistProvider.overrideWith((ref) => FakeWishlistNotifier()),
        ...overrides,
      ],
      child: MaterialApp(
        home: AuthGate(repositories: testRepositories),
      ),
    );
  }

  group('AuthGate', () {
    testWidgets('shows CircularProgressIndicator during loading state',
        (tester) async {
      // authStateProvider in loading state — use a stream that never emits
      final controller = StreamController<User?>();

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller.close();
    });

    testWidgets('shows LoginScreen when unauthenticated (null user)',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream<User?>.value(null),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // LoginScreen should show the 'Welcome' text and Google sign-in button
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('shows HomeScreen when authenticated (user present)',
        (tester) async {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test-uid');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream<User?>.value(mockUser),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // HomeScreen shows the brand name in the app bar
      expect(find.text('Welcome'), findsNothing);
      // HomeScreen should have the bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets(
        'treats user as unauthenticated after 10s timeout during loading',
        (tester) async {
      // Use fakeAsync to control time
      final controller = StreamController<User?>();

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
        ),
      );

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance time past the 10s timeout
      await tester.pump(const Duration(seconds: 11));

      // After timeout, should show LoginScreen
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      await controller.close();
    });

    testWidgets('transitions from loading to LoginScreen when stream emits null',
        (tester) async {
      final controller = StreamController<User?>();

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Emit null (unauthenticated)
      controller.add(null);
      await tester.pumpAndSettle();

      // Should now show LoginScreen
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Welcome'), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        'transitions from loading to HomeScreen when stream emits user',
        (tester) async {
      final controller = StreamController<User?>();
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test-uid');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Emit authenticated user
      controller.add(mockUser);
      await tester.pumpAndSettle();

      // Should now show HomeScreen
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Welcome'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await controller.close();
    });

    testWidgets('shows LoginScreen on auth error state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream<User?>.error(Exception('Auth failed')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should show LoginScreen on error
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });
}
