import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Connection status enum
enum ConnectionStatus { online, offline }

/// Connectivity Service
/// Monitors network connectivity using:
/// - connectivity_plus: Detects Wifi/Data ON/OFF (fast trigger)
/// - internet_connection_checker_plus: Verifies actual internet access (accurate)
class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  static ConnectivityService? _instance;

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  // Status
  ConnectionStatus _status = ConnectionStatus.offline;
  bool _hasNetworkInterface = false;
  bool _hasInternetAccess = false;
  bool _isInitialized = false;

  ConnectionStatus get status => _status;
  bool get isOnline => _status == ConnectionStatus.online;
  bool get isInitialized => _isInitialized;
  bool get hasNetworkInterface => _hasNetworkInterface;

  ConnectivityService._();

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  /// Initialize the service - must be called before using
  Future<void> init() async {
    if (_isInitialized) return;

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // 1. Check initial network interface status
    final results = await _connectivity.checkConnectivity();
    _updateNetworkInterface(results);

    // 2. Check initial internet access
    _hasInternetAccess = await _internetChecker.hasInternetAccess;
    _updateFinalStatus();

    // 3. Listen to network interface changes (Wifi/Data ON/OFF)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateNetworkInterface(results);
      // When network interface changes, also recheck internet
      _recheckInternetAccess();
    });

    // 4. Listen to internet status changes
    _internetSubscription = _internetChecker.onStatusChange.listen((internetStatus) {
      _hasInternetAccess = internetStatus == InternetStatus.connected;
      _updateFinalStatus();

      if (kDebugMode) {
        print('📶 Internet status changed: $internetStatus');
      }
    });

    _isInitialized = true;

    if (kDebugMode) {
      print('📶 Connectivity service initialized');
      print('   - Network interface: $_hasNetworkInterface');
      print('   - Internet access: $_hasInternetAccess');
      print('   - Final status: $_status');
    }
  }

  /// Update network interface status (Wifi/Data ON/OFF)
  void _updateNetworkInterface(List<ConnectivityResult> results) {
    _hasNetworkInterface = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    if (kDebugMode) {
      print('📶 Network interface: $_hasNetworkInterface (results: $results)');
    }

    // If no network interface, definitely offline
    if (!_hasNetworkInterface) {
      _hasInternetAccess = false;
      _updateFinalStatus();
    }
  }

  /// Recheck internet access
  Future<void> _recheckInternetAccess() async {
    if (!_hasNetworkInterface) {
      _hasInternetAccess = false;
      _updateFinalStatus();
      return;
    }

    _hasInternetAccess = await _internetChecker.hasInternetAccess;
    _updateFinalStatus();

    if (kDebugMode) {
      print('📶 Internet recheck: $_hasInternetAccess');
    }
  }

  /// Update final status based on both checks
  void _updateFinalStatus() {
    final newStatus = (_hasNetworkInterface && _hasInternetAccess) ? ConnectionStatus.online : ConnectionStatus.offline;

    if (_status != newStatus) {
      _status = newStatus;

      if (kDebugMode) {
        print('📶 Connection Status Changed: $_status');
        print('   - Network: $_hasNetworkInterface, Internet: $_hasInternetAccess');
      }

      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('📶 App resumed, re-checking connectivity...');
      }
      _recheckAll();
    }
  }

  /// Re-check everything when app resumes
  Future<void> _recheckAll() async {
    // Recheck network interface
    final results = await _connectivity.checkConnectivity();
    _updateNetworkInterface(results);

    // Recheck internet access
    await _recheckInternetAccess();
  }

  /// Force check connectivity now
  Future<void> checkNow() async {
    await _recheckAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
