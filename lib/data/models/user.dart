enum UserRole { admin, managing, staff, citizen }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    required this.permissions,
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
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone_number': phoneNumber,
      'permissions': permissions,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      permissions: permissions ?? this.permissions,
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
