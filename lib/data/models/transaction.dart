/// Transaction Model
/// Represents a complete transaction in the POS system (matching Firebase structure)
library;

import '../../core/sync/sync_status.dart';
import 'transaction_item.dart';

/// Status of a transaction
enum TransactionStatus { pending, selesai, batal }

class Transaction with Syncable {
  /// Transaction code (e.g., TRX-20260110-001)
  final String kodeTransaksi;

  /// List of items in this transaction
  final List<TransactionItem> items;

  /// Total price before payment
  final double totalHarga;

  /// Amount paid by customer
  final double totalBayar;

  /// Change to give back
  final double totalKembalian;

  /// Payment method (cash, qris, card, etc.)
  final String metodePembayaran;

  /// Transaction status
  final TransactionStatus statusTransaksi;

  /// User/cashier ID who created this transaction
  final int userId;

  /// When the transaction was created
  final DateTime createdAt;

  // Sync-related fields
  @override
  final SyncStatus syncStatus;

  @override
  final DateTime? lastSyncAt;

  @override
  final String? syncError;

  const Transaction({
    required this.kodeTransaksi,
    required this.items,
    required this.totalHarga,
    required this.totalBayar,
    required this.totalKembalian,
    required this.metodePembayaran,
    this.statusTransaksi = TransactionStatus.pending,
    required this.userId,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncAt,
    this.syncError,
  });

  /// Number of items in transaction
  int get itemCount => items.fold(0, (sum, item) => sum + item.jumlah);

  /// Check if transaction needs sync
  bool get needsSync => syncStatus.needsSync;

  /// Check if transaction is completed
  bool get isCompleted => statusTransaksi == TransactionStatus.selesai;

  /// Convert to Firebase JSON format
  Map<String, dynamic> toJson() {
    final itemsMap = <String, dynamic>{};
    for (int i = 0; i < items.length; i++) {
      itemsMap['item_${i + 1}'] = items[i].toJson();
    }

    return {
      'kode_transaksi': kodeTransaksi,
      'items': itemsMap,
      'total_harga': totalHarga,
      'total_bayar': totalBayar,
      'total_kembalian': totalKembalian,
      'metode_pembayaran': metodePembayaran,
      'status_transaksi': _statusToString(statusTransaksi),
      'user_id': userId,
      'created_at': _formatDateTime(createdAt),
    };
  }

  /// Create from Firebase JSON
  factory Transaction.fromJson(String kodeTransaksi, Map<String, dynamic> json) {
    // Parse items from Firebase format
    final itemsData = json['items'] as Map<Object?, Object?>?;
    final items = <TransactionItem>[];

    if (itemsData != null) {
      itemsData.forEach((key, value) {
        if (value != null) {
          items.add(TransactionItem.fromJson(Map<String, dynamic>.from(value as Map)));
        }
      });
    }

    return Transaction(
      kodeTransaksi: json['kode_transaksi'] as String? ?? kodeTransaksi,
      items: items,
      totalHarga: (json['total_harga'] as num).toDouble(),
      totalBayar: (json['total_bayar'] as num).toDouble(),
      totalKembalian: (json['total_kembalian'] as num).toDouble(),
      metodePembayaran: json['metode_pembayaran'] as String,
      statusTransaksi: _stringToStatus(json['status_transaksi'] as String?),
      userId: json['user_id'] as int,
      createdAt: _parseDateTime(json['created_at']),
      syncStatus: SyncStatus.synced,
    );
  }

  /// Copy with updated values
  Transaction copyWith({
    String? kodeTransaksi,
    List<TransactionItem>? items,
    double? totalHarga,
    double? totalBayar,
    double? totalKembalian,
    String? metodePembayaran,
    TransactionStatus? statusTransaksi,
    int? userId,
    DateTime? createdAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    String? syncError,
  }) {
    return Transaction(
      kodeTransaksi: kodeTransaksi ?? this.kodeTransaksi,
      items: items ?? this.items,
      totalHarga: totalHarga ?? this.totalHarga,
      totalBayar: totalBayar ?? this.totalBayar,
      totalKembalian: totalKembalian ?? this.totalKembalian,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      statusTransaksi: statusTransaksi ?? this.statusTransaksi,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncError: syncError ?? this.syncError,
    );
  }

  // Helper methods
  static String _statusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.selesai:
        return 'selesai';
      case TransactionStatus.batal:
        return 'batal';
    }
  }

  static TransactionStatus _stringToStatus(String? status) {
    switch (status) {
      case 'selesai':
        return TransactionStatus.selesai;
      case 'batal':
        return TransactionStatus.batal;
      default:
        return TransactionStatus.pending;
    }
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.parse(value.replaceFirst(' ', 'T'));
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'Transaction(kode: $kodeTransaksi, total: $totalHarga, status: $statusTransaksi)';
  }
}
