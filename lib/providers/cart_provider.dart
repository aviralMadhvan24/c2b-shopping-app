import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../models/cart_state.dart';
import 'auth_providers.dart';

/// CartNotifier manages cart state with optional Firestore sync for
/// authenticated users. Guest users operate in-memory only.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier({
    required FirebaseFirestore firestore,
    required String? userId,
  })  : _firestore = firestore,
        _userId = userId,
        super(CartState.empty());

  final FirebaseFirestore _firestore;
  final String? _userId;

  bool get _isAuthenticated => _userId != null;

  /// The Firestore collection reference for the current user's cart.
  CollectionReference<Map<String, dynamic>>? get _cartCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('cart');
  }

  // --- Getters ---

  double get subtotal => state.subtotal;
  int get distinctItemCount => state.distinctItemCount;

  // --- Mutations ---

  /// Adds an item to the cart. If the item (same productId + variantId) already
  /// exists, increments its quantity by 1 (up to max 99).
  Future<void> addItem({
    required String productId,
    required String variantId,
    required double price,
    String productName = '',
    String productImage = '',
    String currencyCode = 'INR',
  }) async {
    final itemKey = '${productId}_$variantId';
    final currentItems = Map<String, CartItem>.from(state.items);

    if (currentItems.containsKey(itemKey)) {
      // Increment existing item, max 99
      final existing = currentItems[itemKey]!;
      if (existing.quantity < 99) {
        currentItems[itemKey] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      }
    } else {
      // Add new item with quantity 1
      currentItems[itemKey] = CartItem(
        productId: productId,
        variantId: variantId,
        productName: productName,
        productImage: productImage,
        price: price,
        currencyCode: currencyCode,
        quantity: 1,
      );
    }

    state = state.copyWith(items: currentItems, syncError: null);
    await _syncToFirestore(itemKey, currentItems[itemKey]);
  }

  /// Increments the quantity of a cart item by 1 (max 99).
  Future<void> incrementQuantity(String itemKey) async {
    final currentItems = Map<String, CartItem>.from(state.items);
    final item = currentItems[itemKey];
    if (item == null) return;

    if (item.quantity >= 99) return;

    currentItems[itemKey] = item.copyWith(quantity: item.quantity + 1);
    state = state.copyWith(items: currentItems, syncError: null);
    await _syncToFirestore(itemKey, currentItems[itemKey]);
  }

  /// Decrements the quantity of a cart item by 1. Removes the item if
  /// quantity reaches 0.
  Future<void> decrementQuantity(String itemKey) async {
    final currentItems = Map<String, CartItem>.from(state.items);
    final item = currentItems[itemKey];
    if (item == null) return;

    if (item.quantity <= 1) {
      // Remove item when quantity would become 0
      currentItems.remove(itemKey);
      state = state.copyWith(items: currentItems, syncError: null);
      await _deleteFromFirestore(itemKey);
    } else {
      currentItems[itemKey] = item.copyWith(quantity: item.quantity - 1);
      state = state.copyWith(items: currentItems, syncError: null);
      await _syncToFirestore(itemKey, currentItems[itemKey]);
    }
  }

  /// Removes an item from the cart entirely.
  Future<void> removeItem(String itemKey) async {
    final currentItems = Map<String, CartItem>.from(state.items);
    if (!currentItems.containsKey(itemKey)) return;

    currentItems.remove(itemKey);
    state = state.copyWith(items: currentItems, syncError: null);
    await _deleteFromFirestore(itemKey);
  }

  // --- Firestore Sync ---

  /// Syncs a single cart item to Firestore (write-through).
  /// On failure: retains local state, sets syncError for non-blocking display.
  Future<void> _syncToFirestore(String itemKey, CartItem? item) async {
    if (!_isAuthenticated || item == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      await _cartCollection!.doc(itemKey).set(item.toMap());
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      // Retain local state, show non-blocking error, retry on next mutation
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to sync cart. Changes saved locally.',
      );
    }
  }

  /// Deletes a cart item from Firestore.
  Future<void> _deleteFromFirestore(String itemKey) async {
    if (!_isAuthenticated) return;

    state = state.copyWith(isSyncing: true);
    try {
      await _cartCollection!.doc(itemKey).delete();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to sync cart. Changes saved locally.',
      );
    }
  }

  /// Loads the cart from Firestore for authenticated users.
  Future<void> loadFromFirestore() async {
    if (!_isAuthenticated) return;

    state = state.copyWith(isSyncing: true);
    try {
      final snapshot = await _cartCollection!.get();
      final remoteItems = <String, CartItem>{};

      for (final doc in snapshot.docs) {
        final item = CartItem.fromMap(doc.data());
        remoteItems[item.itemKey] = item;
      }

      state = state.copyWith(items: remoteItems, isSyncing: false);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to load cart from cloud.',
      );
    }
  }

  /// Merges local cart with remote Firestore cart.
  /// For items existing in both, keeps the higher quantity.
  Future<void> mergeLocalWithRemote() async {
    if (!_isAuthenticated) return;

    state = state.copyWith(isSyncing: true);
    try {
      final snapshot = await _cartCollection!.get();
      final remoteItems = <String, CartItem>{};

      for (final doc in snapshot.docs) {
        final item = CartItem.fromMap(doc.data());
        remoteItems[item.itemKey] = item;
      }

      final localItems = Map<String, CartItem>.from(state.items);
      final mergedItems = <String, CartItem>{};

      // Add all remote items
      mergedItems.addAll(remoteItems);

      // Merge local items: keep higher quantity for duplicates, add new ones
      for (final entry in localItems.entries) {
        final key = entry.key;
        final localItem = entry.value;

        if (mergedItems.containsKey(key)) {
          final remoteItem = mergedItems[key]!;
          if (localItem.quantity > remoteItem.quantity) {
            mergedItems[key] = localItem;
          }
        } else {
          mergedItems[key] = localItem;
        }
      }

      // Write merged state back to Firestore
      final batch = _firestore.batch();
      for (final entry in mergedItems.entries) {
        batch.set(_cartCollection!.doc(entry.key), entry.value.toMap());
      }
      await batch.commit();

      state = state.copyWith(items: mergedItems, isSyncing: false);
    } catch (e) {
      // On failure, keep local state
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to merge cart. Local changes preserved.',
      );
    }
  }
}

// --- Riverpod Providers ---

/// Provides the FirebaseFirestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// The main cart provider that depends on auth state.
/// Recreates the CartNotifier when auth state changes (login/logout).
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authState = ref.watch(authStateProvider);

  final userId = authState.whenData((user) => user?.uid).value;

  final notifier = CartNotifier(
    firestore: firestore,
    userId: userId,
  );

  // If authenticated, load cart from Firestore and merge with any local items
  if (userId != null) {
    // Use Future.microtask to avoid modifying state during build
    Future.microtask(() => notifier.mergeLocalWithRemote());
  }

  return notifier;
});
