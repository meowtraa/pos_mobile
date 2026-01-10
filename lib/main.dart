import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/firebase/firebase_config.dart';
import 'core/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  // Initialize Firebase
  try {
    await FirebaseConfig.initialize();
    if (kDebugMode) {
      print('🔥 Firebase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase initialization failed: $e');
    }
  }

  // Initialize Session Service
  try {
    await SessionService.instance.initialize();
    if (kDebugMode) {
      print('📱 Session service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Session initialization failed: $e');
    }
  }

  runApp(const App());
}
