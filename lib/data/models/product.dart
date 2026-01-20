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
  final String? gambar; // Base64 image data
  final int? lastUpdate;
  final int? jmlKepala; // Jumlah kepala (from backend)

  const Product({
    required this.id,
    required this.namaProduk,
    required this.harga,
    required this.kategoriId,
    required this.satuan,
    this.stok = 0,
    this.gambar,
    this.lastUpdate,
    this.jmlKepala,
  });

  // Backward compatible getters for old UI code
  String get name => namaProduk;
  double get price => harga;
  int get stock => stok;
  int get category => kategoriId;

  /// Check if product is a service (satuan = 'org' or 'orang' means it's a service)
  bool get isService {
    final s = satuan.toLowerCase();
    return s == 'org' || s == 'orang';
  }

  /// Check if product is available (services always available, products need stock > 0)
  bool get isAvailable => isService || stok > 0;

  /// Check if product has a base64 image
  bool get hasImage => gambar != null && gambar!.isNotEmpty && gambar != 'data:image/png;base64,';

  /// Create from Firebase JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to safe parse int
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper to safe parse double
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: parseInt(json['id']),
      namaProduk: json['nama_produk'] as String? ?? 'Unknown',
      harga: parseDouble(json['harga']),
      kategoriId: parseInt(json['kategori_id']),
      satuan: json['satuan'] as String? ?? 'pcs',
      stok: parseInt(json['stok']),
      gambar: json['gambar'] as String?,
      lastUpdate: parseInt(json['last_update']),
      jmlKepala: json['jml_kepala'] != null ? parseInt(json['jml_kepala']) : 1,
    );
  }

  /// Legacy factory for old code compatibility
  factory Product.legacy({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
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
      gambar: imageUrl,
    );
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'nama_produk': namaProduk,
      'harga': harga,
      'kategori_id': kategoriId,
      'satuan': satuan,
      'stok': stok,
      'gambar': gambar,
      'last_update': lastUpdate ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    if (jmlKepala != null) map['jml_kepala'] = jmlKepala;
    return map;
  }

  /// Copy with new values
  Product copyWith({
    int? id,
    String? namaProduk,
    double? harga,
    int? kategoriId,
    String? satuan,
    int? stok,
    String? gambar,
    int? lastUpdate,
    int? jmlKepala,
  }) {
    return Product(
      id: id ?? this.id,
      namaProduk: namaProduk ?? this.namaProduk,
      harga: harga ?? this.harga,
      kategoriId: kategoriId ?? this.kategoriId,
      satuan: satuan ?? this.satuan,
      stok: stok ?? this.stok,
      gambar: gambar ?? this.gambar,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      jmlKepala: jmlKepala ?? this.jmlKepala,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, namaProduk: $namaProduk, harga: $harga)';
  }
}
