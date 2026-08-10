import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/providers/notification_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import '../core/report_ui_helpers.dart';
import 'report_detail_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(allNotificationsProvider);
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.black.withValues(alpha: 0.3),
        centerTitle: true,
        title: const Text('Bildirimlerim'),
      ),
      body: notificationAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('Henüz bildirim yok'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allNotificationsProvider);
              try {
                await ref.read(allNotificationsProvider.future);
              } catch (_) {}
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = notification.readAt == null;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  // okunmamışsa arka planı hafif renklendir
                  color: isUnread
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (isUnread) {
                        try {
                          await ref
                              .read(notificationRepositoryProvider)
                              .markAsRead(notification.id);
                          // işlem başarılıysa listeleri güncelle, ui değişsin
                          ref.invalidate(allNotificationsProvider);
                          ref.invalidate(unreadNotificationsProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bildirim güncellenemedi.'),
                              ),
                            );
                          }
                        }
                      }
                      // backend den gelen json içindeki sikayet id sini al
                      final reportIdStr = notification.data['report_id']
                          ?.toString();
                      if (reportIdStr != null && context.mounted) {
                        // o anki tüm şikayetler listesini al
                        final reportAsyncValue = ref.read(reportListProvider);
                        reportAsyncValue.whenData((reports) {
                          try {
                            final targetReport = reports.firstWhere(
                              (r) => r.id == reportIdStr,
                            );
                            // şikayet bulunduysa detay sayfasına
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReportDetailScreen(report: targetReport),
                                ),
                              );
                            }
                          } catch (e) {
                            // eğer firstWhere şikayeti bulamazsa(şikayet silinmişse falan)
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bu şikayet artık bulunamadı ve silinmiş',
                                  ),
                                ),
                              );
                            }
                          }
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.data['title'] ?? 'Bildirim',
                            style: TextStyle(
                              fontSize: 16,
                              // okunmamışsa metni kalın yap
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.data['message'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getFormattedDate(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },

        error: (error, stack) => Center(child: Text('Bir hata oluştu: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
