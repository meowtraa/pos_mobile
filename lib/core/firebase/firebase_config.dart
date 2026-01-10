/// Firebase Configuration
/// Contains Firebase initialization and configuration settings
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const String databaseUrl = 'https://pos-fire-d563d-default-rtdb.asia-southeast1.firebasedatabase.app';

  static FirebaseDatabase? _database;

  /// Initialize Firebase with all required configurations
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBxTcQ2FgA-YyR38LxYMuo7fsgtg4iYI4M',
        appId: '1:423393494164:android:82970b75e83e56edb86081',
        messagingSenderId: '423393494164',
        projectId: 'pos-fire-d563d',
        databaseURL: databaseUrl,
        storageBucket: 'pos-fire-d563d.firebasestorage.app',
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
