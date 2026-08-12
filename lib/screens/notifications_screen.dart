import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sikayet_uygulamasi/providers/notification_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import '../core/app_colors.dart'; // MERKEZİ RENK DOSYAMIZ EKLENDİ
import 'report_detail_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(allNotificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text('Bildirimlerim', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tümü okundu işaretleme API si bekleniyor')),
              );
            },
            child: Text(
              'Tümünü okundu işaretle',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('Henüz bildirim yok', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          // Güvenli Sıralama (API'nin sırasına güvenmiyoruz)
          final sortedList = List<dynamic>.from(notifications);
          sortedList.sort((a, b) => (b.createdAt as DateTime).compareTo(a.createdAt as DateTime));

          // Sıralanmış listeyi grupluyoruz
          final groupedNotifications = _groupByDay(sortedList);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allNotificationsProvider);
              try {
                await ref.read(allNotificationsProvider.future);
              } catch (_) {}
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groupedNotifications.keys.length,
              itemBuilder: (context, index) {
                final groupKey = groupedNotifications.keys.elementAt(index);
                final items = groupedNotifications[groupKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GRUP BAŞLIĞI (Overline)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                      child: Text(
                        groupKey,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.outline,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    
                    // GRUP İÇİNDEKİ BİLDİRİMLER
                    ...items.map((notification) {
                      final isUnread = notification.readAt == null;
                      final title = notification.data['title'] ?? 'Bildirim';
                      final message = notification.data['message'] ?? '';
                      
                      final iconData = _getNotificationIcon(title);
                      final iconColor = _getNotificationColor(title, isDarkMode);
                      final timeString = _getTimeString(notification.createdAt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? colorScheme.surfaceContainerHigh : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isUnread 
                            ? const Border(left: BorderSide(color: AppColors.accent, width: 4)) // SABİT VURGU RENGİ
                            : Border.all(color: colorScheme.outline.withValues(alpha: 0.1), width: 1),
                          boxShadow: isDarkMode ? [] : [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              if (isUnread) {
                                try {
                                  await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
                                  ref.invalidate(allNotificationsProvider);
                                  ref.invalidate(unreadNotificationsProvider);
                                } catch (e) {}
                              }

                              final reportIdStr = notification.data['report_id']?.toString();
                              if (reportIdStr != null && context.mounted) {
                                final reportAsyncValue = ref.read(reportListProvider);
                                reportAsyncValue.whenData((reports) {
                                  try {
                                    final targetReport = reports.firstWhere((r) => r.id == reportIdStr);
                                    if (context.mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ReportDetailScreen(report: targetReport)));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Bu şikayet artık bulunamadı.')),
                                      );
                                    }
                                  }
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // KATEGORİ İKONU (Artık yuvarlatılmış kare)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8), // Düzeltilen kısım
                                    ),
                                    child: Icon(iconData, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.outline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // OKUNMAMIŞ NOKTASI (SABİT VURGU RENGİ)
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6, left: 8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent, 
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
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

  Map<String, List<dynamic>> _groupByDay(List<dynamic> items) {
    final now = DateTime.now();
    final groups = <String, List<dynamic>>{};

    for (final n in items) {
      final d = n.createdAt as DateTime;
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;

      final key = isToday ? 'BUGÜN' : isYesterday ? 'DÜN' : 'DAHA ÖNCE';
      groups.putIfAbsent(key, () => []).add(n);
    }
    return groups;
  }

  IconData _getNotificationIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('çözüldü')) return Icons.check_circle_outline;
    if (t.contains('personel')) return Icons.person_outline;
    if (t.contains('güncellendi') || t.contains('inceleniyor')) return Icons.access_time;
    if (t.contains('sistem') || t.contains('bakım')) return Icons.notifications_none;
    return Icons.info_outline;
  }

  Color _getNotificationColor(String title, bool isDarkMode) {
    final t = title.toLowerCase();
    if (t.contains('çözüldü')) return isDarkMode ? const Color(0xFF34D399) : const Color(0xFF085041);
    if (t.contains('personel')) return isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);
    if (t.contains('güncellendi') || t.contains('inceleniyor')) return isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF854F0B);
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  String _getTimeString(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Az önce'; // İnce cila eklendi
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24 && now.day == date.day) {
      return '${difference.inHours} saat önce';
    } else {
      final isYesterday = now.subtract(const Duration(days: 1)).day == date.day;
      if (isYesterday) {
        return 'Dün, ${DateFormat('HH:mm').format(date)}';
      }
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    }
  }
}