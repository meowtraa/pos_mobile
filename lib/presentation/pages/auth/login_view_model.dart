import 'package:flutter/foundation.dart';

import '../../../core/services/session_service.dart';
import '../../../data/models/user.dart';
import '../../providers/base_view_model.dart';

/// Login View Model
/// Handles authentication logic for Login Page with demo account
class LoginViewModel extends BaseViewModel {
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  final SessionService _sessionService = SessionService.instance;

  // Demo credentials
  static const String demoEmail = 'demo@machos.pos';
  static const String demoPassword = '123456';

  // Getters
  String get email => _email;
  String get password => _password;
  bool get obscurePassword => _obscurePassword;
  User? get currentUser => _sessionService.currentUser;
  bool get isLoggedIn => _sessionService.isLoggedIn;
  Duration get remainingSessionTime => _sessionService.remainingSessionTime;

  /// Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Set email
  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  /// Set password
  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Fill demo credentials
  void fillDemoCredentials() {
    _email = demoEmail;
    _password = demoPassword;
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login() async {
    if (validateEmail(_email) != null || validatePassword(_password) != null) {
      return false;
    }

    setLoading();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Demo account: demo@machos.pos / 123456
      // OR any email with password "123456"
      if (_password == demoPassword) {
        final user = User(
          id: '1',
          email: _email,
          name: _email.split('@').first.replaceAll('.', ' ').toUpperCase(),
          role: 'demo',
        );

        // Save session with 24h expiry
        await _sessionService.saveSession(user);

        setSuccess();

        if (kDebugMode) {
          print('✅ Login successful: ${user.email}');
          print('⏰ Session expires in 24 hours');
        }

        return true;
      } else {
        setError('Email atau password salah');
        return false;
      }
    } catch (e) {
      setError('Terjadi kesalahan: ${e.toString()}');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _sessionService.clearSession();
    _email = '';
    _password = '';
    setIdle();
  }

  /// Check if session is still valid
  bool checkSession() {
    _sessionService.checkSessionValidity();
    return _sessionService.isLoggedIn;
  }
}
