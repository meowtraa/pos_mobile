/// Voucher Model
/// Represents a voucher/coupon from Firebase RTDB
library;

/// Type of voucher discount
enum VoucherType { persen, nominal }

class Voucher {
  /// Unique ID
  final int id;

  /// Voucher code (e.g., MACPOS26)
  final String kode;

  /// Whether voucher is active
  final bool aktif;

  /// Discount type: persen or nominal
  final VoucherType tipe;

  /// Discount value (percentage or amount)
  final double nilai;

  /// Maximum discount amount (for percentage type)
  final double maxPotongan;

  /// Minimum transaction amount to use this voucher
  final double minTransaksi;

  /// Remaining usage quota (null = unlimited)
  final int? kuota;

  /// Start date (null = no date restriction)
  final DateTime? tanggalMulai;

  /// End date (null = no date restriction)
  final DateTime? tanggalSelesai;

  /// Start time (null = no time restriction)
  final String? jamMulai;

  /// End time (null = no time restriction)
  final String? jamSelesai;

  /// Last update timestamp
  final int? updatedAt;

  const Voucher({
    required this.id,
    required this.kode,
    required this.aktif,
    required this.tipe,
    required this.nilai,
    this.maxPotongan = 0,
    this.minTransaksi = 0,
    this.kuota, // Nullable, default null means unlimited
    this.tanggalMulai,
    this.tanggalSelesai,
    this.jamMulai,
    this.jamSelesai,
    this.updatedAt,
  });

  /// Check if voucher is valid for given subtotal at current time
  VoucherValidationResult validate(double subtotal) {
    final now = DateTime.now();

    // Check if voucher is active
    if (!aktif) {
      return VoucherValidationResult.invalid('Voucher tidak aktif');
    }

    // Check quota (skip if null = unlimited)
    if (kuota != null && kuota! <= 0) {
      return VoucherValidationResult.invalid('Kuota voucher sudah habis');
    }

    // Check minimum transaction
    if (subtotal < minTransaksi) {
      return VoucherValidationResult.invalid('Minimum transaksi Rp ${_formatPrice(minTransaksi)}');
    }

    // Check date range (if specified)
    if (tanggalMulai != null) {
      final startDate = DateTime(tanggalMulai!.year, tanggalMulai!.month, tanggalMulai!.day);
      final today = DateTime(now.year, now.month, now.day);
      if (today.isBefore(startDate)) {
        return VoucherValidationResult.invalid('Voucher belum berlaku (mulai ${_formatDate(tanggalMulai!)})');
      }
    }

    if (tanggalSelesai != null) {
      final endDate = DateTime(tanggalSelesai!.year, tanggalSelesai!.month, tanggalSelesai!.day, 23, 59, 59);
      if (now.isAfter(endDate)) {
        return VoucherValidationResult.invalid('Voucher sudah kadaluarsa (sampai ${_formatDate(tanggalSelesai!)})');
      }
    }

    // Check time range (if specified)
    if (jamMulai != null && jamMulai!.isNotEmpty) {
      final startTime = _parseTime(jamMulai!);
      final currentMinutes = now.hour * 60 + now.minute;
      if (currentMinutes < startTime) {
        return VoucherValidationResult.invalid('Voucher berlaku mulai jam $jamMulai');
      }
    }

    if (jamSelesai != null && jamSelesai!.isNotEmpty) {
      final endTime = _parseTime(jamSelesai!);
      final currentMinutes = now.hour * 60 + now.minute;
      if (currentMinutes > endTime) {
        return VoucherValidationResult.invalid('Voucher berlaku sampai jam $jamSelesai');
      }
    }

    return VoucherValidationResult.valid();
  }

