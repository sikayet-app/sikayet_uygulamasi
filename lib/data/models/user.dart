enum UserRole { admin, managing, staff, citizen }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.citizen,
      ),
      phoneNumber: map['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone_number': phoneNumber,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

String getRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Sistem Yöneticisi';
    case UserRole.citizen:
      return 'Vatandaş';
    case UserRole.managing:
      return 'Sorumlu';
    case UserRole.staff:
      return 'Personel';
  }
}
