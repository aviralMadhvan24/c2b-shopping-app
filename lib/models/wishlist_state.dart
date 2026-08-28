import 'wishlist_item_model.dart';

class WishlistState {
  final Map<String, WishlistItem> items; // keyed by productId
  final bool isSyncing;
  final String? syncError;

  const WishlistState({
    required this.items,
    this.isSyncing = false,
    this.syncError,
  });

  factory WishlistState.empty() => const WishlistState(items: {});

  int get itemCount => items.length;

  WishlistState copyWith({
    Map<String, WishlistItem>? items,
    bool? isSyncing,
    String? syncError,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError,
    );
  }
}
