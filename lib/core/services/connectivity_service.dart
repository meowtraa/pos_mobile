import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connection status enum
enum ConnectionStatus { online, offline }

/// Connectivity Service
/// Monitors network connectivity status
class ConnectivityService extends ChangeNotifier {
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

    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results, notify: false);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    _isInitialized = true;

    if (kDebugMode) {
      print('📶 Connectivity service initialized: $_status');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateStatus(results, notify: true);
  }

  void _updateStatus(List<ConnectivityResult> results, {required bool notify}) {
    final wasOnline = _status == ConnectionStatus.online;

    // Check if any connection is available from network interface
    final hasNetworkConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    if (hasNetworkConnection) {
      // If network is connected, check for actual internet access
      _checkInternetConnection().then((hasInternet) {
        final newStatus = hasInternet ? ConnectionStatus.online : ConnectionStatus.offline;

        if (_status != newStatus) {
          _status = newStatus;
          if (kDebugMode) {
            print('📶 Internet Check Result: $_status');
          }
          if (notify) notifyListeners();
        }
      });
    } else {
      _status = ConnectionStatus.offline;
      if (notify && wasOnline) notifyListeners();
    }
  }

  /// Check if we have actual internet access by looking up a known domain
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
