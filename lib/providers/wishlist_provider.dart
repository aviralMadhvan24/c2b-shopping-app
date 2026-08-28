import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wishlist_item_model.dart';
import '../models/wishlist_state.dart';
import 'auth_providers.dart';

/// Provides the [WishlistNotifier] scoped to the current auth state.
/// Authenticated users sync with Firestore; guests keep items in memory only.
final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final userId = authAsync.valueOrNull?.uid;
  final firestore = FirebaseFirestore.instance;

  final notifier = WishlistNotifier(
    firestore: firestore,
    userId: userId,
  );

  // Load from Firestore when user is authenticated
  if (userId != null) {
    notifier.loadFromFirestore();
  }

  return notifier;
});

/// Manages wishlist state with Firestore synchronization for authenticated users.
///
/// - Authenticated users: write-through to `users/{uid}/wishlist/{productId}`
/// - Guest users: in-memory only
/// - On failure: retains previous state, sets syncError message
class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier({
    required FirebaseFirestore firestore,
    required String? userId,
  })  : _firestore = firestore,
        _userId = userId,
        super(WishlistState.empty());

  final FirebaseFirestore _firestore;
  final String? _userId;

  /// Whether the current user is authenticated.
  bool get _isAuthenticated => _userId != null;

  /// Firestore collection reference for the user's wishlist.
  CollectionReference<Map<String, dynamic>> get _wishlistCollection =>
      _firestore.collection('users').doc(_userId!).collection('wishlist');

  /// Adds a product to the wishlist.
  ///
  /// For authenticated users, writes to Firestore at
  /// `users/{uid}/wishlist/{productId}` with a timestamp.
  /// For guests, stores in memory only.
  Future<void> addItem(String productId) async {
    // Don't add duplicates
    if (state.items.containsKey(productId)) return;

    final item = WishlistItem(
      productId: productId,
      addedAt: DateTime.now(),
    );

    // Optimistically update local state
    final updatedItems = Map<String, WishlistItem>.from(state.items);
    updatedItems[productId] = item;
    state = state.copyWith(items: updatedItems, syncError: null);

    // Sync to Firestore for authenticated users
    if (_isAuthenticated) {
      try {
        state = state.copyWith(isSyncing: true);
        await _wishlistCollection.doc(productId).set({
          'productId': productId,
          'addedAt': Timestamp.fromDate(item.addedAt),
        });
        state = state.copyWith(isSyncing: false);
      } catch (e) {
        // Retain the item in local state but show error
        state = state.copyWith(
          isSyncing: false,
          syncError: 'Failed to sync wishlist. Please try again.',
        );
      }
    }
  }

  /// Removes a product from the wishlist.
  ///
  /// For authenticated users, deletes the Firestore document.
  /// For guests, removes from memory only.
  Future<void> removeItem(String productId) async {
    if (!state.items.containsKey(productId)) return;

    // Store previous state for rollback on failure
    final previousItems = Map<String, WishlistItem>.from(state.items);

    // Optimistically update local state
    final updatedItems = Map<String, WishlistItem>.from(state.items);
    updatedItems.remove(productId);
    state = state.copyWith(items: updatedItems, syncError: null);

    // Sync to Firestore for authenticated users
    if (_isAuthenticated) {
      try {
        state = state.copyWith(isSyncing: true);
        await _wishlistCollection.doc(productId).delete();
        state = state.copyWith(isSyncing: false);
      } catch (e) {
        // Rollback to previous state on failure
        state = state.copyWith(
          items: previousItems,
          isSyncing: false,
          syncError: 'Failed to remove item. Please try again.',
        );
      }
    }
  }

  /// Loads the wishlist from Firestore for authenticated users.
  ///
  /// Displays cached local state until the Firestore load completes.
  /// Must complete within 10 seconds of app launch.
  Future<void> loadFromFirestore() async {
    if (!_isAuthenticated) return;

    try {
      state = state.copyWith(isSyncing: true);

      final snapshot = await _wishlistCollection
          .get()
          .timeout(const Duration(seconds: 10));

      final loadedItems = <String, WishlistItem>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final productId = data['productId'] as String;
        final timestamp = data['addedAt'];
        final addedAt = timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.now();

        loadedItems[productId] = WishlistItem(
          productId: productId,
          addedAt: addedAt,
        );
      }

      state = state.copyWith(items: loadedItems, isSyncing: false);
    } catch (e) {
      // Keep cached/local state on failure, just clear syncing flag
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to load wishlist. Showing cached data.',
      );
    }
  }

  /// Merges local wishlist items into Firestore without duplicating
  /// existing entries (uses product ID to determine duplicates).
  ///
  /// Called when a user logs in for the first time with local items.
  Future<void> mergeLocalItems() async {
    if (!_isAuthenticated) return;
    if (state.items.isEmpty) return;

    try {
      state = state.copyWith(isSyncing: true);

      // Load current remote items
      final snapshot = await _wishlistCollection
          .get()
          .timeout(const Duration(seconds: 10));

      final remoteProductIds = <String>{};
      final mergedItems = <String, WishlistItem>{};

      // Add all remote items first
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final productId = data['productId'] as String;
        final timestamp = data['addedAt'];
        final addedAt = timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.now();

        remoteProductIds.add(productId);
        mergedItems[productId] = WishlistItem(
          productId: productId,
          addedAt: addedAt,
        );
      }

      // Merge local items that don't exist remotely
      final batch = _firestore.batch();
      for (final entry in state.items.entries) {
        if (!remoteProductIds.contains(entry.key)) {
          mergedItems[entry.key] = entry.value;
          batch.set(_wishlistCollection.doc(entry.key), {
            'productId': entry.key,
            'addedAt': Timestamp.fromDate(entry.value.addedAt),
          });
        }
      }

      await batch.commit();

      state = state.copyWith(items: mergedItems, isSyncing: false);
    } catch (e) {
      // Retain previous local state on failure
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to merge wishlist. Please try again.',
      );
    }
  }
}