  /// Calculate discount amount for given subtotal
  double calculateDiscount(double subtotal) {
    if (tipe == VoucherType.persen) {
      final discount = subtotal * (nilai / 100);
      // Apply max discount limit if specified
      if (maxPotongan > 0 && discount > maxPotongan) {
        return maxPotongan;
      }
      return discount;
    }
    // Nominal discount
    return nilai > subtotal ? subtotal : nilai;
  }

  /// Parse time string (HH:mm) to minutes since midnight
  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return hour * 60 + minute;
    }
    return 0;
  }

  /// Format price for display
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Create from Firebase JSON
  factory Voucher.fromJson(String code, Map<String, dynamic> json) {
    return Voucher(
      id: _parseNum(json['id'])?.toInt() ?? 0,
      kode: json['kode'] as String? ?? code,
      aktif: json['aktif'] as bool? ?? false,
      tipe: _parseType(json['tipe'] as String?),
      nilai: _parseNum(json['nilai'])?.toDouble() ?? 0,
      maxPotongan: _parseNum(json['max_potongan'])?.toDouble() ?? 0,
      minTransaksi: _parseNum(json['min_transaksi'])?.toDouble() ?? 0,
      kuota: _parseKuota(json['kuota']),
      tanggalMulai: _parseDate(json['tanggal_mulai']),
      tanggalSelesai: _parseDate(json['tanggal_selesai']),
      jamMulai: json['jam_mulai'] as String?,
      jamSelesai: json['jam_selesai'] as String?,
      updatedAt: _parseNum(json['updated_at'])?.toInt(),
    );
  }

  /// Parse num from dynamic (handles String or num)
  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode': kode,
      'aktif': aktif,
      'tipe': tipe == VoucherType.persen ? 'persen' : 'nominal',
      'nilai': nilai,
      'max_potongan': maxPotongan,
      'min_transaksi': minTransaksi,
      'kuota': kuota?.toString(), // Null if unlimited
      'tanggal_mulai': tanggalMulai != null
          ? '${tanggalMulai!.year}-${tanggalMulai!.month.toString().padLeft(2, '0')}-${tanggalMulai!.day.toString().padLeft(2, '0')}'
          : null,
      'tanggal_selesai': tanggalSelesai != null
          ? '${tanggalSelesai!.year}-${tanggalSelesai!.month.toString().padLeft(2, '0')}-${tanggalSelesai!.day.toString().padLeft(2, '0')}'
          : null,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'updated_at': updatedAt,
    };
  }

  /// Copy with updated values
  Voucher copyWith({
    int? id,
    String? kode,
    bool? aktif,
    VoucherType? tipe,
    double? nilai,
    double? maxPotongan,
    double? minTransaksi,
    int? kuota,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? jamMulai,
    String? jamSelesai,
    int? updatedAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      aktif: aktif ?? this.aktif,
      tipe: tipe ?? this.tipe,
      nilai: nilai ?? this.nilai,
      maxPotongan: maxPotongan ?? this.maxPotongan,
      minTransaksi: minTransaksi ?? this.minTransaksi,
      kuota: kuota ?? this.kuota,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper parsing methods
  static VoucherType _parseType(String? type) {
    if (type == 'persen') return VoucherType.persen;
    return VoucherType.nominal;
  }

  static int? _parseKuota(dynamic kuota) {
    if (kuota == null || kuota == 'null') return null; // Handle null explicitly
    if (kuota is int) return kuota;
    if (kuota is String) return int.tryParse(kuota); // Can return null
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value == '') return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Voucher(kode: $kode, tipe: $tipe, nilai: $nilai, aktif: $aktif)';
  }
}

/// Result of voucher validation
class VoucherValidationResult {
  final bool isValid;
  final String? errorMessage;

  const VoucherValidationResult._({required this.isValid, this.errorMessage});

  factory VoucherValidationResult.valid() {
    return const VoucherValidationResult._(isValid: true);
  }

  factory VoucherValidationResult.invalid(String message) {
    return VoucherValidationResult._(isValid: false, errorMessage: message);
  }
}
