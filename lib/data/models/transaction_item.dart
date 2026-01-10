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

  const TransactionItem({
    required this.produkId,
    required this.namaProduk,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
    this.userId,
  });

  /// Create from Firebase JSON
  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      produkId: json['produk_id'] as int,
      namaProduk: json['nama_produk'] as String,
      hargaSatuan: (json['harga_satuan'] as num).toDouble(),
      jumlah: json['jumlah'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      userId: json['user_id'] as int?,
    );
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'produk_id': produkId,
      'nama_produk': namaProduk,
      'harga_satuan': hargaSatuan,
      'jumlah': jumlah,
      'subtotal': subtotal,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
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
  }) {
    return TransactionItem(
      produkId: produkId ?? this.produkId,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      jumlah: jumlah ?? this.jumlah,
      subtotal: subtotal ?? this.subtotal,
      userId: userId ?? this.userId,
    );
  }
}
