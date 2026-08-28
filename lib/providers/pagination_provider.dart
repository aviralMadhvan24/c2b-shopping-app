import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paginated_result.dart';
import '../models/pagination_state.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

/// Provides the ProductRepository instance used by the pagination notifier.
/// Override this in tests or to swap implementations.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  throw UnimplementedError(
    'productRepositoryProvider must be overridden with a concrete ProductRepository.',
  );
});

/// PaginationNotifier manages cursor-based product pagination.
///
/// It fetches 20 items per page, appends new results to the existing list,
/// tracks the cursor and hasNextPage flag, and prevents duplicate requests.
/// State persists across navigation since the provider is not autoDispose.
class PaginationNotifier extends StateNotifier<PaginationState<Product>> {
  PaginationNotifier({required this.repository})
      : super(PaginationState<Product>.initial());

  final ProductRepository repository;

  bool get hasMore => state.hasNextPage;
  bool get isLoading => state.isLoading;

  /// Fetches the next page of products using the cursor from the previous
  /// response. No-ops if already loading or no more pages are available.
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final PaginatedResult<Product> result = await repository.fetchProducts(
        cursor: state.nextCursor,
        first: 20,
      );

      state = state.copyWith(
        items: [...state.items, ...result.items],
        nextCursor: result.nextCursor,
        hasNextPage: result.hasNextPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Resets pagination state to initial (clears items and cursor).
  void reset() {
    state = PaginationState<Product>.initial();
  }
}

/// The main pagination provider for the product grid.
/// Persists state across navigation (no autoDispose).
/// Automatically loads the first page when created.
final paginationProvider =
    StateNotifierProvider<PaginationNotifier, PaginationState<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final notifier = PaginationNotifier(repository: repository);

  // Load the first page immediately
  Future.microtask(() => notifier.loadNextPage());

  return notifier;
});
