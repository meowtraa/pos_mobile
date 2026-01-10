import 'dart:async';
import 'package:flutter/foundation.dart';

import '../sync/sync_status.dart';

/// Sync Manager
/// Manages sync status for offline-first data operations
class SyncManager extends ChangeNotifier {
  static SyncManager? _instance;

  // Pending items waiting to sync
  final Map<String, SyncItem> _pendingItems = {};

  // Recent synced items (for showing success indicator)
  final List<SyncItem> _recentSynced = [];

  SyncManager._();

  static SyncManager get instance {
    _instance ??= SyncManager._();
    return _instance!;
  }

  /// Get all pending items
  List<SyncItem> get pendingItems => _pendingItems.values.toList();
  int get pendingCount => _pendingItems.length;
  bool get hasPending => _pendingItems.isNotEmpty;

  /// Get recent synced items (last 5)
  List<SyncItem> get recentSynced => _recentSynced.take(5).toList();

  /// Add item to pending sync
  void addPending(String id, String type, String description) {
    _pendingItems[id] = SyncItem(
      id: id,
      type: type,
      description: description,
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    if (kDebugMode) {
      print('📋 [SYNC] Added pending: $id - $description');
    }

    notifyListeners();
  }

  /// Mark item as syncing
  void markSyncing(String id) {
    if (_pendingItems.containsKey(id)) {
      _pendingItems[id] = _pendingItems[id]!.copyWith(status: SyncStatus.syncing);
      notifyListeners();
    }
  }

  /// Mark item as synced (success)
  void markSynced(String id) {
    if (_pendingItems.containsKey(id)) {
      final item = _pendingItems.remove(id)!;
      final syncedItem = item.copyWith(status: SyncStatus.synced, syncedAt: DateTime.now());

      // Add to recent synced list
      _recentSynced.insert(0, syncedItem);

      // No limit - show all synced items

      if (kDebugMode) {
        print('✅ [SYNC] Synced: $id');
      }

      notifyListeners();
    }
  }

  /// Mark item as failed
  void markFailed(String id, String error) {
    if (_pendingItems.containsKey(id)) {
      _pendingItems[id] = _pendingItems[id]!.copyWith(status: SyncStatus.failed, error: error);

      if (kDebugMode) {
        print('❌ [SYNC] Failed: $id - $error');
      }

      notifyListeners();
    }
  }

  /// Clear all pending items
  void clearPending() {
    _pendingItems.clear();
    notifyListeners();
  }

  /// Clear recent synced items
  void clearRecentSynced() {
    _recentSynced.clear();
    notifyListeners();
  }
}

/// Sync Item model
class SyncItem {
  final String id;
  final String type;
  final String description;
  final SyncStatus status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final String? error;

  SyncItem({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.syncedAt,
    this.error,
  });

  SyncItem copyWith({
    String? id,
    String? type,
    String? description,
    SyncStatus? status,
    DateTime? createdAt,
    DateTime? syncedAt,
    String? error,
  }) {
    return SyncItem(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      error: error ?? this.error,
    );
  }
}
