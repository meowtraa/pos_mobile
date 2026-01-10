/// Product Model
/// Represents a product or service in the POS system (matching Firebase structure)
library;

class Product {
  final int id;
  final String namaProduk;
  final double harga;
  final int kategoriId;
  final String satuan;
  final int stok;
  final String? imageUrl; // Optional image URL

  const Product({
    required this.id,
    required this.namaProduk,
    required this.harga,
    required this.kategoriId,
    required this.satuan,
    this.stok = 0,
    this.imageUrl,
  });

  // Backward compatible getters for old UI code
  String get name => namaProduk;
  double get price => harga;
  int get stock => stok;
  String get category => kategoriId == 1 ? 'Layanan Barber' : 'Produk';

  /// Check if product is a service (satuan = 'org' means it's a service)
  bool get isService => satuan == 'org';

  /// Check if product is available (for non-service items)
  bool get isAvailable => isService || stok > 0;

  /// Create from Firebase JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      namaProduk: json['nama_produk'] as String,
      harga: (json['harga'] as num).toDouble(),
      kategoriId: json['kategori_id'] as int,
      satuan: json['satuan'] as String,
      stok: json['stok'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Legacy factory for old code compatibility
  factory Product.legacy({
    required String id,
    required String name,
    required double price,
    required String imageUrl,
    required String category,
    int? stock,
    bool isService = false,
  }) {
    return Product(
      id: int.tryParse(id) ?? 0,
      namaProduk: name,
      harga: price,
      kategoriId: isService ? 1 : 2, // 1 = jasa, 2 = produk
      satuan: isService ? 'org' : 'pcs',
      stok: stock ?? 0,
      imageUrl: imageUrl,
    );
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_produk': namaProduk,
      'harga': harga,
      'kategori_id': kategoriId,
      'satuan': satuan,
      'stok': stok,
      'image_url': imageUrl,
    };
  }

  /// Copy with new values
  Product copyWith({
    int? id,
    String? namaProduk,
    double? harga,
    int? kategoriId,
    String? satuan,
    int? stok,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      namaProduk: namaProduk ?? this.namaProduk,
      harga: harga ?? this.harga,
      kategoriId: kategoriId ?? this.kategoriId,
      satuan: satuan ?? this.satuan,
      stok: stok ?? this.stok,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, namaProduk: $namaProduk, harga: $harga)';
  }
}
