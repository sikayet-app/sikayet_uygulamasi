import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/data/models/report.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import '../widgets/app_card.dart';
import '../core/report_ui_helpers.dart';

class ReportAssignmentScreen extends ConsumerWidget {
  const ReportAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Text('Şikayetler ve İş Atama'),
        centerTitle: true,
        elevation: 0,
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (reports) {
          final assignableReports = reports
              .where((r) => r.status == ReportStatus.pending || r.status == ReportStatus.inProgress)
              .toList();

          if (assignableReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('Atanacak yeni şikayet bulunmuyor.', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: assignableReports.length,
            itemBuilder: (context, index) {
              final report = assignableReports[index];
              
              final statusColor = colorForStatus(report.status, isDarkMode: isDarkMode);
              final statusBgColor = getStatusBgColor(report.status, isDarkMode: isDarkMode);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: AppCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              report.status == ReportStatus.pending ? 'Bekliyor' : 'İşlemde',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            getFormattedDate(report.createdAt), 
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(getCategoryIcon(report.category), size: 18, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              report.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: colorScheme.outline),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.fullAddress ?? 'Adres belirtilmemiş',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SORUMLU PERSONEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                report.assignedStaffName ?? 'Henüz atanmadı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: report.assignedStaffName == null 
                                      ? colorForStatus(ReportStatus.rejected, isDarkMode: isDarkMode) 
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary, 
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(report.status == ReportStatus.pending ? Icons.person_add_alt_1 : Icons.edit, size: 18),
                            label: Text(report.status == ReportStatus.pending ? 'Personel Ata' : 'Güncelle'),
                            onPressed: () {
                              _showStaffSelectionSheet(context, ref, report, colorScheme, isDarkMode);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Eksik olan metodu buraya ekledik
  void _showStaffSelectionSheet(BuildContext context, WidgetRef ref, Report report, ColorScheme colorScheme, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final staffAsync = ref.watch(staffListProvider); 
          
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  report.assignedStaffId == null ? 'Personel Ata' : 'Personeli Güncelle', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: staffAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Hata: $err')),
                  data: (staffList) {
                    if (staffList.isEmpty) {
                      return const Center(child: Text('Sistemde kayıtlı personel bulunamadı.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: staffList.length,
                      itemBuilder: (context, index) {
                        final staff = staffList[index];
                        final isCurrentlyAssigned = report.assignedStaffId == staff.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentlyAssigned ? colorScheme.primary : colorScheme.primaryContainer,
                            child: Text(
                              getInitials(staff.name), 
                              style: TextStyle(
                                color: isCurrentlyAssigned ? colorScheme.onPrimary : colorScheme.onPrimaryContainer, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          title: Text(
                            staff.name, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentlyAssigned ? colorScheme.primary : null,
                            ),
                          ),
                          subtitle: Text(staff.email),
                          trailing: isCurrentlyAssigned 
                              ? Icon(Icons.check_circle, color: colorScheme.primary)
                              : const Icon(Icons.chevron_right),
                          onTap: isCurrentlyAssigned ? null : () async {
                            try {
                              if (report.assignedStaffId == null) {
                                await ref.read(reportRepositoryProvider).assignReport(report.id, staff.id);
                              } else {
                                await ref.read(reportRepositoryProvider).updateAssignedStaff(report.id, staff.id);
                              }

                              ref.invalidate(reportListProvider);
                              
                              if (context.mounted) {
                                Navigator.pop(context); 
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${staff.name} başarıyla atandı.'),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Atama yapılamadı: $e'),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}