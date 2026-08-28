import 'cart_item_model.dart';

class CartState {
  final Map<String, CartItem> items; // keyed by itemKey
  final bool isSyncing;
  final String? syncError;

  const CartState({
    required this.items,
    this.isSyncing = false,
    this.syncError,
  });

  factory CartState.empty() => const CartState(items: {});

  double get subtotal =>
      items.values.fold(0, (sum, item) => sum + item.lineTotal);

  int get distinctItemCount => items.length;

  CartState copyWith({
    Map<String, CartItem>? items,
    bool? isSyncing,
    String? syncError,
  }) {
    return CartState(
      items: items ?? this.items,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError,
    );
  }
}
