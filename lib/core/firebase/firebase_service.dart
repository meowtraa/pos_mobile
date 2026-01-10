/// Firebase Service
/// Base service for Firebase Realtime Database operations with debug logging
library;

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'firebase_config.dart';

class FirebaseService {
  static FirebaseService? _instance;
  late final FirebaseDatabase _database;

  FirebaseService._() {
    _database = FirebaseConfig.database;
  }

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseDatabase get database => _database;

  /// Get a reference to a path in the database
  DatabaseReference ref(String path) {
    return _database.ref(path);
  }

  /// Default timeout for write operations
  static const Duration _writeTimeout = Duration(seconds: 10);

  /// Write data to a path (POST/CREATE) with timeout
  Future<void> set(String path, Map<String, dynamic> data, {Duration? timeout}) async {
    if (kDebugMode) {
      print('🔥 [SET] Path: $path');
      print('📤 Data: ${_truncateData(data)}');
    }
    try {
      await ref(path)
          .set(data)
          .timeout(
            timeout ?? _writeTimeout,
            onTimeout: () {
              if (kDebugMode) {
                print('⏱️ [SET] Timeout: $path - will sync later');
              }
              // Don't throw - data is cached locally, will sync when online
            },
          );
      if (kDebugMode) {
        print('✅ [SET] Success: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SET] Error: $path - $e');
      }
      rethrow;
    }
  }

  /// Push new data and get the generated key (POST with auto-ID) with timeout
  Future<String> push(String path, Map<String, dynamic> data, {Duration? timeout}) async {
    if (kDebugMode) {
      print('🔥 [PUSH] Path: $path');
      print('📤 Data: ${_truncateData(data)}');
    }
    try {
      final newRef = ref(path).push();
      await newRef
          .set(data)
          .timeout(
            timeout ?? _writeTimeout,
            onTimeout: () {
              if (kDebugMode) {
                print('⏱️ [PUSH] Timeout: $path - will sync later');
              }
            },
          );
      if (kDebugMode) {
        print('✅ [PUSH] Success: $path -> Key: ${newRef.key}');
      }
      return newRef.key!;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PUSH] Error: $path - $e');
      }
      rethrow;
    }
  }

  /// Update data at a path (PATCH/UPDATE)
  Future<void> update(String path, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('🔥 [UPDATE] Path: $path');
      print('📤 Data: ${_truncateData(data)}');
    }
    try {
      await ref(path).update(data);
      if (kDebugMode) {
        print('✅ [UPDATE] Success: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UPDATE] Error: $path - $e');
      }
      rethrow;
    }
  }

  /// Delete data at a path (DELETE)
  Future<void> delete(String path) async {
    if (kDebugMode) {
      print('🔥 [DELETE] Path: $path');
    }
    try {
      await ref(path).remove();
      if (kDebugMode) {
        print('✅ [DELETE] Success: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [DELETE] Error: $path - $e');
      }
      rethrow;
    }
  }

  /// Read data once from a path (GET)
  Future<DataSnapshot> get(String path) async {
    if (kDebugMode) {
      print('🔥 [GET] Path: $path');
    }
    try {
      final snapshot = await ref(path).get();
      if (kDebugMode) {
        print('✅ [GET] Success: $path - Exists: ${snapshot.exists}');
        if (snapshot.exists) {
          print('📥 Data: ${_truncateData(snapshot.value)}');
        }
      }
      return snapshot;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GET] Error: $path - $e');
      }
      rethrow;
    }
  }

  /// Listen to realtime changes at a path
  Stream<DatabaseEvent> onValue(String path) {
    if (kDebugMode) {
      print('👂 [LISTEN] Subscribing to: $path');
    }
    return ref(path).onValue.map((event) {
      if (kDebugMode) {
        print('📡 [STREAM] Value changed at: $path');
      }
      return event;
    });
  }

  /// Listen to child added events
  Stream<DatabaseEvent> onChildAdded(String path) {
    if (kDebugMode) {
      print('👂 [LISTEN] Child added at: $path');
    }
    return ref(path).onChildAdded;
  }

  /// Listen to child changed events
  Stream<DatabaseEvent> onChildChanged(String path) {
    if (kDebugMode) {
      print('👂 [LISTEN] Child changed at: $path');
    }
    return ref(path).onChildChanged;
  }

  /// Listen to child removed events
  Stream<DatabaseEvent> onChildRemoved(String path) {
    if (kDebugMode) {
      print('👂 [LISTEN] Child removed at: $path');
    }
    return ref(path).onChildRemoved;
  }

  /// Query data with filters
  Query query(
    String path, {
    String? orderByChild,
    dynamic startAt,
    dynamic endAt,
    dynamic equalTo,
    int? limitToFirst,
    int? limitToLast,
  }) {
    if (kDebugMode) {
      print('🔍 [QUERY] Path: $path');
      if (orderByChild != null) print('   orderByChild: $orderByChild');
      if (equalTo != null) print('   equalTo: $equalTo');
      if (limitToFirst != null) print('   limitToFirst: $limitToFirst');
      if (limitToLast != null) print('   limitToLast: $limitToLast');
    }

    Query query = ref(path);

    if (orderByChild != null) {
      query = query.orderByChild(orderByChild);
    }

    if (startAt != null) {
      query = query.startAt(startAt);
    }

    if (endAt != null) {
      query = query.endAt(endAt);
    }

    if (equalTo != null) {
      query = query.equalTo(equalTo);
    }

    if (limitToFirst != null) {
      query = query.limitToFirst(limitToFirst);
    }

    if (limitToLast != null) {
      query = query.limitToLast(limitToLast);
    }

    return query;
  }

  /// Run a transaction
  Future<TransactionResult> runTransaction(String path, TransactionHandler handler) async {
    if (kDebugMode) {
      print('🔥 [TRANSACTION] Path: $path');
    }
    try {
      final result = await ref(path).runTransaction(handler);
      if (kDebugMode) {
        print('✅ [TRANSACTION] Success: $path - Committed: ${result.committed}');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [TRANSACTION] Error: $path - $e');
      }
      rethrow;
    }
  }

  /// Server timestamp
  Object get serverTimestamp => ServerValue.timestamp;

  /// Generate a unique key
  String generateKey(String path) {
    final key = ref(path).push().key!;
    if (kDebugMode) {
      print('🔑 [KEY] Generated: $key for path: $path');
    }
    return key;
  }

  /// Helper to truncate data for logging
  String _truncateData(dynamic data) {
    final str = data.toString();
    if (str.length > 200) {
      return '${str.substring(0, 200)}...';
    }
    return str;
  }
}
