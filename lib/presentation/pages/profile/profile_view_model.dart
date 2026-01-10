import '../../providers/base_view_model.dart';
import '../../../data/models/user.dart';

/// Profile View Model
/// Handles business logic for Profile Page
class ProfileViewModel extends BaseViewModel {
  User? _user;

  User? get user => _user;

  ProfileViewModel() {
    _loadUser();
  }

  /// Load user data (demo)
  void _loadUser() {
    _user = const User(id: '1', email: 'admin@machos.com', name: 'Admin', role: 'admin');
    notifyListeners();
  }

  /// Update user name
  void updateName(String name) {
    if (_user != null) {
      _user = User(id: _user!.id, email: _user!.email, name: name, avatarUrl: _user!.avatarUrl, role: _user!.role);
      notifyListeners();
    }
  }

  /// Update user email
  void updateEmail(String email) {
    if (_user != null) {
      _user = User(id: _user!.id, email: email, name: _user!.name, avatarUrl: _user!.avatarUrl, role: _user!.role);
      notifyListeners();
    }
  }

  /// Save profile changes
  Future<bool> saveProfile() async {
    setLoading();
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      setSuccess();
      return true;
    } catch (e) {
      setError('Gagal menyimpan profil');
      return false;
    }
  }
}
