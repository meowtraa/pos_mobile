/// Order Repository
/// Handles order data operations with Firebase Realtime Database
/// Supports offline-first pattern with automatic sync
library;

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/firebase_service.dart';
import '../../core/sync/sync_status.dart';
import '../models/order.dart';

class OrderRepository {
  static OrderRepository? _instance;
  final FirebaseService _firebase = FirebaseService.instance;
  final Uuid _uuid = const Uuid();

  // Default store ID - should be set based on logged in user
  String _storeId = 'default_store';

  OrderRepository._();

  static OrderRepository get instance {
    _instance ??= OrderRepository._();
    return _instance!;
  }

  /// Set the current store ID
  void setStoreId(String storeId) {
    _storeId = storeId;
  }

  /// Get the orders path for current store
  String get _ordersPath => 'stores/$_storeId/orders';

  /// Get the counter path for invoice numbers
  String get _counterPath => 'stores/$_storeId/counters';

  /// Generate a unique local ID
  String generateLocalId() {
    return _uuid.v4();
  }

  /// Generate invoice number with sequential counter
  Future<String> generateInvoiceNumber() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final counterRef = _firebase.ref('$_counterPath/$dateStr');

    try {
      final result = await counterRef.runTransaction((current) {
        final currentValue = (current as int?) ?? 0;
        return Transaction.success(currentValue + 1);
      });

      final counter = result.snapshot.value as int;
      return 'INV-$dateStr-${counter.toString().padLeft(4, '0')}';
    } catch (e) {
      // Fallback: use timestamp-based invoice
      final timestamp = today.millisecondsSinceEpoch;
      return 'INV-$dateStr-$timestamp';
    }
  }

  /// Create a new order - works offline!
  Future<Order> createOrder(Order order) async {
    try {
      // Push to Firebase (will be cached if offline)
      final orderRef = _firebase.ref(_ordersPath).push();
      final firebaseId = orderRef.key!;

      // Update order with Firebase ID
      final orderWithId = order.copyWith(
        firebaseId: firebaseId,
        syncStatus: SyncStatus.synced,
        lastSyncAt: DateTime.now(),
      );

      // Save to Firebase
      await orderRef.set(orderWithId.toJson());

      if (kDebugMode) {
        print('✅ Order created: ${order.invoiceNumber}');
      }

      return orderWithId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Create order failed: $e');
      }

      // Return order with pending status (will sync later)
      return order.copyWith(syncStatus: SyncStatus.pending, syncError: e.toString());
    }
  }

  /// Get all orders for current store
  Future<List<Order>> getOrders() async {
    try {
      final snapshot = await _firebase.get(_ordersPath);

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries.map((e) {
        return Order.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get orders failed: $e');
      }
      return [];
    }
  }

  /// Get orders for today
  Future<List<Order>> getTodayOrders() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTimestamp = startOfDay.millisecondsSinceEpoch;

    try {
      final snapshot = await _firebase.query(_ordersPath, orderByChild: 'createdAt', startAt: startTimestamp).get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries.map((e) {
        return Order.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get today orders failed: $e');
      }
      return [];
    }
  }

  /// Get a single order by Firebase ID
  Future<Order?> getOrder(String firebaseId) async {
    try {
      final snapshot = await _firebase.get('$_ordersPath/$firebaseId');

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      return Order.fromJson(firebaseId, Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get order failed: $e');
      }
      return null;
    }
  }

  /// Listen to orders in realtime
  Stream<List<Order>> watchOrders() {
    return _firebase.onValue(_ordersPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Order>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        return Order.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Listen to today's orders in realtime
  Stream<List<Order>> watchTodayOrders() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTimestamp = startOfDay.millisecondsSinceEpoch;

    return _firebase.query(_ordersPath, orderByChild: 'createdAt', startAt: startTimestamp).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Order>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        return Order.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Get daily summary
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _firebase
          .query(
            _ordersPath,
            orderByChild: 'createdAt',
            startAt: startOfDay.millisecondsSinceEpoch,
            endAt: endOfDay.millisecondsSinceEpoch - 1,
          )
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return {'date': date, 'totalOrders': 0, 'totalRevenue': 0.0, 'totalItems': 0};
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final orders = data.entries.map((e) {
        return Order.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList();

      return {
        'date': date,
        'totalOrders': orders.length,
        'totalRevenue': orders.fold<double>(0, (sum, o) => sum + o.total),
        'totalItems': orders.fold<int>(0, (sum, o) => sum + o.itemCount),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get daily summary failed: $e');
      }
      return {'date': date, 'totalOrders': 0, 'totalRevenue': 0.0, 'totalItems': 0};
    }
  }

  /// Delete an order
  Future<bool> deleteOrder(String firebaseId) async {
    try {
      await _firebase.delete('$_ordersPath/$firebaseId');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete order failed: $e');
      }
      return false;
    }
  }
}
