/// Firebase Configuration Example
/// Copy this file to firebase_config.dart and fill in your actual values
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const String databaseUrl = 'YOUR_DATABASE_URL';

  static FirebaseDatabase? _database;

  /// Initialize Firebase with all required configurations
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        databaseURL: databaseUrl,
        storageBucket: 'YOUR_STORAGE_BUCKET',
      ),
    );

    // Get the database instance ONCE
    _database = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseUrl);

    // Enable offline persistence on the SAME instance we use
    _database!.setPersistenceEnabled(true);
    _database!.setPersistenceCacheSizeBytes(10000000); // 10MB cache

    // Keep synced paths - important for offline to work!
    _database!.ref('master_products').keepSynced(true);
    _database!.ref('master_kategori').keepSynced(true);
    _database!.ref('master_staffs').keepSynced(true);
    _database!.ref('transactions').keepSynced(true);

    if (kDebugMode) {
      print('🔥 Firebase initialized with offline persistence');
      print('📱 Database URL: $databaseUrl');
    }
  }

  /// Get the database instance with offline support
  static FirebaseDatabase get database {
    if (_database == null) {
      throw Exception('Firebase not initialized! Call FirebaseConfig.initialize() first.');
    }
    return _database!;
  }
}
