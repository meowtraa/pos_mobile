import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../../core/firebase/firebase_service.dart';
import '../../../core/services/session_service.dart';
import '../../../data/models/user.dart';
import '../../providers/base_view_model.dart';

/// Login View Model
/// Handles authentication with Firebase Auth + RTDB profile fetch
class LoginViewModel extends BaseViewModel {
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  final SessionService _sessionService = SessionService.instance;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseService _firebase = FirebaseService.instance;

  // Demo credentials (for easy testing)
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

  /// Fill demo credentials for testing
  void fillDemoCredentials() {
    _email = demoEmail;
    _password = demoPassword;
    notifyListeners();
  }

  /// Login with Firebase Auth + fetch profile from RTDB
  Future<bool> login() async {
    if (validateEmail(_email) != null || validatePassword(_password) != null) {
      return false;
    }

    setLoading();

    if (kDebugMode) {
      print('🔐 [LOGIN] Starting login for: $_email');
    }

    try {
      // Step 1: Authenticate with Firebase Auth
      if (kDebugMode) {
        print('🔐 [LOGIN] Step 1: Firebase Auth...');
      }

      final credential = await _auth.signInWithEmailAndPassword(email: _email.trim(), password: _password);

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        setError('Login gagal: User tidak ditemukan');
        if (kDebugMode) {
          print('❌ [LOGIN] Firebase Auth returned null user');
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ [LOGIN] Firebase Auth success');
        print('   └── UID: ${firebaseUser.uid}');
        print('   └── Email: ${firebaseUser.email}');
        print('   └── DisplayName: ${firebaseUser.displayName}');
      }

      // Step 2: Fetch user profile from master_staffs by email
      if (kDebugMode) {
        print('🔐 [LOGIN] Step 2: Fetching profile from master_staffs...');
      }

      final userData = await _fetchUserByEmail(_email.trim());

      if (userData == null) {
        // User authenticated but not in master_staffs
        if (kDebugMode) {
          print('⚠️ [LOGIN] User not found in master_staffs, using default profile');
        }

        final user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? _email,
          name: firebaseUser.displayName ?? _email.split('@').first,
          role: 'staff',
        );

        await _sessionService.saveSession(user);
        setSuccess();

        if (kDebugMode) {
          print('✅ [LOGIN] Login complete (default profile)');
          print('   └── ID: ${user.id}');
          print('   └── Name: ${user.name}');
          print('   └── Role: ${user.role}');
        }

        return true;
      }

      // Step 3: Create user with data from master_staffs
      if (kDebugMode) {
        print('✅ [LOGIN] Found user in master_staffs');
        print('   └── Data: $userData');
      }

      final user = User(
        id: userData['id']?.toString() ?? firebaseUser.uid,
        email: userData['email'] as String? ?? firebaseUser.email ?? _email,
        name: userData['name'] as String? ?? firebaseUser.displayName ?? _email.split('@').first,
        role: userData['role'] as String? ?? 'staff',
      );

      // Step 4: Save session
      await _sessionService.saveSession(user);

      setSuccess();

      if (kDebugMode) {
        print('✅ [LOGIN] Login complete!');
        print('   └── ID: ${user.id}');
        print('   └── Email: ${user.email}');
        print('   └── Name: ${user.name}');
        print('   └── Role: ${user.role}');
      }

      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          errorMessage = 'Password salah';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        case 'user-disabled':
          errorMessage = 'Akun telah dinonaktifkan';
          break;
        case 'too-many-requests':
          errorMessage = 'Terlalu banyak percobaan, coba lagi nanti';
          break;
        case 'invalid-credential':
          errorMessage = 'Email atau password salah';
          break;
        default:
          errorMessage = 'Login gagal: ${e.message}';
      }
      setError(errorMessage);
      if (kDebugMode) {
        print('❌ [LOGIN] Firebase Auth error: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      setError('Terjadi kesalahan: ${e.toString()}');
      if (kDebugMode) {
        print('❌ [LOGIN] Error: $e');
      }
      return false;
    }
  }

  /// Fetch user data from master_staffs by email
  Future<Map<String, dynamic>?> _fetchUserByEmail(String email) async {
    try {
      if (kDebugMode) {
        print('🔍 [LOGIN] Searching master_staffs for: $email');
      }

      final snapshot = await _firebase.get('master_staffs');

      if (!snapshot.exists || snapshot.value == null) {
        if (kDebugMode) {
          print('⚠️ [LOGIN] master_staffs is empty or not found');
        }
        return null;
      }

      final data = snapshot.value;

      // Handle both List and Map formats
      if (data is List) {
        for (var i = 0; i < data.length; i++) {
          final item = data[i];
          if (item != null && item is Map) {
            final staffEmail = item['email'] as String?;
            if (staffEmail?.toLowerCase() == email.toLowerCase()) {
              if (kDebugMode) {
                print('✅ [LOGIN] Found match at index $i');
              }
              return Map<String, dynamic>.from(item);
            }
          }
        }
      } else if (data is Map) {
        for (var entry in data.entries) {
          if (entry.value != null && entry.value is Map) {
            final staffEmail = entry.value['email'] as String?;
            if (staffEmail?.toLowerCase() == email.toLowerCase()) {
              if (kDebugMode) {
                print('✅ [LOGIN] Found match at key ${entry.key}');
              }
              return Map<String, dynamic>.from(entry.value);
            }
          }
        }
      }

      if (kDebugMode) {
        print('⚠️ [LOGIN] No matching email found in master_staffs');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOGIN] Error fetching user: $e');
      }
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    if (kDebugMode) {
      print('🚪 [LOGOUT] Logging out...');
    }

    try {
      await _auth.signOut();
      if (kDebugMode) {
        print('✅ [LOGOUT] Firebase signOut complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [LOGOUT] Firebase signOut error: $e');
      }
    }
    await _sessionService.clearSession();
    _email = '';
    _password = '';
    setIdle();

    if (kDebugMode) {
      print('✅ [LOGOUT] Logout complete');
    }
  }

  /// Check if session is still valid
  bool checkSession() {
    _sessionService.checkSessionValidity();
    return _sessionService.isLoggedIn;
  }
}
