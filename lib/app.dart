import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/login_view_model.dart';
import 'presentation/pages/pos/pos_page.dart';
import 'presentation/pages/pos/pos_view_model.dart';
import 'presentation/pages/profile/profile_view_model.dart';
import 'presentation/providers/theme_view_model.dart';
import 'routes/app_routes.dart';

/// Main App Widget
/// Root widget of the application
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user has valid session
    final hasValidSession = SessionService.instance.isLoggedIn;

    return MultiProvider(
      providers: [
        // Theme ViewModel
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        // Auth ViewModel
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        // POS ViewModel
        ChangeNotifierProvider(create: (_) => POSViewModel()),
        // Profile ViewModel
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          return MaterialApp(
            title: "Macho's POS",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeViewModel.themeMode,
            // Auto-redirect to POS if session is valid
            home: hasValidSession ? const POSPage() : const LoginPage(),
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
