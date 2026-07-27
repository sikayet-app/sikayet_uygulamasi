import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/api_constants.dart';
import 'auth_repository.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {'Accept': 'application/json'},
    ),
  );
  Future<void> _saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'device_name': 'flutter_mobile',
        },
      );
      print('RESPONSE: ${response.data}');
      print('RESPONSE TYPE: ${response.data.runtimeType}');

      final token = response.data['token'];
      final userData = response.data['data'];

      final user = User.fromMap(userData);
      await _saveSession(token);

      return AuthResult(user: user, token: token);
    } on DioException catch (e) {
      print('ERROR RESPONSE: ${e.response?.data}');
      print('ERROR TYPE: ${e.response?.data.runtimeType}');
      final message = e.response?.data['message'] ?? 'Kayıt başarısız.';
      throw Exception(message);
    }
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'device_name': 'flutter_mobile',
        },
      );
      final token = response.data['token'];
      final userData = response.data['data'];

      final user = User.fromMap(userData);
      await _saveSession(token);

      return AuthResult(user: user, token: token);
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ??
          'Giriş yapılamadı. Bilgilerinizi kontrol edin';
      throw Exception(message);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return User.fromMap(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _dio.post(
          '/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    // backend de id ile kullanıcı getirme yok
    return null;
  }

  @override
  Future<List<User>> getAllUsers() async {
    //backend de yok
    return [];
  }
}
