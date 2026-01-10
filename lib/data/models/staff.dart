/// Staff Model
/// Represents a staff member (kapster/barber) in the POS system
library;

class Staff {
  final int id;
  final String name;
  final String role;

  const Staff({required this.id, required this.name, required this.role});

  /// Check if staff is a kapster
  bool get isKapster => role == 'kapster';

  /// Create from Firebase JSON
  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(id: json['id'] as int, name: json['name'] as String, role: json['role'] as String);
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role};
  }

  /// Copy with new values
  Staff copyWith({int? id, String? name, String? role}) {
    return Staff(id: id ?? this.id, name: name ?? this.name, role: role ?? this.role);
  }

  @override
  String toString() {
    return 'Staff(id: $id, name: $name, role: $role)';
  }
}
