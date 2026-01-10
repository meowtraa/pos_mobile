/// API Response Wrapper
/// Generic class to wrap API responses
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({required this.success, this.message, this.data, this.statusCode, this.errors});

  factory ApiResponse.success({T? data, String? message, int? statusCode}) {
    return ApiResponse(success: true, data: data, message: message, statusCode: statusCode);
  }

  factory ApiResponse.error({String? message, int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse(success: false, message: message, statusCode: statusCode, errors: errors);
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}

/// Pagination Meta
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({required this.currentPage, required this.lastPage, required this.perPage, required this.total});

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

/// Paginated Response
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;

  PaginatedResponse({required this.data, required this.meta});
}
