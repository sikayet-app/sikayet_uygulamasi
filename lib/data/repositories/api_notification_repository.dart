import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_repository.dart';
import '../models/app_notification.dart';
import '../../core/api_constants.dart';

class ApiNotificationRepository implements NotificationRepository {
  late final Dio _dio;
  ApiNotificationRepository() {
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
  @override
  Future<List<AppNotification>> getNotifications() async {
    
    
    final response = await _dio.get('/notifications');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => AppNotification.fromMap(json)).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }
}
