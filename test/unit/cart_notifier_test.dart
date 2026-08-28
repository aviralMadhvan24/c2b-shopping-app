import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/providers/cart_provider.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late CartNotifier notifier;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    notifier = CartNotifier(firestore: mockFirestore, userId: null);
  });

  group('CartNotifier', () {
    test('addItem stores product ID, variant ID, and quantity 1', () async {
      await notifier.addItem(
        productId: 'prod-1',
        variantId: 'var-1',
        price: 29.99,
      );

      final state = notifier.state;
      expect(state.items.length, 1);

      final item = state.items['prod-1_var-1']!;
      expect(item.productId, 'prod-1');
      expect(item.variantId, 'var-1');
      expect(item.quantity, 1);
      expect(item.price, 29.99);
    });

    test('incrementQuantity increases quantity by 1', () async {
      await notifier.addItem(
        productId: 'prod-1',
        variantId: 'var-1',
        price: 10.0,
      );

      await notifier.incrementQuantity('prod-1_var-1');

      final item = notifier.state.items['prod-1_var-1']!;
      expect(item.quantity, 2);
    });

    test('decrementQuantity to 0 removes the item', () async {
      await notifier.addItem(
        productId: 'prod-1',
        variantId: 'var-1',
        price: 15.0,
      );

      // Item has quantity 1; decrementing should remove it
      await notifier.decrementQuantity('prod-1_var-1');

      expect(notifier.state.items.containsKey('prod-1_var-1'), isFalse);
      expect(notifier.state.items.length, 0);
    });

    test('subtotal sums price * quantity for all items', () async {
      await notifier.addItem(
        productId: 'prod-1',
        variantId: 'var-1',
        price: 10.0,
      );
      await notifier.addItem(
        productId: 'prod-2',
        variantId: 'var-2',
        price: 20.0,
      );
      // Increment prod-1 to quantity 2
      await notifier.incrementQuantity('prod-1_var-1');

      // subtotal = (10 * 2) + (20 * 1) = 40
      expect(notifier.subtotal, 40.0);
    });
  });
}
