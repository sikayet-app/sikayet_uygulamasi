import 'package:dio/dio.dart';
import 'package:sikayet_uygulamasi/core/api_constants.dart';
import 'auth_repository.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthRepository implements AuthRepository{
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );
  @override
  Future<AuthResult> login({required String email, required String password}) async {
    
  }
}