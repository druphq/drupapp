/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final bool success;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? meta;
  final bool fromCache;

  const ApiResponse({
    this.data,
    required this.success,
    this.message,
    this.statusCode,
    this.meta,
    this.fromCache = false,
  });

  /// Create a successful response
  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
    bool fromCache = false,
  }) {
    return ApiResponse(
      data: data,
      success: true,
      message: message,
      statusCode: statusCode,
      meta: meta,
      fromCache: fromCache,
    );
  }

  /// Create a failed response
  factory ApiResponse.failure({String? message, int? statusCode}) {
    return ApiResponse(
      data: null,
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message, data: $data)';
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  }) : hasMore = currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? json;

    return PaginatedResponse(
      items: dataList.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? dataList.length,
      total: meta['total'] as int? ?? dataList.length,
    );
  }
}
