enum UserRole { admin, managing, staff, citizen }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'role': role.name};
  }

  User copyWith({String? id, String? name, String? email, UserRole? role}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
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
