import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/sync_status.dart';

/// Sync Manager
/// Manages sync status for offline-first data operations
/// Persists pending items to SharedPreferences for app restart survival
class SyncManager extends ChangeNotifier {
  static SyncManager? _instance;
  static const String _storageKey = 'pending_sync_items';

  // Pending items waiting to sync
  final Map<String, SyncItem> _pendingItems = {};

  // Recent synced items (for showing success indicator)
  final List<SyncItem> _recentSynced = [];

  // SharedPreferences instance
  SharedPreferences? _prefs;

  SyncManager._();

  static SyncManager get instance {
    _instance ??= SyncManager._();
    return _instance!;
  }

  /// Initialize the sync manager and load persisted data
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromStorage();

    if (kDebugMode) {
      print('📦 [SYNC] Initialized with ${_pendingItems.length} pending items');
    }
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

    _saveToStorage();
    notifyListeners();
  }

  /// Mark item as syncing
  void markSyncing(String id) {
    if (_pendingItems.containsKey(id)) {
      _pendingItems[id] = _pendingItems[id]!.copyWith(status: SyncStatus.syncing);
      _saveToStorage();
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

      _saveToStorage();
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

      _saveToStorage();
      notifyListeners();
    }
  }

  /// Clear all pending items
  void clearPending() {
    _pendingItems.clear();
    _saveToStorage();
    notifyListeners();
  }

  /// Clear recent synced items
  void clearRecentSynced() {
    _recentSynced.clear();
    notifyListeners();
  }

  /// Save pending items to SharedPreferences
  Future<void> _saveToStorage() async {
    if (_prefs == null) return;

    try {
      final List<Map<String, dynamic>> jsonList = _pendingItems.values.map((item) => item.toJson()).toList();

      await _prefs!.setString(_storageKey, jsonEncode(jsonList));

      if (kDebugMode) {
        print('💾 [SYNC] Saved ${jsonList.length} pending items to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SYNC] Error saving to storage: $e');
      }
    }
  }

  /// Load pending items from SharedPreferences
  Future<void> _loadFromStorage() async {
    if (_prefs == null) return;

    try {
      final String? jsonString = _prefs!.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return;

      final List<dynamic> jsonList = jsonDecode(jsonString);

      for (final json in jsonList) {
        final item = SyncItem.fromJson(json as Map<String, dynamic>);
        _pendingItems[item.id] = item;
      }

      if (kDebugMode) {
        print('📂 [SYNC] Loaded ${_pendingItems.length} pending items from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SYNC] Error loading from storage: $e');
      }
    }
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

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'description': description,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
    'error': error,
  };

  /// Create from JSON
  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      status: SyncStatus.values.firstWhere((s) => s.name == json['status'], orElse: () => SyncStatus.pending),
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt'] as String) : null,
      error: json['error'] as String?,
    );
  }

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
