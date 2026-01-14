import '../../providers/base_view_model.dart';
import '../../../core/services/session_service.dart';
import '../../../data/models/user.dart';

/// Profile View Model
/// Handles business logic for Profile Page
class ProfileViewModel extends BaseViewModel {
  User? _user;

  User? get user => _user;

  ProfileViewModel() {
    _loadUser();
  }

  /// Load user data from SessionService
  void _loadUser() {
    _user = SessionService.instance.currentUser;
    notifyListeners();
  }

  /// Refresh user data
  void refresh() {
    _loadUser();
  }

  /// Update user name (local only - for display purposes)
  void updateName(String name) {
    if (_user != null) {
      _user = User(id: _user!.id, email: _user!.email, name: name, avatarUrl: _user!.avatarUrl, role: _user!.role);
      notifyListeners();
    }
  }

  /// Update user email (local only - for display purposes)
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
      // TODO: Implement actual profile update via Firebase
      await Future.delayed(const Duration(seconds: 1));
      setSuccess();
      return true;
    } catch (e) {
      setError('Gagal menyimpan profil');
      return false;
    }
  }
}
