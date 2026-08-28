import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/providers/cart_provider.dart';
import 'package:fashion_store/providers/wishlist_provider.dart';
import 'package:fashion_store/theme/app_theme.dart';
import 'package:fashion_store/widgets/product_card.dart';

class _FakeFirestore extends Fake implements FirebaseFirestore {}

class _TestCartNotifier extends CartNotifier {
  _TestCartNotifier() : super(firestore: _FakeFirestore(), userId: null);
}

class _TestWishlistNotifier extends WishlistNotifier {
  _TestWishlistNotifier() : super(firestore: _FakeFirestore(), userId: null);
}

/// A long product name plus a struck-through MRP is the worst case for the
/// card's info column — it is what overflowed the card by 6.7px in a tight
/// two-column grid before the title was made flexible.
void main() {
  const product = Product(
    id: 'p1',
    name: 'Samsung Galaxy Buds2 Pro Wireless Earbuds With ANC',
    description: 'Long-titled discounted product.',
    price: 8999,
    mrp: 17999,
    discountPercent: 50,
    image: 'assets/products/galaxy-buds2-pro.jpg',
    category: 'Electronics',
    rating: 4.6,
  );

  Widget harness({required double width, required double aspectRatio}) {
    return ProviderScope(
      overrides: [
        cartProvider.overrideWith((ref) => _TestCartNotifier()),
        wishlistProvider.overrideWith((ref) => _TestWishlistNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SizedBox(
              width: width,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                padding: const EdgeInsets.all(12),
                children: const [
                  ProductCard(product: product),
                  ProductCard(product: product),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('card does not overflow in a tight grid cell', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(width: 300, aspectRatio: 0.62));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  // ProductCard grids in the app run at 0.58 (home / categories) and 0.62
  // (wishlist). 0.66 is checked as headroom above the tightest real usage.
  testWidgets('card fits every aspect ratio the app uses', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final ratio in [0.58, 0.62, 0.66]) {
      await tester.pumpWidget(harness(width: 320, aspectRatio: ratio));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $ratio');
    }
  });
}
