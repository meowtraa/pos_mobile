/// API Constants
/// Contains all API related constants
class ApiConstants {
  ApiConstants._();

  // Base URL - Change this to your API base URL
  static const String baseUrl = 'https://api.example.com';

  // API Version
  static const String apiVersion = '/api/v1';

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Products
  static const String products = '/products';
  static const String categories = '/categories';

  // Transactions
  static const String transactions = '/transactions';
  static const String orders = '/orders';

  // Timeout durations (in milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}
