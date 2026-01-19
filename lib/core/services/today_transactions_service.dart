import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/transaction.dart';

/// Today Transactions Service
/// Stores today's transactions locally for re-printing receipts
/// Auto-clears when day changes
class TodayTransactionsService extends ChangeNotifier {
  static TodayTransactionsService? _instance;
  static const String _storageKey = 'today_transactions';
  static const String _dateKey = 'today_transactions_date';

  SharedPreferences? _prefs;
  List<Transaction> _transactions = [];
  bool _isInitialized = false;

  TodayTransactionsService._();

  static TodayTransactionsService get instance {
    _instance ??= TodayTransactionsService._();
    return _instance!;
  }

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  int get count => _transactions.length;
  bool get isEmpty => _transactions.isEmpty;
  bool get isInitialized => _isInitialized;

  /// Calculate total revenue for today
  double get totalRevenue {
    return _transactions.fold(0, (sum, t) => sum + t.totalHarga);
  }

  /// Calculate cash revenue for today (Tunai)
  double get totalCashRevenue {
    return _transactions
        .where((t) => t.metodePembayaran.toLowerCase() == 'tunai')
        .fold(0, (sum, t) => sum + t.totalHarga);
  }

  /// Calculate non-cash revenue for today (QRIS, Card, etc.)
  double get totalNonCashRevenue {
    return _transactions
        .where((t) => t.metodePembayaran.toLowerCase() != 'tunai')
        .fold(0, (sum, t) => sum + t.totalHarga);
  }

  /// Initialize service
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _checkAndLoadTransactions();
    _isInitialized = true;

    if (kDebugMode) {
      print('📋 TodayTransactionsService initialized: ${_transactions.length} transactions');
    }
  }

  /// Check if date changed and load transactions
  Future<void> _checkAndLoadTransactions() async {
    final today = _getDateString(DateTime.now());
    final savedDate = _prefs?.getString(_dateKey);

    if (savedDate != today) {
      // Different day - clear old data
      if (kDebugMode) {
        print('📋 New day detected. Clearing old transactions.');
      }
      await _clear();
      await _prefs?.setString(_dateKey, today);
    } else {
      // Same day - load existing data
      await _loadTransactions();
    }
  }

  /// Add a transaction to today's list
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await _saveTransactions();
    notifyListeners();

    if (kDebugMode) {
      print('📋 Added transaction: ${transaction.kodeTransaksi}');
    }
  }

  /// Get transaction by code
  Transaction? getByCode(String code) {
    try {
      return _transactions.firstWhere((t) => t.kodeTransaksi == code);
    } catch (_) {
      return null;
    }
  }

  /// Clear all transactions
  Future<void> clear() async {
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    _transactions.clear();
    await _prefs?.remove(_storageKey);
  }

  /// Load transactions from SharedPreferences
  Future<void> _loadTransactions() async {
    try {
      final jsonString = _prefs?.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return;

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      _transactions = jsonList
          .map((json) => Transaction.fromJson(json['kode_transaksi'] as String, Map<String, dynamic>.from(json as Map)))
          .toList();

      // Sort by created_at descending (newest first)
      _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        print('📋 Loaded ${_transactions.length} transactions from storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading transactions: $e');
      }
      _transactions = [];
    }
  }

  /// Save transactions to SharedPreferences
  Future<void> _saveTransactions() async {
    try {
      final jsonList = _transactions.map((t) => t.toJson()).toList();
      await _prefs?.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving transactions: $e');
      }
    }
  }

  /// Get date string for comparison (YYYY-MM-DD)
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
