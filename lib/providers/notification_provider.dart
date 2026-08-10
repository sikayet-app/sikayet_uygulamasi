import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/data/repositories/api_notification_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/models/app_notification.dart';
import 'auth_provider.dart';
import '../data/repositories/api_notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository();
});

final allNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return [];
      }
      final repository = ref.watch(notificationRepositoryProvider);

      final notifications = await repository.getNotifications();
      // dönen iki ayrı listeyi tek bir listede birleştir

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
final unreadNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final allNotifications = await ref.watch(allNotificationsProvider.future);
      return allNotifications.where((n) => n.readAt == null).toList();
    });
