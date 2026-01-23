/// Customer Model
/// Represents a customer/member in the loyalty system (matching Firebase structure)
library;

class Customer {
  /// Unique ID
  final int id;

  /// Customer name
  final String nama;

  /// WhatsApp number (used as identifier)
  final String noWa;

  /// Address
  final String alamat;

  /// Date of birth (YYYY-MM-DD format)
  final String? tglLahir;

  /// Job/Occupation
  final String? pekerjaan;

  /// Total visits/transactions (for loyalty rewards)
  final int totalKunjungan;

  /// Created timestamp (milliseconds since epoch)
  final int? createdAt;

  /// Updated timestamp (milliseconds since epoch)
  final int? updatedAt;

  const Customer({
    required this.id,
    required this.nama,
    required this.noWa,
    required this.alamat,
    this.tglLahir,
    this.pekerjaan,
    this.totalKunjungan = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Alias getters for backward compatibility
  String get name => nama;
  String get phoneNumber => noWa;
  String get address => alamat;
  int get transactionCount => totalKunjungan;

  Customer copyWith({
    int? id,
    String? nama,
    String? noWa,
    String? alamat,
    String? tglLahir,
    String? pekerjaan,
    int? totalKunjungan,
    int? createdAt,
    int? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      noWa: noWa ?? this.noWa,
      alamat: alamat ?? this.alamat,
      tglLahir: tglLahir ?? this.tglLahir,
      pekerjaan: pekerjaan ?? this.pekerjaan,
      totalKunjungan: totalKunjungan ?? this.totalKunjungan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firebase JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'no_wa': noWa,
      'alamat': alamat,
      'tgl_lahir': tglLahir,
      'pekerjaan': pekerjaan,
      'total_kunjungan': totalKunjungan,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create from Firebase JSON
  factory Customer.fromJson(int id, Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int? ?? id,
      nama: json['nama'] as String? ?? '',
      noWa: json['no_wa'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      tglLahir: json['tgl_lahir'] as String?,
      pekerjaan: json['pekerjaan'] as String?,
      totalKunjungan: json['total_kunjungan'] as int? ?? 0,
      createdAt: json['created_at'] as int?,
      updatedAt: json['updated_at'] as int?,
    );
  }
}
