import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/firebase/firebase_config.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/printer_service.dart';
import 'core/services/session_service.dart';
import 'core/services/sync_manager.dart';
import 'core/services/order_sync_service.dart';
import 'data/repositories/transaction_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to landscape only
  // await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

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

  // Initialize Connectivity Service FIRST (before other services that depend on it)
  try {
    await ConnectivityService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Connectivity service initialization failed: $e');
    }
  }

  // Initialize Printer Service (auto-reconnect to last printer)
  try {
    await PrinterService.instance.init();
    if (kDebugMode) {
      print('🖨️ Printer service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Printer service initialization failed: $e');
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

  // Initialize Sync Manager (load persisted pending items)
  try {
    await SyncManager.instance.init();
    if (kDebugMode) {
      print('🔄 Sync manager initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Sync manager initialization failed: $e');
    }
  }

  // Initialize Order Sync Service (auto-sync pending orders when online)
  try {
    await OrderSyncService.instance.init();
    if (kDebugMode) {
      print('📦 Order sync service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Order sync service initialization failed: $e');
    }
  }

  // Verify sync status - check if pending items are already synced to Firebase
  try {
    await TransactionRepository.instance.verifySyncStatus();
    if (kDebugMode) {
      print('✅ Sync status verified');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Sync verification failed: $e');
    }
  }

  runApp(const App());
}
