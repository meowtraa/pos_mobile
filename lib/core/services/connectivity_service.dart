import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Connection status enum
enum ConnectionStatus { online, offline }

/// Connectivity Service
/// Monitors network connectivity status using connectivity_plus only
class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  static ConnectivityService? _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Default to OFFLINE until we actually check
  ConnectionStatus _status = ConnectionStatus.offline;
  bool _isInitialized = false;

  ConnectionStatus get status => _status;
  bool get isOnline => _status == ConnectionStatus.online;
  bool get isInitialized => _isInitialized;

  ConnectivityService._();

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  /// Initialize the service - must be called before using
  Future<void> init() async {
    if (_isInitialized) return;

    // Register lifecycle observer to check when app resumes
    WidgetsBinding.instance.addObserver(this);

    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results, notify: true);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results, notify: true);
    });

    _isInitialized = true;

    if (kDebugMode) {
      print('📶 Connectivity service initialized: $_status');
    }
  }

  /// Update status based on connectivity results
  void _updateStatus(List<ConnectivityResult> results, {required bool notify}) {
    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    final newStatus = hasConnection ? ConnectionStatus.online : ConnectionStatus.offline;

    if (_status != newStatus) {
      _status = newStatus;
      if (kDebugMode) {
        print('📶 Connection Status Changed: $_status (results: $results)');
      }
      if (notify) notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('📶 App resumed, re-checking connectivity...');
      }
      _recheckConnectivity();
    }
  }

  /// Re-check connectivity when app resumes
  Future<void> _recheckConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results, notify: true);
  }

  /// Force check connectivity
  Future<void> checkNow() async {
    await _recheckConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}
