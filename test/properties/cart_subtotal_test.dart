// Feature: app-completion, Property 3: Cart Subtotal Calculation
// **Validates: Requirements 3.10**
//
// For any set of cart items with prices and quantities, the cart subtotal
// SHALL equal the sum of each item's price multiplied by its quantity
// (Σ price_i × quantity_i).

import 'package:glados/glados.dart';
import 'package:fashion_store/models/cart_item_model.dart';
import 'package:fashion_store/models/cart_state.dart';

// --- Custom Generators ---

extension CartSubtotalGenerators on Any {
  Generator<double> get positivePrice =>
      doubleInRange(0.01, 9999.99).map((d) => (d * 100).round() / 100.0);

  Generator<int> get validQuantity => intInRange(1, 99);

  Generator<CartItem> get cartItem => combine4(
        intInRange(1, 10000), // unique suffix for productId
        intInRange(1, 10000), // unique suffix for variantId
        positivePrice, // price
        validQuantity, // quantity
        (int productSuffix, int variantSuffix, double price, int quantity) =>
            CartItem(
          productId: 'product_$productSuffix',
          variantId: 'variant_$variantSuffix',
          productName: 'Test Product',
          productImage: 'https://example.com/image.png',
          price: price,
          currencyCode: 'USD',
          quantity: quantity,
        ),
      );

  Generator<List<CartItem>> get cartItemList =>
      listWithLengthInRange(1, 10, cartItem);
}

void main() {
  group('Property 3: Cart Subtotal Calculation', () {
    Glados(any.cartItemList, ExploreConfig(numRuns: 100)).test(
      'Cart subtotal equals sum of (price * quantity) for all items',
      (List<CartItem> items) {
        // Build a CartState from the list of items, keyed by itemKey
        final itemMap = <String, CartItem>{};
        for (final item in items) {
          // Use itemKey to avoid duplicates - last one wins
          itemMap[item.itemKey] = item;
        }

        final cartState = CartState(items: itemMap);

        // Manually compute expected subtotal
        double expectedSubtotal = 0;
        for (final item in itemMap.values) {
          expectedSubtotal += item.price * item.quantity;
        }

        // Verify CartState.subtotal matches manual calculation
        expect(cartState.subtotal, closeTo(expectedSubtotal, 0.001));
      },
    );

    Glados(any.cartItemList, ExploreConfig(numRuns: 100)).test(
      'Cart subtotal equals sum of lineTotal for all items',
      (List<CartItem> items) {
        // Build a CartState from the list of items, keyed by itemKey
        final itemMap = <String, CartItem>{};
        for (final item in items) {
          itemMap[item.itemKey] = item;
        }

        final cartState = CartState(items: itemMap);

        // Verify subtotal equals sum of individual lineTotals
        final expectedSubtotal =
            itemMap.values.fold(0.0, (sum, item) => sum + item.lineTotal);

        expect(cartState.subtotal, closeTo(expectedSubtotal, 0.001));
      },
    );

    test('Empty cart has subtotal of 0', () {
      final cartState = CartState.empty();
      expect(cartState.subtotal, equals(0.0));
    });
  });
}
