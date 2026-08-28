class PaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasNextPage;

  const PaginatedResult({
    required this.items,
    this.nextCursor,
    required this.hasNextPage,
  });
}
