import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/data/repositories/api_notification_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/models/app_notification.dart';
import 'auth_provider.dart';
import '../data/repositories/api_notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository();
});

final unreadNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return [];
      }
      final repository = ref.watch(notificationRepositoryProvider);
      return await repository.getNotifications(isRead: false);
    });

final allNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return [];
      }
      final repository = ref.watch(notificationRepositoryProvider);

      // iki farklı ağ isteğini (okunmuş ve okunmamış) paralel olarak başlat
      final results = await Future.wait([
        repository.getNotifications(isRead: false),
        repository.getNotifications(isRead: true),
      ]);
      // dönen iki ayrı listeyi tek bir listede birleştir
      final allNotifications = [...results[0], ...results[1]];

      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allNotifications;
    });
