/// User Model
/// Represents an authenticated user
class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String role;

  const User({required this.id, required this.email, required this.name, this.avatarUrl, this.role = 'staff'});

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Create user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'staff',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'avatar_url': avatarUrl, 'role': role};
  }
}
