import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/providers/analytics_provider.dart';
import 'package:fashion_store/providers/auth_providers.dart';
import 'package:fashion_store/providers/cart_provider.dart';
import 'package:fashion_store/screens/product_detail_screen.dart';
import 'package:fashion_store/services/analytics_service.dart';

// --- Mocks ---

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

/// Provides a transparent 1x1 PNG for network image requests in tests.
class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  set autoUncompress(bool value) {}

  @override
  bool get autoUncompress => true;
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  // A 1x1 transparent PNG
  static final _transparentPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
    0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
    0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  /// A product with variants having different prices and availability.
  /// - Size S / Color Red → $29.99 (available)
  /// - Size M / Color Red → $34.99 (available)
  /// - Size L / Color Red → $39.99 (sold out)
  final testProduct = Product(
    id: 'prod-1',
    name: 'Test Fashion Shirt',
    image: 'https://example.com/shirt.jpg',
    price: 29.99,
    currencyCode: 'USD',
    category: 'Shirts',
    rating: 4.5,
    description: 'A stylish test shirt.',
    variants: [
      const ProductVariant(
        id: 'variant-s-red',
        title: 'S / Red',
        price: 29.99,
        currencyCode: 'USD',
        availableForSale: true,
        selectedOptions: {'Size': 'S', 'Color': 'Red'},
      ),
      const ProductVariant(
        id: 'variant-m-red',
        title: 'M / Red',
        price: 34.99,
        currencyCode: 'USD',
        availableForSale: true,
        selectedOptions: {'Size': 'M', 'Color': 'Red'},
      ),
      const ProductVariant(
        id: 'variant-l-red',
        title: 'L / Red',
        price: 39.99,
        currencyCode: 'USD',
        availableForSale: false,
        selectedOptions: {'Size': 'L', 'Color': 'Red'},
      ),
    ],
  );

  Widget buildTestWidget(Product product) {
    final mockFirestore = MockFirebaseFirestore();
    final mockAnalytics = MockAnalyticsService();

    return ProviderScope(
      overrides: [
        // Override auth state to guest (null user) so cart works in-memory
        authStateProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
        // Override firestore provider with mock to avoid real Firebase
        firestoreProvider.overrideWithValue(mockFirestore),
        // Override analytics provider with mock to avoid Firebase initialization
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
      ],
      child: MaterialApp(
        home: ProductDetailScreen(product: product),
      ),
    );
  }

  /// The variant option chips sit below the fold of the scrollable detail page,
  /// so they must be scrolled into view before they can be tapped.
  Future<void> tapOption(WidgetTester tester, String value) async {
    final option = find.text(value);
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  group('ProductDetailScreen with variants', () {
    testWidgets(
      'displays initial pre-selected variant price',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(testProduct));
        await tester.pumpAndSettle();

        // First available variant (S / Red) at $29.99 should be pre-selected
        expect(find.text('USD 29.99'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a variant option updates the displayed price',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(testProduct));
        await tester.pumpAndSettle();

        // Initially shows price of first available variant (S / Red → $29.99)
        expect(find.text('USD 29.99'), findsOneWidget);

        // Tap the "M" size option to switch to variant M / Red ($34.99)
        await tapOption(tester, 'M');

        // Price should update to reflect the M / Red variant
        expect(find.text('USD 34.99'), findsOneWidget);
        expect(find.text('USD 29.99'), findsNothing);
      },
    );

    testWidgets(
      'tapping a sold-out variant option disables Add to Cart button',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(testProduct));
        await tester.pumpAndSettle();

        // Initially, the Add to Cart button should be enabled (first variant is available)
        final addToCartButton = find.widgetWithText(ElevatedButton, 'Add To Cart');
        expect(addToCartButton, findsOneWidget);
        final initialButton = tester.widget<ElevatedButton>(addToCartButton);
        expect(initialButton.onPressed, isNotNull);

        // Tap the "L" size option to switch to variant L / Red (sold out)
        await tapOption(tester, 'L');

        // Price should update to reflect the L / Red variant
        expect(find.text('USD 39.99'), findsOneWidget);

        // "Sold Out" label should appear
        expect(find.text('Sold Out'), findsWidgets);

        // The button should now be disabled (onPressed is null)
        final soldOutButton = find.widgetWithText(ElevatedButton, 'Sold Out');
        expect(soldOutButton, findsOneWidget);
        final disabledButton = tester.widget<ElevatedButton>(soldOutButton);
        expect(disabledButton.onPressed, isNull);
      },
    );

    testWidgets(
      'tapping back to available variant re-enables Add to Cart button',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(testProduct));
        await tester.pumpAndSettle();

        // Switch to sold-out variant (L)
        await tapOption(tester, 'L');

        // Verify disabled
        final soldOutButton = find.widgetWithText(ElevatedButton, 'Sold Out');
        expect(soldOutButton, findsOneWidget);
        final disabledButton = tester.widget<ElevatedButton>(soldOutButton);
        expect(disabledButton.onPressed, isNull);

        // Switch back to available variant (S)
        await tapOption(tester, 'S');

        // Button should be re-enabled
        final enabledButton = find.widgetWithText(ElevatedButton, 'Add To Cart');
        expect(enabledButton, findsOneWidget);
        final button = tester.widget<ElevatedButton>(enabledButton);
        expect(button.onPressed, isNotNull);
      },
    );
  });
}
