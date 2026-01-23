/// Customer Repository
/// Handles customer data operations with Firebase Realtime Database
library;

import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_service.dart';
import '../models/customer.dart';

class CustomerRepository {
  static final CustomerRepository instance = CustomerRepository._();
  final FirebaseService _firebase = FirebaseService.instance;

  CustomerRepository._();

  /// Get the customers path
  String get _customersPath => 'customers';

  /// Find customer by WhatsApp number
  Future<Customer?> findByPhone(String phone) async {
    try {
      final cleanPhone = phone.trim();
      if (cleanPhone.isEmpty) return null;

      final snapshot = await _firebase.get(_customersPath);

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      // Firebase structure: customers/{id}/{data}
      final data = snapshot.value;

      if (data is Map) {
        // Map format
        for (final entry in data.entries) {
          final customerData = Map<String, dynamic>.from(entry.value as Map);
          final noWa = customerData['no_wa'] as String?;
          if (noWa == cleanPhone) {
            final id = int.tryParse(entry.key.toString()) ?? 0;
            return Customer.fromJson(id, customerData);
          }
        }
      } else if (data is List) {
        // Array format (indexed by ID)
        for (var i = 0; i < data.length; i++) {
          if (data[i] != null) {
            final customerData = Map<String, dynamic>.from(data[i] as Map);
            final noWa = customerData['no_wa'] as String?;
            if (noWa == cleanPhone) {
              return Customer.fromJson(i, customerData);
            }
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Find customer by phone failed: $e');
      }
      return null;
    }
  }

  /// Get next available ID for new customer
  Future<int> _getNextId() async {
    try {
      final snapshot = await _firebase.get(_customersPath);

      if (!snapshot.exists || snapshot.value == null) {
        return 1;
      }

      final data = snapshot.value;
      int maxId = 0;

      if (data is Map) {
        for (final key in data.keys) {
          final id = int.tryParse(key.toString()) ?? 0;
          if (id > maxId) maxId = id;
        }
      } else if (data is List) {
        maxId = data.length - 1;
      }

      return maxId + 1;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Add new customer to Firebase
  Future<Customer?> addCustomer(Customer customer) async {
    try {
      final nextId = await _getNextId();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Unix timestamp in seconds

      final newCustomer = customer.copyWith(id: nextId, createdAt: now, updatedAt: now);

      await _firebase.set('$_customersPath/$nextId', newCustomer.toJson());

      if (kDebugMode) {
        print('✅ Customer added: ${newCustomer.nama} (ID: $nextId)');
      }

      return newCustomer;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Add customer failed: $e');
      }
      return null;
    }
  }

  /// Increment transaction count for customer
  Future<bool> incrementTransactionCount(String phone) async {
    try {
      final customer = await findByPhone(phone);
      if (customer == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final newCount = customer.totalKunjungan + 1;

      await _firebase.update('$_customersPath/${customer.id}', {'total_kunjungan': newCount, 'updated_at': now});

      if (kDebugMode) {
        print('✅ Customer visit incremented: ${customer.nama} (count: $newCount)');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Increment transaction count failed: $e');
      }
      return false;
    }
  }

  /// Get all customers
  Future<List<Customer>> getCustomers() async {
    try {
      final snapshot = await _firebase.get(_customersPath);

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final customers = <Customer>[];
      final data = snapshot.value;

      if (data is Map) {
        for (final entry in data.entries) {
          final id = int.tryParse(entry.key.toString()) ?? 0;
          final customerData = Map<String, dynamic>.from(entry.value as Map);
          customers.add(Customer.fromJson(id, customerData));
        }
      } else if (data is List) {
        for (var i = 0; i < data.length; i++) {
          if (data[i] != null) {
            final customerData = Map<String, dynamic>.from(data[i] as Map);
            customers.add(Customer.fromJson(i, customerData));
          }
        }
      }

      return customers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get customers failed: $e');
      }
      return [];
    }
  }
}
