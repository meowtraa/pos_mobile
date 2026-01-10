/// API Exceptions
/// Custom exception classes for handling API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException({String message = 'No internet connection'}) : super(message: message);
}

class TimeoutException extends ApiException {
  TimeoutException({String message = 'Request timed out'}) : super(message: message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String message = 'Unauthorized access'}) : super(message: message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException({String message = 'Access forbidden'}) : super(message: message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException({String message = 'Resource not found'}) : super(message: message, statusCode: 404);
}

class ServerException extends ApiException {
  ServerException({String message = 'Server error occurred'}) : super(message: message, statusCode: 500);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({String message = 'Validation failed', this.errors})
    : super(message: message, statusCode: 422, data: errors);
}
