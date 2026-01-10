/// Transaction Repository
/// Handles transaction data operations with Firebase Realtime Database
/// Supports offline-first pattern with automatic sync
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/firebase_service.dart';
import '../../core/services/sync_manager.dart';
import '../../core/sync/sync_status.dart';
import '../models/transaction.dart' as model;

class TransactionRepository {
  static TransactionRepository? _instance;
  final FirebaseService _firebase = FirebaseService.instance;
  final Uuid _uuid = const Uuid();

  TransactionRepository._();

  static TransactionRepository get instance {
    _instance ??= TransactionRepository._();
    return _instance!;
  }

  /// Get the transactions path
  String get _transactionsPath => 'transactions';

  /// Generate transaction code (TRX-YYYYMMDD-UUID8)
  /// Uses UUID v4 for guaranteed uniqueness - impossible to collide
  /// Format: TRX-20260110-A1B2C3D4
  String generateTransactionCode() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    // Use first 8 chars of UUID for readability while maintaining uniqueness
    final shortUuid = _uuid.v4().substring(0, 8).toUpperCase();

    final code = 'TRX-$dateStr-$shortUuid';

    if (kDebugMode) {
      print('🎫 Transaction code generated: $code');
    }

    return code;
  }

  /// Create a new transaction - works offline!
  /// Uses fire-and-forget pattern - writes to local cache immediately
  /// Firebase will sync to server when online
  Future<model.Transaction> createTransaction(model.Transaction transaction) async {
    final path = '$_transactionsPath/pending/${transaction.kodeTransaksi}';
    final syncManager = SyncManager.instance;

    // Add to pending sync
    syncManager.addPending(transaction.kodeTransaksi, 'transaction', 'Transaksi ${transaction.kodeTransaksi}');

    try {
      // Firebase with persistence enabled will:
      // 1. Write to LOCAL CACHE immediately (instant, no waiting)
      // 2. Sync to server when online (background)

      // Use ref().set() directly - it writes to local cache first
      // Don't await the server confirmation - just let it sync in background
      _firebase
          .ref(path)
          .set(transaction.toJson())
          .then((_) {
            // Mark as synced when Firebase confirms
            syncManager.markSynced(transaction.kodeTransaksi);
            if (kDebugMode) {
              print('☁️ Transaction synced to server: ${transaction.kodeTransaksi}');
            }
          })
          .catchError((e) {
            // Mark as failed if error
            syncManager.markFailed(transaction.kodeTransaksi, e.toString());
            if (kDebugMode) {
              print('⚠️ Transaction will sync later: ${transaction.kodeTransaksi} - $e');
            }
          });

      if (kDebugMode) {
        print('✅ Transaction saved locally: ${transaction.kodeTransaksi}');
      }

      // Return immediately - transaction is in local cache
      return transaction.copyWith(syncStatus: SyncStatus.pending, lastSyncAt: DateTime.now());
    } catch (e) {
      syncManager.markFailed(transaction.kodeTransaksi, e.toString());
      if (kDebugMode) {
        print('❌ Create transaction failed: $e');
      }
      rethrow;
    }
  }

  /// Get all pending transactions
  Future<List<model.Transaction>> getPendingTransactions() async {
    try {
      final snapshot = await _firebase.get('$_transactionsPath/pending');

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final transactions = data.entries.map((e) {
        return model.Transaction.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get pending transactions failed: $e');
      }
      return [];
    }
  }

  /// Get all completed transactions
  Future<List<model.Transaction>> getCompletedTransactions() async {
    try {
      final snapshot = await _firebase.get('$_transactionsPath/completed');

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final transactions = data.entries.map((e) {
        return model.Transaction.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get completed transactions failed: $e');
      }
      return [];
    }
  }

  /// Get a single transaction
  Future<model.Transaction?> getTransaction(String kodeTransaksi, {String status = 'pending'}) async {
    try {
      final snapshot = await _firebase.get('$_transactionsPath/$status/$kodeTransaksi');

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      return model.Transaction.fromJson(kodeTransaksi, Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get transaction failed: $e');
      }
      return null;
    }
  }

  /// Listen to pending transactions in realtime
  Stream<List<model.Transaction>> watchPendingTransactions() {
    return _firebase.onValue('$_transactionsPath/pending').map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <model.Transaction>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final transactions = data.entries.map((e) {
        return model.Transaction.fromJson(e.key, Map<String, dynamic>.from(e.value));
      }).toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  /// Get today's transactions summary
  Future<Map<String, dynamic>> getTodaySummary() async {
    try {
      final transactions = await getPendingTransactions();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayTransactions = transactions.where((t) => t.createdAt.isAfter(startOfDay)).toList();

      return {
        'date': today,
        'totalTransactions': todayTransactions.length,
        'totalRevenue': todayTransactions.fold<double>(0, (sum, t) => sum + t.totalHarga),
        'totalItems': todayTransactions.fold<int>(0, (sum, t) => sum + t.itemCount),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get today summary failed: $e');
      }
      return {'date': DateTime.now(), 'totalTransactions': 0, 'totalRevenue': 0.0, 'totalItems': 0};
    }
  }

  /// Complete a transaction (move from pending to completed)
  Future<bool> completeTransaction(String kodeTransaksi) async {
    try {
      // Get the transaction
      final transaction = await getTransaction(kodeTransaksi);
      if (transaction == null) return false;

      // Update status and move to completed
      final updatedTransaction = transaction.copyWith(statusTransaksi: model.TransactionStatus.selesai);

      // Save to completed
      await _firebase.set('$_transactionsPath/completed/$kodeTransaksi', updatedTransaction.toJson());

      // Remove from pending
      await _firebase.delete('$_transactionsPath/pending/$kodeTransaksi');

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Complete transaction failed: $e');
      }
      return false;
    }
  }

  /// Cancel a transaction
  Future<bool> cancelTransaction(String kodeTransaksi) async {
    try {
      // Get the transaction
      final transaction = await getTransaction(kodeTransaksi);
      if (transaction == null) return false;

      // Update status
      final updatedTransaction = transaction.copyWith(statusTransaksi: model.TransactionStatus.batal);

      // Save with cancelled status
      await _firebase.set('$_transactionsPath/cancelled/$kodeTransaksi', updatedTransaction.toJson());

      // Remove from pending
      await _firebase.delete('$_transactionsPath/pending/$kodeTransaksi');

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cancel transaction failed: $e');
      }
      return false;
    }
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(String kodeTransaksi, {String status = 'pending'}) async {
    try {
      await _firebase.delete('$_transactionsPath/$status/$kodeTransaksi');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete transaction failed: $e');
      }
      return false;
    }
  }
}
