import '../../providers/base_view_model.dart';

/// Home View Model
/// Handles business logic for Home Page
class HomeViewModel extends BaseViewModel {
  int _counter = 0;

  /// Get current counter value
  int get counter => _counter;

  /// Increment counter
  void incrementCounter() {
    _counter++;
    notifyListeners();
  }

  /// Reset counter
  void resetCounter() {
    _counter = 0;
    notifyListeners();
  }

  /// Example async operation
  Future<void> fetchData() async {
    setLoading();
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      // Process data here
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }
}
