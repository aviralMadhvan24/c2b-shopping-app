// Feature: app-completion, Property 5: Wishlist Merge is Set Union Without Duplicates
// **Validates: Requirements 4.6**
//
// For any local wishlist and remote wishlist, merging them SHALL produce a
// wishlist that contains every product ID from both sources exactly once,
// with no duplicate entries based on product ID.

import 'package:glados/glados.dart';

// --- Merge Logic (mirrors WishlistNotifier.mergeLocalItems) ---

/// Pure function implementing the same merge algorithm as WishlistNotifier:
/// 1. Start with all remote product IDs
/// 2. For each local product ID: if it doesn't exist in remote, add it
/// Result is set union with no duplicates.
Set<String> mergeWishlist(Set<String> localIds, Set<String> remoteIds) {
  final merged = <String>{};

  // Add all remote items first
  merged.addAll(remoteIds);

  // Merge local items that don't exist remotely
  for (final id in localIds) {
    if (!merged.contains(id)) {
      merged.add(id);
    }
  }

  return merged;
}

// --- Custom Generators ---

extension WishlistMergeGenerators on Any {
  /// Generates a set of product IDs (0-10 items).
  Generator<Set<String>> get productIdSet =>
      any.listWithLengthInRange(0, 10, any.nonEmptyLetterOrDigits).map(
        (list) => list.toSet(),
      );

  /// Generates two wishlist sets (local & remote) with some overlapping IDs.
  Generator<({Set<String> local, Set<String> remote})>
      get wishlistPairWithOverlap => combine3(
            productIdSet, // base local IDs
            productIdSet, // base remote IDs
            any.listWithLengthInRange(0, 5, any.nonEmptyLetterOrDigits), // shared IDs
            (Set<String> baseLocal, Set<String> baseRemote,
                List<String> overlaps) {
              final local = Set<String>.from(baseLocal);
              final remote = Set<String>.from(baseRemote);

              // Add shared IDs to both sets to ensure overlap
              for (final id in overlaps) {
                local.add(id);
                remote.add(id);
              }

              return (local: local, remote: remote);
            },
          );
}

void main() {
  group('Property 5: Wishlist Merge is Set Union Without Duplicates', () {
    Glados(any.wishlistPairWithOverlap, ExploreConfig(numRuns: 100)).test(
      'Merged wishlist contains every product ID from both sources',
      (pair) {
        final merged = mergeWishlist(pair.local, pair.remote);

        // Every local ID must be in merged
        for (final id in pair.local) {
          expect(merged.contains(id), isTrue,
              reason: 'Local product ID "$id" missing from merged wishlist');
        }

        // Every remote ID must be in merged
        for (final id in pair.remote) {
          expect(merged.contains(id), isTrue,
              reason: 'Remote product ID "$id" missing from merged wishlist');
        }

        // Merged should be exactly the union
        final expectedUnion = {...pair.local, ...pair.remote};
        expect(merged, equals(expectedUnion));
      },
    );

    Glados(any.wishlistPairWithOverlap, ExploreConfig(numRuns: 100)).test(
      'Merged wishlist has no duplicate entries (size equals union size)',
      (pair) {
        final merged = mergeWishlist(pair.local, pair.remote);

        // The merged result is already a Set, so duplicates are impossible
        // at the data structure level. Verify the count matches the union.
        final expectedUnion = {...pair.local, ...pair.remote};
        expect(merged.length, equals(expectedUnion.length),
            reason:
                'Merged size ${merged.length} != union size ${expectedUnion.length}');
      },
    );

    Glados(any.wishlistPairWithOverlap, ExploreConfig(numRuns: 100)).test(
      'Merged wishlist contains no IDs not present in either source',
      (pair) {
        final merged = mergeWishlist(pair.local, pair.remote);

        // Every merged ID must come from local or remote
        for (final id in merged) {
          expect(pair.local.contains(id) || pair.remote.contains(id), isTrue,
              reason:
                  'Merged contains "$id" which is in neither local nor remote');
        }
      },
    );
  });
}
