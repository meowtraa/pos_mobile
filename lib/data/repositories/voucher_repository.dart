/// Voucher Repository
/// Handles voucher data operations with Firebase Realtime Database
library;

import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_service.dart';
import '../models/voucher.dart';

class VoucherRepository {
  static VoucherRepository? _instance;
  final FirebaseService _firebase = FirebaseService.instance;

  VoucherRepository._();

  static VoucherRepository get instance {
    _instance ??= VoucherRepository._();
    return _instance!;
  }

  /// Get the vouchers path
  String get _vouchersPath => 'master_vouchers';

  /// Get all vouchers
  Future<List<Voucher>> getVouchers() async {
    try {
      final snapshot = await _firebase.get(_vouchersPath);

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final vouchers = data.entries.map((e) {
        return Voucher.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList();

      if (kDebugMode) {
        print('🎫 Loaded ${vouchers.length} vouchers from Firebase');
      }

      return vouchers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get vouchers failed: $e');
      }
      return [];
    }
  }

  /// Get a single voucher by code
  Future<Voucher?> getVoucherByCode(String code) async {
    try {
      final upperCode = code.toUpperCase().trim();
      final snapshot = await _firebase.get('$_vouchersPath/$upperCode');

      if (!snapshot.exists || snapshot.value == null) {
        if (kDebugMode) {
          print('🎫 Voucher not found: $upperCode');
        }
        return null;
      }

      final voucher = Voucher.fromJson(upperCode, Map<String, dynamic>.from(snapshot.value as Map));

      if (kDebugMode) {
        print('🎫 Voucher found: ${voucher.kode} (${voucher.tipe}, ${voucher.nilai})');
      }

      return voucher;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get voucher failed: $e');
      }
      return null;
    }
  }

  /// Validate and apply voucher
  /// Returns the voucher if valid, null otherwise with error message
  Future<({Voucher? voucher, String? error})> validateVoucher(String code, double subtotal) async {
    try {
      // Get voucher from Firebase
      final voucher = await getVoucherByCode(code);

      if (voucher == null) {
        return (voucher: null, error: 'Kode voucher tidak ditemukan');
      }

      // Validate voucher
      final result = voucher.validate(subtotal);

      if (!result.isValid) {
        return (voucher: null, error: result.errorMessage);
      }

      return (voucher: voucher, error: null);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Validate voucher failed: $e');
      }
      return (voucher: null, error: 'Terjadi kesalahan saat validasi voucher');
    }
  }

  /// Decrease voucher quota after successful use
  Future<bool> useVoucher(String code) async {
    try {
      final upperCode = code.toUpperCase().trim();
      final voucher = await getVoucherByCode(upperCode);

      if (voucher == null || voucher.kuota <= 0) {
        return false;
      }

      // Decrease quota using update with Map
      final newKuota = voucher.kuota - 1;
      await _firebase.update('$_vouchersPath/$upperCode', {
        'kuota': newKuota.toString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      if (kDebugMode) {
        print('🎫 Voucher used: $upperCode (remaining quota: $newKuota)');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Use voucher failed: $e');
      }
      return false;
    }
  }

  /// Listen to voucher changes in realtime
  Stream<List<Voucher>> watchVouchers() {
    return _firebase.onValue(_vouchersPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Voucher>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        return Voucher.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList();
    });
  }
}
