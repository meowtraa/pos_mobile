import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../sync/sync_status.dart';
import 'connectivity_service.dart';
import 'sync_manager.dart';

/// Order Sync Service
/// Handles local storage of pending orders and auto-sync when connectivity returns
class OrderSyncService extends ChangeNotifier {
  static OrderSyncService? _instance;
  static const String _storageKey = 'pending_orders';

  final List<Order> _pendingOrders = [];
  SharedPreferences? _prefs;
  bool _isSyncing = false;
  bool _wasOnline = true;

  OrderSyncService._();

  static OrderSyncService get instance {
    _instance ??= OrderSyncService._();
    return _instance!;
  }

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingOrders();

    // Store initial connectivity state
    _wasOnline = ConnectivityService.instance.isOnline;

    // Listen to connectivity changes
    ConnectivityService.instance.addListener(_onConnectivityChanged);

    if (kDebugMode) {
      print('📦 [ORDER_SYNC] Initialized with ${_pendingOrders.length} pending orders');
    }
  }

  /// Called when connectivity status changes
  void _onConnectivityChanged() {
    final isNowOnline = ConnectivityService.instance.isOnline;

    // Check if we just came back online
    if (!_wasOnline && isNowOnline) {
      _onConnectivityRestored();
    }

    _wasOnline = isNowOnline;
  }

  /// Get pending orders count
  int get pendingCount => _pendingOrders.length;
  bool get hasPending => _pendingOrders.isNotEmpty;
  List<Order> get pendingOrders => List.unmodifiable(_pendingOrders);

  /// Add an order to pending queue (when offline)
  Future<void> addPendingOrder(Order order) async {
    final pendingOrder = order.copyWith(syncStatus: SyncStatus.pending);
    _pendingOrders.add(pendingOrder);

    // Also add to SyncManager for UI indicator
    SyncManager.instance.addPending(order.localId, 'order', 'Order ${order.invoiceNumber}');

    await _savePendingOrders();
    notifyListeners();

    if (kDebugMode) {
      print('📋 [ORDER_SYNC] Added pending order: ${order.invoiceNumber}');
    }
  }

  /// Try to sync all pending orders
  Future<void> syncPendingOrders() async {
    if (_isSyncing || _pendingOrders.isEmpty) return;
    if (!ConnectivityService.instance.isOnline) return;

    _isSyncing = true;
    notifyListeners();

    if (kDebugMode) {
      print('🔄 [ORDER_SYNC] Syncing ${_pendingOrders.length} pending orders...');
    }

    final ordersToSync = List<Order>.from(_pendingOrders);
    final successfulSyncs = <String>[];

    for (final order in ordersToSync) {
      try {
        // Mark as syncing in SyncManager
        SyncManager.instance.markSyncing(order.localId);

        // Try to create on Firebase
        final syncedOrder = await OrderRepository.instance.createOrder(order);

        if (syncedOrder.syncStatus == SyncStatus.synced) {
          successfulSyncs.add(order.localId);
          SyncManager.instance.markSynced(order.localId);

          if (kDebugMode) {
            print('✅ [ORDER_SYNC] Synced: ${order.invoiceNumber}');
          }
        } else {
          SyncManager.instance.markFailed(order.localId, syncedOrder.syncError ?? 'Unknown error');
        }
      } catch (e) {
        SyncManager.instance.markFailed(order.localId, e.toString());
        if (kDebugMode) {
          print('❌ [ORDER_SYNC] Failed to sync ${order.invoiceNumber}: $e');
        }
      }
    }

    // Remove successfully synced orders from pending list
    _pendingOrders.removeWhere((o) => successfulSyncs.contains(o.localId));
    await _savePendingOrders();

    _isSyncing = false;
    notifyListeners();

    if (kDebugMode) {
      print('✅ [ORDER_SYNC] Sync complete. ${successfulSyncs.length} synced, ${_pendingOrders.length} remaining');
    }
  }

  /// Called when connectivity is restored
  void _onConnectivityRestored() {
    if (kDebugMode) {
      print('📶 [ORDER_SYNC] Connectivity restored! Verifying sync status...');
    }

    // Verify pending items in SyncManager against Firebase
    TransactionRepository.instance.verifySyncStatus();

    // Also sync any pending orders from OrderSyncService
    if (_pendingOrders.isNotEmpty) {
      if (kDebugMode) {
        print('📶 [ORDER_SYNC] Auto-syncing ${_pendingOrders.length} pending orders...');
      }
      syncPendingOrders();
    }
  }

  /// Save pending orders to SharedPreferences
  Future<void> _savePendingOrders() async {
    if (_prefs == null) return;

    try {
      final jsonList = _pendingOrders.map((order) => _orderToStorageJson(order)).toList();
      await _prefs!.setString(_storageKey, jsonEncode(jsonList));

      if (kDebugMode) {
        print('💾 [ORDER_SYNC] Saved ${jsonList.length} pending orders to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ORDER_SYNC] Error saving pending orders: $e');
      }
    }
  }

  /// Load pending orders from SharedPreferences
  Future<void> _loadPendingOrders() async {
    if (_prefs == null) return;

    try {
      final jsonString = _prefs!.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return;

      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      for (final json in jsonList) {
        final order = _orderFromStorageJson(json as Map<String, dynamic>);
        _pendingOrders.add(order);

        // Also add to SyncManager for UI
        SyncManager.instance.addPending(order.localId, 'order', 'Order ${order.invoiceNumber}');
      }

      if (kDebugMode) {
        print('📂 [ORDER_SYNC] Loaded ${_pendingOrders.length} pending orders from storage');
      }

      // Try to sync immediately if online
      if (ConnectivityService.instance.isOnline && _pendingOrders.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), syncPendingOrders);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ORDER_SYNC] Error loading pending orders: $e');
      }
    }
  }

  /// Convert Order to storage JSON (includes all fields needed to recreate)
  Map<String, dynamic> _orderToStorageJson(Order order) {
    return {
      'localId': order.localId,
      'invoiceNumber': order.invoiceNumber,
      'storeId': order.storeId,
      'items': order.items.map((e) => e.toJson()).toList(),
      'subtotal': order.subtotal,
      'discount': order.discount,
      'couponCode': order.couponCode,
      'total': order.total,
      'paymentMethod': order.paymentMethod,
      'amountReceived': order.amountReceived,
      'change': order.change,
      'customerName': order.customerName,
      'notes': order.notes,
      'cashierId': order.cashierId,
      'cashierName': order.cashierName,
      'createdAt': order.createdAt.millisecondsSinceEpoch,
      'retryCount': order.retryCount,
    };
  }

  /// Create Order from storage JSON
  Order _orderFromStorageJson(Map<String, dynamic> json) {
    return Order(
      localId: json['localId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      storeId: json['storeId'] as String,
      items: (json['items'] as List).map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      couponCode: json['couponCode'] as String?,
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      amountReceived: (json['amountReceived'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      customerName: json['customerName'] as String?,
      notes: json['notes'] as String?,
      cashierId: json['cashierId'] as String,
      cashierName: json['cashierName'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      syncStatus: SyncStatus.pending,
      retryCount: (json['retryCount'] as int?) ?? 0,
    );
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
