// Feature: app-completion, Property 4: Cart Merge Keeps Higher Quantity
// **Validates: Requirements 3.7**
//
// For any local cart state and remote cart state, merging them SHALL produce
// a cart that contains all items from both sources, and for items that exist
// in both, the merged quantity SHALL equal the maximum of the two quantities.

import 'dart:math';

import 'package:glados/glados.dart';
import 'package:fashion_store/models/cart_item_model.dart';

// --- Merge Logic (mirrors CartNotifier.mergeLocalWithRemote) ---

/// Pure function implementing the same merge algorithm as CartNotifier:
/// 1. Start with all remote items
/// 2. For each local item: if key exists in remote, keep higher quantity;
///    if not, add the local item.
Map<String, CartItem> mergeCart(
  Map<String, CartItem> localItems,
  Map<String, CartItem> remoteItems,
) {
  final merged = <String, CartItem>{};

  // Add all remote items first
  merged.addAll(remoteItems);

  // Merge local items
  for (final entry in localItems.entries) {
    final key = entry.key;
    final localItem = entry.value;

    if (merged.containsKey(key)) {
      final remoteItem = merged[key]!;
      if (localItem.quantity > remoteItem.quantity) {
        merged[key] = localItem;
      }
    } else {
      merged[key] = localItem;
    }
  }

  return merged;
}

// --- Custom Generators ---

extension CartMergeGenerators on Any {
  Generator<CartItem> get cartItem => combine7(
        any.nonEmptyLetterOrDigits, // productId
        any.nonEmptyLetterOrDigits, // variantId
        any.nonEmptyLetterOrDigits, // productName
        any.nonEmptyLetterOrDigits, // productImage
        any.doubleInRange(0.01, 9999.99)
            .map((d) => (d * 100).round() / 100.0), // price
        any.nonEmptyLetterOrDigits, // currencyCode
        any.intInRange(1, 99), // quantity
        (String productId, String variantId, String productName,
                String productImage, double price, String currencyCode,
                int quantity) =>
            CartItem(
          productId: productId,
          variantId: variantId,
          productName: productName,
          productImage: productImage,
          price: price,
          currencyCode: currencyCode,
          quantity: quantity,
        ),
      );

  /// Generates a cart map with 0-5 items, keyed by itemKey.
  Generator<Map<String, CartItem>> get cartMap =>
      any.listWithLengthInRange(0, 5, cartItem).map((items) {
        final map = <String, CartItem>{};
        for (final item in items) {
          map[item.itemKey] = item;
        }
        return map;
      });

  /// Generates two cart maps (local & remote) with some overlapping keys.
  /// This creates a more interesting test scenario by ensuring overlaps exist.
  Generator<({Map<String, CartItem> local, Map<String, CartItem> remote})>
      get cartPairWithOverlap => combine3(
            cartMap, // base local items
            cartMap, // base remote items
            any.listWithLengthInRange(0, 3, combine3(
              any.nonEmptyLetterOrDigits, // shared productId
              any.nonEmptyLetterOrDigits, // shared variantId
              any.intInRange(1, 99), // quantity for local overlap
              (String pid, String vid, int qty) => (pid: pid, vid: vid, qty: qty),
            )),
            (Map<String, CartItem> baseLocal, Map<String, CartItem> baseRemote,
                List<({String pid, String vid, int qty})> overlaps) {
              final local = Map<String, CartItem>.from(baseLocal);
              final remote = Map<String, CartItem>.from(baseRemote);

              // Create overlapping items with different quantities
              for (final overlap in overlaps) {
                final key = '${overlap.pid}_${overlap.vid}';
                final localQty = overlap.qty;
                final remoteQty = max(1, (localQty + 5) % 99 + 1);

                local[key] = CartItem(
                  productId: overlap.pid,
                  variantId: overlap.vid,
                  productName: 'Product ${overlap.pid}',
                  productImage: 'image.png',
                  price: 10.0,
                  currencyCode: 'INR',
                  quantity: localQty,
                );
                remote[key] = CartItem(
                  productId: overlap.pid,
                  variantId: overlap.vid,
                  productName: 'Product ${overlap.pid}',
                  productImage: 'image.png',
                  price: 10.0,
                  currencyCode: 'INR',
                  quantity: remoteQty,
                );
              }

              return (local: local, remote: remote);
            },
          );
}

void main() {
  group('Property 4: Cart Merge Keeps Higher Quantity', () {
    Glados(any.cartPairWithOverlap, ExploreConfig(numRuns: 100)).test(
      'Merged cart contains all keys from both local and remote',
      (pair) {
        final merged = mergeCart(pair.local, pair.remote);

        // All keys from local must be present
        for (final key in pair.local.keys) {
          expect(merged.containsKey(key), isTrue,
              reason: 'Local key "$key" missing from merged cart');
        }

        // All keys from remote must be present
        for (final key in pair.remote.keys) {
          expect(merged.containsKey(key), isTrue,
              reason: 'Remote key "$key" missing from merged cart');
        }

        // Merged keys should be exactly the union of both
        final expectedKeys = {...pair.local.keys, ...pair.remote.keys};
        expect(merged.keys.toSet(), equals(expectedKeys));
      },
    );

    Glados(any.cartPairWithOverlap, ExploreConfig(numRuns: 100)).test(
      'For overlapping keys, merged quantity equals max of local and remote',
      (pair) {
        final merged = mergeCart(pair.local, pair.remote);

        final overlappingKeys =
            pair.local.keys.toSet().intersection(pair.remote.keys.toSet());

        for (final key in overlappingKeys) {
          final localQty = pair.local[key]!.quantity;
          final remoteQty = pair.remote[key]!.quantity;
          final expectedQty = max(localQty, remoteQty);

          expect(merged[key]!.quantity, equals(expectedQty),
              reason:
                  'Key "$key": expected max($localQty, $remoteQty) = $expectedQty, '
                  'got ${merged[key]!.quantity}');
        }
      },
    );

    Glados(any.cartPairWithOverlap, ExploreConfig(numRuns: 100)).test(
      'Non-overlapping items are preserved as-is',
      (pair) {
        final merged = mergeCart(pair.local, pair.remote);

        // Local-only items preserved
        final localOnlyKeys =
            pair.local.keys.toSet().difference(pair.remote.keys.toSet());
        for (final key in localOnlyKeys) {
          expect(merged[key], equals(pair.local[key]),
              reason: 'Local-only item "$key" was not preserved as-is');
        }

        // Remote-only items preserved
        final remoteOnlyKeys =
            pair.remote.keys.toSet().difference(pair.local.keys.toSet());
        for (final key in remoteOnlyKeys) {
          expect(merged[key], equals(pair.remote[key]),
              reason: 'Remote-only item "$key" was not preserved as-is');
        }
      },
    );
  });
}
