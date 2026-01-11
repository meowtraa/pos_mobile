import 'dart:async';
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

    // Check if any connection is available
    final hasConnection = results.any((result) => result != ConnectivityResult.none);

    _status = hasConnection ? ConnectionStatus.online : ConnectionStatus.offline;

    if (kDebugMode) {
      print('📶 Connectivity: $_status (results: $results)');
    }

    // Only notify if status actually changed
    if (notify && wasOnline != isOnline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
