import 'package:sikayet_uygulamasi/core/password_hasher.dart';
import 'auth_repository.dart';
import '../models/user.dart';
import '../local/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthRepository implements AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final existingUser = await _dbHelper.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Bu email zaten kayıtlı');
    }
    final passwordHash = hashPassword(password);

    final user = User(
      id: const Uuid().v4(),
      name: name,
      email: email,
      role: UserRole.citizen,
    );

    await _dbHelper.insertUser(user, passwordHash);
    final token = const Uuid().v4();
    await _saveSession(user.id, token);
    return AuthResult(user: user, token: token);
  }

  Future<void> _saveSession(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', userId);
    await prefs.setString('authToken', token);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final foundUser = await _dbHelper.getUserByEmail(email);
    if (foundUser == null) {
      throw Exception('Kullanıcı bulunamadı');
    }
    final passwordHash = hashPassword(password);
    if (foundUser['passwordHash'] != passwordHash) {
      throw Exception('Şifre Yanlış');
    }
    final user = User.fromMap(foundUser);
    final token = const Uuid().v4();
    await _saveSession(user.id, token);
    return AuthResult(user: user, token: token);
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('currentUserId');

    if (userId == null) {
      return null;
    }
    final userMap = await _dbHelper.getUserById(userId);
    if (userMap == null) {
      return null;
    }
    return User.fromMap(userMap);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    await prefs.remove('authToken');
  }

  Future<void> ensureAdminExists() async {
    final bool hasAdmin = await _dbHelper.hasAdminUser();
    if (hasAdmin) return;
    final passwordHash = hashPassword('admin12345');
    final user = User(
      id: const Uuid().v4(),
      name: 'Admin',
      email: 'admin@belediye.gov.tr',
      role: UserRole.admin,
    );
    await _dbHelper.insertUser(user, passwordHash);
  }

  @override
  Future<List<User>> getAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT * FROM users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  @override
  Future<User?> getUserById(String userId) async {
    final userMap = await _dbHelper.getUserById(userId);
    if (userMap == null) return null;
    return User.fromMap(userMap);
  }

  @override
  Future<List<User>> getStaffList() async {
    final allUsers = await getAllUsers();
    return allUsers.where((user) => user.role == UserRole.staff).toList();
  }

  @override
  Future<void> deleteUser(String userId) async {
    throw UnimplementedError('Bu metot lokalde desteklenmiyor');
  }

  @override
  Future<List<User>> getManagingList() async {
    throw UnimplementedError('Bu metot lokalde desteklenmiyor');
  }

  @override
  Future<List<User>> getCitizenList() async {
    throw UnimplementedError('Bu metot lokalde desteklenmiyor');
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    throw UnimplementedError('Bu metot lokalde desteklenmiyor');
  }
}
