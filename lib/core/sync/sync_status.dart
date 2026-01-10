/// Sync Status Enum and Model
/// Represents the synchronization state of data
library;

/// Status of data synchronization with Firebase
enum SyncStatus {
  /// Data is synchronized with server
  synced,

  /// Data is pending sync (created/modified offline)
  pending,

  /// Data is currently syncing
  syncing,

  /// Sync failed, will retry
  failed,
}

/// Extension on SyncStatus for utility methods
extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.synced:
        return 'Tersinkron';
      case SyncStatus.pending:
        return 'Menunggu Sinkron';
      case SyncStatus.syncing:
        return 'Sedang Sinkron...';
      case SyncStatus.failed:
        return 'Gagal Sinkron';
    }
  }

  String get emoji {
    switch (this) {
      case SyncStatus.synced:
        return '🟢';
      case SyncStatus.pending:
        return '🟡';
      case SyncStatus.syncing:
        return '🔵';
      case SyncStatus.failed:
        return '🔴';
    }
  }

  bool get needsSync => this == SyncStatus.pending || this == SyncStatus.failed;
}

/// Mixin for models that can be synced
mixin Syncable {
  SyncStatus get syncStatus;
  DateTime? get lastSyncAt;
  String? get syncError;
}
