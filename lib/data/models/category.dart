/// Category Model
/// Represents a product/service category in the POS system
library;

/// Tipe kategori
enum CategoryType { jasa, produk }

class Category {
  final int id;
  final String namaKategori;
  final CategoryType tipe;

  const Category({required this.id, required this.namaKategori, required this.tipe});

  /// Check if this is a service category
  bool get isService => tipe == CategoryType.jasa;

  /// Check if this is a product category
  bool get isProduct => tipe == CategoryType.produk;

  /// Create from Firebase JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    // Safe parsing for ID
    int id = 0;
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] is String) {
      id = int.tryParse(json['id']) ?? 0;
    }

    return Category(
      id: id,
      namaKategori: json['nama_kategori'] as String? ?? 'Unknown',
      tipe: (json['tipe'] as String?)?.toLowerCase() == 'produk' ? CategoryType.produk : CategoryType.jasa,
    );
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'nama_kategori': namaKategori, 'tipe': tipe == CategoryType.jasa ? 'jasa' : 'produk'};
  }

  /// Copy with new values
  Category copyWith({int? id, String? namaKategori, CategoryType? tipe}) {
    return Category(id: id ?? this.id, namaKategori: namaKategori ?? this.namaKategori, tipe: tipe ?? this.tipe);
  }

  // Backward compatible getters
  /// Category ID as string for old UI code
  String get categoryId => id.toString();

  /// Category name for old UI code
  String get name => namaKategori;

  /// Static list of default categories for UI (legacy support)
  static final List<Category> categories = [
    const Category(id: 0, namaKategori: 'Semua', tipe: CategoryType.jasa),
    const Category(id: 1, namaKategori: 'Layanan Barber', tipe: CategoryType.jasa),
    const Category(id: 2, namaKategori: 'Produk', tipe: CategoryType.produk),
  ];
}
