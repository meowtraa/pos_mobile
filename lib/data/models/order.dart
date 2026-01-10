/// Order Model
/// Represents a complete order/transaction in the POS system with sync support
library;

import '../../../core/sync/sync_status.dart';

/// Represents an item in an order
class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? employeeId;
  final String? employeeName;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.employeeId,
    this.employeeName,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'employeeId': employeeId,
      'employeeName': employeeName,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      employeeId: json['employeeId'] as String?,
      employeeName: json['employeeName'] as String?,
    );
  }
}

/// Represents a complete order/transaction
class Order with Syncable {
  /// Local unique identifier (generated on device)
  final String localId;

  /// Server/Firebase identifier (null if not synced yet)
  final String? firebaseId;

  /// Invoice number (generated format: INV-YYYYMMDD-XXXX)
  final String invoiceNumber;

  /// Store identifier
  final String storeId;

  /// List of items in this order
  final List<OrderItem> items;

  /// Subtotal before discount
  final double subtotal;

  /// Discount amount
  final double discount;

  /// Coupon code used (if any)
  final String? couponCode;

  /// Final total after discount
  final double total;

  /// Payment method (cash, card, qris, etc.)
  final String paymentMethod;

  /// Amount received from customer
  final double amountReceived;

  /// Change to return to customer
  final double change;

  /// Customer name (optional)
  final String? customerName;

  /// Notes for the order
  final String? notes;

  /// Cashier/user who created this order
  final String cashierId;

  /// Cashier name
  final String cashierName;

  /// When the order was created
  final DateTime createdAt;

  // Sync-related fields
  @override
  final SyncStatus syncStatus;

  @override
  final DateTime? lastSyncAt;

  @override
  final String? syncError;

  /// Number of sync retry attempts
  final int retryCount;

  const Order({
    required this.localId,
    this.firebaseId,
    required this.invoiceNumber,
    required this.storeId,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.couponCode,
    required this.total,
    required this.paymentMethod,
    required this.amountReceived,
    required this.change,
    this.customerName,
    this.notes,
    required this.cashierId,
    required this.cashierName,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncAt,
    this.syncError,
    this.retryCount = 0,
  });

  /// Number of items in order
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if order needs sync
  bool get needsSync => syncStatus.needsSync;

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'invoiceNumber': invoiceNumber,
      'storeId': storeId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'couponCode': couponCode,
      'total': total,
      'paymentMethod': paymentMethod,
      'amountReceived': amountReceived,
      'change': change,
      'customerName': customerName,
      'notes': notes,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'synced': syncStatus == SyncStatus.synced,
      'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from Firebase data
  factory Order.fromJson(String firebaseId, Map<String, dynamic> json) {
    return Order(
      localId: json['localId'] as String,
      firebaseId: firebaseId,
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
      syncStatus: json['synced'] == true ? SyncStatus.synced : SyncStatus.pending,
      lastSyncAt: json['lastSyncAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncAt'] as int) : null,
    );
  }

  /// Copy with updated values
  Order copyWith({
    String? localId,
    String? firebaseId,
    String? invoiceNumber,
    String? storeId,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    String? couponCode,
    double? total,
    String? paymentMethod,
    double? amountReceived,
    double? change,
    String? customerName,
    String? notes,
    String? cashierId,
    String? cashierName,
    DateTime? createdAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncAt,
    String? syncError,
    int? retryCount,
  }) {
    return Order(
      localId: localId ?? this.localId,
      firebaseId: firebaseId ?? this.firebaseId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      couponCode: couponCode ?? this.couponCode,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      change: change ?? this.change,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncError: syncError ?? this.syncError,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
