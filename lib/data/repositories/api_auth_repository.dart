import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/api_constants.dart';
import 'auth_repository.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthRepository implements AuthRepository {
  late final Dio _dio;
  ApiAuthRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('authToken');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
  Future<void> _saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'phone_number': phoneNumber,
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
      final response = await _dio.get('/me');
      return User.fromMap(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      final userData = response.data['data'] ?? response.data;
      return User.fromMap(userData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<User>> getAllUsers({String? role}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      final response = await _dio.get('/users', queryParameters: queryParams);

      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => User.fromMap(json)).toList();
    } on DioException catch (e) {
      throw Exception('Kullanıcılar getirilemedi: ${e.message}');
    }
  }

  @override
  Future<List<User>> getStaffList() async {
    final response = await _dio.get(
      '/users',
      queryParameters: {'role': 'staff'},
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => User.fromMap(json)).toList();
  }

  @override
  Future<List<User>> getManagingList() async {
    final response = await _dio.get(
      '/users',
      queryParameters: {'role': 'managing'},
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => User.fromMap(json)).toList();
  }

  @override
  Future<List<User>> getCitizenList() async {
    final response = await _dio.get(
      '/users',
      queryParameters: {'role': 'citizen'},
    );
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => User.fromMap(json)).toList();
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _dio.delete('users/$userId');
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _dio.patch('/users/$userId/role', data: {'role': newRole});
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? 'Kullancı rolü güncellenemdi.';
      throw Exception(message);
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }
}
