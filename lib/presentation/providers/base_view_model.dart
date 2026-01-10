import 'package:flutter/foundation.dart';

/// View State Enum
enum ViewState { idle, loading, success, error }

/// Base View Model
/// Abstract base class for all ViewModels using Provider
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  /// Current state of the view
  ViewState get state => _state;

  /// Error message if any
  String? get errorMessage => _errorMessage;

  /// Check if currently loading
  bool get isLoading => _state == ViewState.loading;

  /// Check if idle
  bool get isIdle => _state == ViewState.idle;

  /// Check if success
  bool get isSuccess => _state == ViewState.success;

  /// Check if error
  bool get isError => _state == ViewState.error;

  /// Set state to loading
  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set state to success
  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set state to error
  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Set state to idle
  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state
  void resetState() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
