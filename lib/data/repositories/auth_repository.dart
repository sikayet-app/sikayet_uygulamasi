import '../models/user.dart';

class AuthResult {
  final User user;
  final String token;

  AuthResult({required this.user, required this.token});
}

abstract class AuthRepository {
  Future<AuthResult> login({required String email, required String password});
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(String userId);
  Future<List<User>> getStaffList();
  Future<List<User>> getManagingList();
  Future<void> updateUserRole(String userId, String newRole);
  Future<void> deleteUser(String userId);
  Future<List<User>> getCitizenList();
}
