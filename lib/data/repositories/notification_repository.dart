import '../models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications({bool isRead = false});
  Future<void> markAsRead(String id);
}
