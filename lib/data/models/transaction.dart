/// Transaction Model
/// Represents a complete transaction in the POS system (matching Firebase structure)
library;

import 'package:intl/intl.dart';
import '../../core/sync/sync_status.dart';
import 'transaction_item.dart';
import 'customer.dart';

/// Status of a transaction
enum TransactionStatus { pending, selesai, batal }

class Transaction with Syncable {
  /// Transaction code (e.g., TRX-20260110-001)
  final String kodeTransaksi;

  /// List of items in this transaction
  final List<TransactionItem> items;

  /// Subtotal before discount (if using voucher)
  final double? subtotal;

  /// Discount amount from voucher
  final double? diskon;

  /// Discount amount from member loyalty
  final double? diskonMember;

  /// Voucher code used (if any)
  final String? kodeVoucher;

  /// Voucher ID used (if any)
  final int? voucherId;

  /// Customer object (snapshot)
  final Customer? customer;

  /// Total price (after discount)
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
    this.subtotal,
    this.diskon,
    this.diskonMember,
    this.kodeVoucher,
    this.voucherId,
    this.customer,
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
    // Convert items to array
    final itemsList = items.map((item) => item.toJson()).toList();

    final json = <String, dynamic>{
      'kode_transaksi': kodeTransaksi,
      'items': itemsList,
      'total_harga': totalHarga,
      'total_bayar': totalBayar,
      'total_kembalian': totalKembalian,
      'metode_pembayaran': metodePembayaran,
      'status_transaksi': _statusToString(statusTransaksi),
      'user_id': userId,
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
    };

    // Add optional fields
    if (diskon != null && diskon! > 0) json['diskon'] = diskon;
    if (diskonMember != null && diskonMember! > 0) json['diskon_loyalty'] = diskonMember;
    if (kodeVoucher != null && kodeVoucher!.isNotEmpty) json['kode_voucher'] = kodeVoucher;
    if (voucherId != null) json['voucher_id'] = voucherId;
    if (customer != null) json['customer'] = customer!.toJson();

    return json;
  }

  /// Create from Firebase JSON
  factory Transaction.fromJson(String kodeTransaksi, Map<String, dynamic> json) {
    // Parse items - support both array and map format
    final items = <TransactionItem>[];
    final itemsData = json['items'];

    if (itemsData is List) {
      // Array format: [{...}, {...}]
      for (final item in itemsData) {
        if (item != null) {
          items.add(TransactionItem.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      }
    } else if (itemsData is Map) {
      // Map format: {item_1: {...}, item_2: {...}}
      itemsData.forEach((key, value) {
        if (value != null) {
          items.add(TransactionItem.fromJson(Map<String, dynamic>.from(value as Map)));
        }
      });
    }

    return Transaction(
      kodeTransaksi: json['kode_transaksi'] as String? ?? kodeTransaksi,
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      diskon: (json['diskon'] as num?)?.toDouble(),
      diskonMember: (json['diskon_loyalty'] as num?)?.toDouble(),
      kodeVoucher: json['kode_voucher'] as String?,
      voucherId: json['voucher_id'] as int?,
      customer: json['customer'] != null
          ? Customer.fromJson(0, Map<String, dynamic>.from(json['customer'] as Map))
          : null,
      totalHarga: (json['total_harga'] as num).toDouble(),
      totalBayar: (json['total_bayar'] as num).toDouble(),
      totalKembalian: (json['total_kembalian'] as num).toDouble(),
      metodePembayaran: json['metode_pembayaran'] as String? ?? 'tunai',
      statusTransaksi: _stringToStatus(json['status_transaksi'] as String?),
      userId: json['user_id'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      syncStatus: SyncStatus.synced,
    );
  }

  /// Copy with updated values
  Transaction copyWith({
    String? kodeTransaksi,
    List<TransactionItem>? items,
    double? subtotal,
    double? diskon,
    double? diskonMember,
    String? kodeVoucher,
    int? voucherId,
    Customer? customer,
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
      subtotal: subtotal ?? this.subtotal,
      diskon: diskon ?? this.diskon,
      diskonMember: diskonMember ?? this.diskonMember,
      kodeVoucher: kodeVoucher ?? this.kodeVoucher,
      voucherId: voucherId ?? this.voucherId,
      customer: customer ?? this.customer,
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

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.parse(value.replaceFirst(' ', 'T'));
    } else if (value is int) {
      // Handle both milliseconds and seconds timestamp
      // If value is less than year 2100 in milliseconds, it's likely in seconds
      if (value < 4102444800) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'Transaction(kode: $kodeTransaksi, total: $totalHarga, status: $statusTransaksi)';
  }
}
