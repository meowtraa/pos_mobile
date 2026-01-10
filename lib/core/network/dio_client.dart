import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'api_exceptions.dart';

/// Dio Client
/// Singleton class for handling HTTP requests
class DioClient {
  static DioClient? _instance;
  late final Dio _dio;

  DioClient._() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  factory DioClient() {
    _instance ??= DioClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: ApiConstants.baseUrl + ApiConstants.apiVersion,
    connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
    receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
    sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  );

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      // Auth Interceptor
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token here
          // final token = await _getToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token refresh here if 401
          // if (error.response?.statusCode == 401) {
          //   // Try to refresh token
          // }
          handler.next(error);
        },
      ),
      // Logging Interceptor (only in debug mode)
      if (kDebugMode)
        LogInterceptor(requestBody: true, responseBody: true, error: true, requestHeader: true, responseHeader: false),
    ]);
  }

  /// Set Authorization Token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove Authorization Token
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio Errors
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled');
      default:
        return ApiException(message: error.message ?? 'Unknown error occurred');
    }
  }

  /// Handle Response Errors
  ApiException _handleResponseError(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final message = data is Map ? data['message'] : 'An error occurred';

    switch (statusCode) {
      case 400:
        return ApiException(message: message ?? 'Bad request', statusCode: statusCode);
      case 401:
        return UnauthorizedException(message: message ?? 'Unauthorized');
      case 403:
        return ForbiddenException(message: message ?? 'Forbidden');
      case 404:
        return NotFoundException(message: message ?? 'Not found');
      case 422:
        return ValidationException(
          message: message ?? 'Validation failed',
          errors: data is Map ? data['errors'] : null,
        );
      case 500:
      case 501:
      case 502:
      case 503:
        return ServerException(message: message ?? 'Server error');
      default:
        return ApiException(message: message ?? 'Unknown error', statusCode: statusCode);
    }
  }
}
