class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
    );
  }
}

class PaginatedResponse<T> {
  const PaginatedResponse({required this.data, required this.meta});

  final List<T> data;
  final PaginationMeta meta;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData.whereType<Map<String, dynamic>>().map(fromJsonT).toList()
        : <T>[];

    return PaginatedResponse(
      data: items,
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}
