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

  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOnline => _status == ConnectionStatus.online;

  ConnectivityService._() {
    _init();
  }

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  Future<void> _init() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _status == ConnectionStatus.online;

    // Check if any connection is available
    final hasConnection = results.any((result) => result != ConnectivityResult.none);

    _status = hasConnection ? ConnectionStatus.online : ConnectionStatus.offline;

    if (kDebugMode) {
      print('📶 Connectivity: $_status (results: $results)');
    }

    // Only notify if status actually changed
    if (wasOnline != isOnline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
