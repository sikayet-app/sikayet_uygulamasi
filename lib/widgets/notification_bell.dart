import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    return unreadAsync.when(
      data: (unreadList) {
        final unreadCount = unreadList.length;

        return IconButton(
          onPressed: () {
            // zile tıkladığında bildirimler listesi açılacak.
          },
          icon: Badge(
            // eğer okunmamış bildirim yoksa kırmızı balonu gizle
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
      error: (error, stack) => const IconButton(
        onPressed: null,
        icon: Icon(Icons.notifications_off_outlined),
      ),
      loading: () => const IconButton(
        onPressed: null,
        icon: Icon(Icons.notifications_outlined),
      ),
    );
  }
}
