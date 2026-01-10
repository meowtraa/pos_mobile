import 'package:flutter/material.dart';

import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/pos/pos_page.dart';
import '../presentation/pages/profile/profile_page.dart';

/// App Routes
/// Centralized route management
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String home = '/home';
  static const String pos = '/pos';
  static const String login = '/login';
  static const String register = '/register';

  // Products
  static const String products = '/products';
  static const String productDetail = '/products/detail';
  static const String addProduct = '/products/add';

  // Transactions
  static const String transactions = '/transactions';
  static const String checkout = '/checkout';

  // Settings
  static const String settings = '/settings';
  static const String profile = '/profile';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage(), settings: settings);

      case home:
        return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);

      case pos:
        return MaterialPageRoute(builder: (_) => const POSPage(), settings: settings);

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage(), settings: settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
