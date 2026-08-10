import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsProvider);

    return IconButton(
      onPressed: () {
        // zile tıkladığında bildirimler listesi açılacak.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
      icon: unreadAsync.when(
        data: (unreadList) {
          final unreadCount = unreadList.length;
          return Badge(
            // eğer okunmamış bildirim yoksa kırmızı balonu gizle
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications_outlined),
          );
        },
        error: (error, stack) => const Icon(Icons.notifications_outlined),

        loading: () => const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
