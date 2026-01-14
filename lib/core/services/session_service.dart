import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user.dart';

/// Session Service
/// Manages user session with 24-hour expiry for demo accounts
class SessionService extends ChangeNotifier {
  static SessionService? _instance;
  static const String _keyLoginTime = 'session_login_time';
  static const String _keyUserEmail = 'session_user_email';
  static const String _keyUserName = 'session_user_name';
  static const String _keyUserId = 'session_user_id';
  static const String _keyUserRole = 'session_user_role';

  /// Session expires after 24 hours
  static const Duration sessionDuration = Duration(hours: 24);

  SharedPreferences? _prefs;
  User? _currentUser;
  DateTime? _loginTime;

  SessionService._();

  static SessionService get instance {
    _instance ??= SessionService._();
    return _instance!;
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && !isSessionExpired;
  DateTime? get loginTime => _loginTime;

  // Convenience getters for user data
  String? get userId => _currentUser?.id;
  String? get userName => _currentUser?.name;
  String? get userEmail => _currentUser?.email;
  String? get userRole => _currentUser?.role;

  /// Check if session is expired
  bool get isSessionExpired {
    if (_loginTime == null) return true;
    final now = DateTime.now();
    final expiryTime = _loginTime!.add(sessionDuration);
    return now.isAfter(expiryTime);
  }

  /// Get remaining session time
  Duration get remainingSessionTime {
    if (_loginTime == null) return Duration.zero;
    final now = DateTime.now();
    final expiryTime = _loginTime!.add(sessionDuration);
    final remaining = expiryTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Initialize session from stored preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSession();

    if (kDebugMode) {
      if (_currentUser != null) {
        print('📱 Session loaded: ${_currentUser!.email}');
        print('⏰ Session expires in: ${remainingSessionTime.inHours}h ${remainingSessionTime.inMinutes % 60}m');
      } else {
        print('📱 No active session');
      }
    }
  }

  /// Load session from SharedPreferences
  Future<void> _loadSession() async {
    final loginTimeMs = _prefs?.getInt(_keyLoginTime);
    final email = _prefs?.getString(_keyUserEmail);
    final name = _prefs?.getString(_keyUserName);
    final id = _prefs?.getString(_keyUserId);
    final role = _prefs?.getString(_keyUserRole);

    if (loginTimeMs != null && email != null && name != null && id != null) {
      _loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimeMs);

      // Check if session expired
      if (!isSessionExpired) {
        _currentUser = User(id: id, email: email, name: name, role: role ?? 'staff');
        notifyListeners();
      } else {
        // Session expired, clear it
        await clearSession();
        if (kDebugMode) {
          print('⏰ Session expired, please login again');
        }
      }
    }
  }

  /// Save session after login
  Future<void> saveSession(User user) async {
    _currentUser = user;
    _loginTime = DateTime.now();

    await _prefs?.setInt(_keyLoginTime, _loginTime!.millisecondsSinceEpoch);
    await _prefs?.setString(_keyUserEmail, user.email);
    await _prefs?.setString(_keyUserName, user.name);
    await _prefs?.setString(_keyUserId, user.id);
    await _prefs?.setString(_keyUserRole, user.role);

    notifyListeners();

    if (kDebugMode) {
      print('💾 Session saved: ${user.email} (${user.role})');
      print('⏰ Session will expire at: ${_loginTime!.add(sessionDuration)}');
    }
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    _currentUser = null;
    _loginTime = null;

    await _prefs?.remove(_keyLoginTime);
    await _prefs?.remove(_keyUserEmail);
    await _prefs?.remove(_keyUserName);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyUserRole);

    notifyListeners();

    if (kDebugMode) {
      print('🚪 Session cleared');
    }
  }

  /// Check session validity (call periodically or on app resume)
  void checkSessionValidity() {
    if (_currentUser != null && isSessionExpired) {
      clearSession();
    }
  }
}
