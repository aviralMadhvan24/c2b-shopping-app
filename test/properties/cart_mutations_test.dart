// Feature: app-completion, Property 2: Cart Mutation Invariants
// **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
//
// For any product ID and variant ID, adding the item to an empty cart SHALL
// result in a cart entry with quantity 1; adding the same product ID and variant
// ID to a cart that already contains that combination SHALL increment the
// existing quantity by 1; and for any cart item with quantity Q, the quantity
// after increment SHALL be min(Q+1, 99) and the quantity after decrement SHALL
// be max(Q-1, 0), with the item removed entirely when the result is 0.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' hide any;
import 'package:fashion_store/providers/cart_provider.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// --- Custom Generators ---

extension CartMutationGenerators on Any {
  Generator<String> get nonEmptyId => nonEmptyLetterOrDigits;

  Generator<double> get positivePrice =>
      doubleInRange(0.01, 9999.99).map((d) => (d * 100).round() / 100.0);

  Generator<int> get validQuantity => intInRange(1, 99);
}

/// Creates a CartNotifier in guest mode (userId: null) to avoid Firestore.
CartNotifier _createNotifier() {
  return CartNotifier(
    firestore: MockFirebaseFirestore(),
    userId: null,
  );
}

void main() {
  group('Property 2: Cart Mutation Invariants', () {
    Glados2(any.nonEmptyId, any.nonEmptyId, ExploreConfig(numRuns: 100)).test(
      'Adding item to empty cart results in quantity 1',
      (productId, variantId) async {
        final notifier = _createNotifier();

        await notifier.addItem(
          productId: productId,
          variantId: variantId,
          price: 10.0,
          productName: 'Test',
          productImage: '',
          currencyCode: 'INR',
        );

        final itemKey = '${productId}_$variantId';
        expect(notifier.state.items.containsKey(itemKey), isTrue);
        expect(notifier.state.items[itemKey]!.quantity, equals(1));
      },
    );

    Glados2(any.nonEmptyId, any.nonEmptyId, ExploreConfig(numRuns: 100)).test(
      'Adding duplicate item increments existing quantity by 1',
      (productId, variantId) async {
        final notifier = _createNotifier();

        // Add item first time
        await notifier.addItem(
          productId: productId,
          variantId: variantId,
          price: 10.0,
          productName: 'Test',
          productImage: '',
          currencyCode: 'INR',
        );

        // Add same item again
        await notifier.addItem(
          productId: productId,
          variantId: variantId,
          price: 10.0,
          productName: 'Test',
          productImage: '',
          currencyCode: 'INR',
        );

        final itemKey = '${productId}_$variantId';
        expect(notifier.state.items[itemKey]!.quantity, equals(2));
      },
    );

    Glados(any.validQuantity, ExploreConfig(numRuns: 100)).test(
      'Increment caps at 99: min(Q+1, 99)',
      (initialQuantity) async {
        final notifier = _createNotifier();
        const productId = 'prod1';
        const variantId = 'var1';
        const itemKey = '${productId}_$variantId';

        // Add the item once, then use addItem repeatedly to reach initialQuantity
        await notifier.addItem(
          productId: productId,
          variantId: variantId,
          price: 10.0,
          productName: 'Test',
          productImage: '',
          currencyCode: 'INR',
        );

        for (var i = 1; i < initialQuantity; i++) {
          await notifier.addItem(
            productId: productId,
            variantId: variantId,
            price: 10.0,
            productName: 'Test',
            productImage: '',
            currencyCode: 'INR',
          );
        }

        expect(notifier.state.items[itemKey]!.quantity, equals(initialQuantity));

        // Now increment once
        await notifier.incrementQuantity(itemKey);

        final expectedQuantity = initialQuantity < 99 ? initialQuantity + 1 : 99;
        expect(
          notifier.state.items[itemKey]!.quantity,
          equals(expectedQuantity),
        );
      },
    );

    Glados(any.validQuantity, ExploreConfig(numRuns: 100)).test(
      'Decrement: max(Q-1, 0), item removed when result is 0',
      (initialQuantity) async {
        final notifier = _createNotifier();
        const productId = 'prod1';
        const variantId = 'var1';
        const itemKey = '${productId}_$variantId';

        // Add the item and build up to initialQuantity
        await notifier.addItem(
          productId: productId,
          variantId: variantId,
          price: 10.0,
          productName: 'Test',
          productImage: '',
          currencyCode: 'INR',
        );

        for (var i = 1; i < initialQuantity; i++) {
          await notifier.addItem(
            productId: productId,
            variantId: variantId,
            price: 10.0,
            productName: 'Test',
            productImage: '',
            currencyCode: 'INR',
          );
        }

        expect(notifier.state.items[itemKey]!.quantity, equals(initialQuantity));

        // Decrement once
        await notifier.decrementQuantity(itemKey);

        final expectedQuantity = initialQuantity - 1;
        if (expectedQuantity == 0) {
          // Item should be removed entirely
          expect(notifier.state.items.containsKey(itemKey), isFalse);
        } else {
          expect(
            notifier.state.items[itemKey]!.quantity,
            equals(expectedQuantity),
          );
        }
      },
    );
  });
}
