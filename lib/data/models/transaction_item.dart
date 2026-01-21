/// Transaction Item Model
/// Represents an item in a transaction
library;

class TransactionItem {
  final int produkId;
  final String namaProduk;
  final double hargaSatuan;
  final int jumlah;
  final double subtotal;
  final int? userId; // Staff/kapster ID for services
  final String? kapsterName; // Staff/kapster name for services
  final int jmlKepala; // Jumlah kepala per item

  const TransactionItem({
    required this.produkId,
    required this.namaProduk,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
    this.userId,
    this.kapsterName,
    this.jmlKepala = 1,
  });

  // Helper to safe parse int
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Create from Firebase JSON
  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      produkId: json['produk_id'] as int? ?? 0,
      namaProduk: json['produk'] as String? ?? json['nama_produk'] as String,
      hargaSatuan: (json['harga'] as num? ?? json['harga_satuan'] as num).toDouble(),
      jumlah: json['qty'] as int? ?? json['jumlah'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      userId: json['user_id'] as int?,
      kapsterName: json['kapster_name'] as String?,
      jmlKepala: json['jml_kepala'] != null ? _parseInt(json['jml_kepala']) : 1,
    );
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'produk': namaProduk,
      'harga': hargaSatuan,
      'qty': jumlah,
      'subtotal': subtotal,
      'jml_kepala': jmlKepala,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    // Note: kapster_name is NOT saved to Firebase
    // It will be looked up from user_id when displaying
    return map;
  }

  /// Copy with new values
  TransactionItem copyWith({
    int? produkId,
    String? namaProduk,
    double? hargaSatuan,
    int? jumlah,
    double? subtotal,
    int? userId,
    String? kapsterName,
    int? jmlKepala,
  }) {
    return TransactionItem(
      produkId: produkId ?? this.produkId,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      jumlah: jumlah ?? this.jumlah,
      subtotal: subtotal ?? this.subtotal,
      userId: userId ?? this.userId,
      kapsterName: kapsterName ?? this.kapsterName,
      jmlKepala: jmlKepala ?? this.jmlKepala,
    );
  }
}
