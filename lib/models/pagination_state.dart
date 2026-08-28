class PaginationState<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasNextPage;
  final bool isLoading;
  final String? error;

  const PaginationState({
    required this.items,
    this.nextCursor,
    required this.hasNextPage,
    this.isLoading = false,
    this.error,
  });

  factory PaginationState.initial() => PaginationState<T>(
        items: const [],
        hasNextPage: true,
        isLoading: false,
      );

  PaginationState<T> copyWith({
    List<T>? items,
    String? nextCursor,
    bool? hasNextPage,
    bool? isLoading,
    String? error,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
