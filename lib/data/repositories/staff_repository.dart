/// Staff Repository
/// Handles staff data operations with Firebase Realtime Database
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_service.dart';
import '../models/staff.dart';

class StaffRepository {
  static StaffRepository? _instance;
  final FirebaseService _firebase = FirebaseService.instance;

  StaffRepository._();

  static StaffRepository get instance {
    _instance ??= StaffRepository._();
    return _instance!;
  }

  /// Get the staffs path (master_staffs is an array in Firebase)
  String get _staffsPath => 'master_staffs';

  /// Get all staffs
  Future<List<Staff>> getStaffs() async {
    try {
      final snapshot = await _firebase.get(_staffsPath);

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final staffs = <Staff>[];
      final rawData = snapshot.value;

      // Handle both List and Map formats
      if (rawData is List) {
        // Firebase array: [null, {staff1}, {staff2}, ...]
        for (var i = 0; i < rawData.length; i++) {
          if (rawData[i] != null) {
            staffs.add(Staff.fromJson(Map<String, dynamic>.from(rawData[i])));
          }
        }
      } else if (rawData is Map) {
        // Firebase object: {1: {staff1}, 2: {staff2}, ...}
        rawData.forEach((key, value) {
          if (value != null) {
            staffs.add(Staff.fromJson(Map<String, dynamic>.from(value)));
          }
        });
      }

      if (kDebugMode) {
        print('✅ Loaded ${staffs.length} staffs');
      }

      return staffs;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get staffs failed: $e');
      }
      return [];
    }
  }

  /// Get kapsters only
  Future<List<Staff>> getKapsters() async {
    final staffs = await getStaffs();
    return staffs.where((s) => s.isKapster).toList();
  }

  /// Get a single staff by ID
  Future<Staff?> getStaff(int id) async {
    try {
      final snapshot = await _firebase.get('$_staffsPath/$id');

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      return Staff.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get staff failed: $e');
      }
      return null;
    }
  }

  /// Listen to staffs in realtime
  Stream<List<Staff>> watchStaffs() {
    return _firebase.onValue(_staffsPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Staff>[];
      }

      final staffs = <Staff>[];
      final rawData = event.snapshot.value;

      // Handle both List and Map formats
      if (rawData is List) {
        for (var i = 0; i < rawData.length; i++) {
          if (rawData[i] != null) {
            staffs.add(Staff.fromJson(Map<String, dynamic>.from(rawData[i])));
          }
        }
      } else if (rawData is Map) {
        rawData.forEach((key, value) {
          if (value != null) {
            staffs.add(Staff.fromJson(Map<String, dynamic>.from(value)));
          }
        });
      }

      return staffs;
    });
  }

  /// Listen to kapsters in realtime
  Stream<List<Staff>> watchKapsters() {
    return watchStaffs().map((staffs) => staffs.where((s) => s.isKapster).toList());
  }
}
