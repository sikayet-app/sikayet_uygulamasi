import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sikayet_uygulamasi/data/models/report.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'package:sikayet_uygulamasi/screens/user_management_screen.dart';
import 'package:sikayet_uygulamasi/screens/report_assignment_screen.dart';
import '../widgets/app_card.dart'; 
import '../core/report_ui_helpers.dart'; 

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'YÖNETİM PANELİ',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1.2),
            ),
            const Text('Sistem Özeti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
        data: (reports) {
          final total = reports.length;
          final pending = reports.where((r) => r.status == ReportStatus.pending).length;
          final inProgress = reports.where((r) => r.status == ReportStatus.inProgress).length;
          final resolved = reports.where((r) => r.status == ReportStatus.resolved).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. İSTATİSTİK BÖLÜMÜ (4'lü Grid)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard('Toplam Kayıt', total.toString(), Icons.assignment_outlined, Colors.blueGrey, isDarkMode),
                    _buildStatCard('Yeni / Bekleyen', pending.toString(), Icons.inbox_outlined, colorForStatus(ReportStatus.pending, isDarkMode: isDarkMode), isDarkMode, bgColor: getStatusBgColor(ReportStatus.pending, isDarkMode: isDarkMode)),
                    _buildStatCard('Sahada (İşlemde)', inProgress.toString(), Icons.engineering_outlined, colorForStatus(ReportStatus.inProgress, isDarkMode: isDarkMode), isDarkMode, bgColor: getStatusBgColor(ReportStatus.inProgress, isDarkMode: isDarkMode)),
                    _buildStatCard('Çözüldü', resolved.toString(), Icons.check_circle_outline, colorForStatus(ReportStatus.resolved, isDarkMode: isDarkMode), isDarkMode, bgColor: getStatusBgColor(ReportStatus.resolved, isDarkMode: isDarkMode)),
                  ],
                ),
                
                const SizedBox(height: 24),
                _buildSectionOverline('DURUM DAĞILIMI', colorScheme),
                
                // 2. GRAFİK VE LEJANT BÖLÜMÜ
                if (total > 0)
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 4,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      if (resolved > 0) PieChartSectionData(color: colorForStatus(ReportStatus.resolved, isDarkMode: isDarkMode), value: resolved.toDouble(), showTitle: false, radius: 20),
                                      if (inProgress > 0) PieChartSectionData(color: colorForStatus(ReportStatus.inProgress, isDarkMode: isDarkMode), value: inProgress.toDouble(), showTitle: false, radius: 20),
                                      if (pending > 0) PieChartSectionData(color: colorForStatus(ReportStatus.pending, isDarkMode: isDarkMode), value: pending.toDouble(), showTitle: false, radius: 20),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(total.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                    Text('Kayıt', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // LEJANT 
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem('Çözüldü', resolved, total, colorForStatus(ReportStatus.resolved, isDarkMode: isDarkMode), colorScheme),
                              const SizedBox(height: 8),
                              _buildLegendItem('İşlemde', inProgress, total, colorForStatus(ReportStatus.inProgress, isDarkMode: isDarkMode), colorScheme),
                              const SizedBox(height: 8),
                              _buildLegendItem('Bekliyor', pending, total, colorForStatus(ReportStatus.pending, isDarkMode: isDarkMode), colorScheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
                _buildSectionOverline('OPERASYON MERKEZİ', colorScheme),

                // 3. AKSİYON MENÜLERİ 
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Şikayetler ve İş Atama',
                        subtitle: 'Bekleyen şikayetleri personellere yönlendirin',
                        colorScheme: colorScheme,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportAssignmentScreen()));
                        },
                      ),
                      Divider(height: 1, indent: 72, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      _buildActionTile(
                        icon: Icons.people_outline,
                        title: 'Kullanıcı Yönetimi',
                        subtitle: 'Kullanıcıları, personelleri ve yetkileri düzenleyin',
                        colorScheme: colorScheme,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionOverline(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.outline, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, bool isDarkMode, {Color? bgColor}) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor ?? iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8), 
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black87)),
            ],
          ),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color, ColorScheme colorScheme) {
    final percentage = total == 0 ? 0 : ((count / total) * 100).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Text('%$percentage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required String subtitle, required ColorScheme colorScheme, required bool isDarkMode, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E3244) : const Color(0xFFEEF1F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDarkMode ? Colors.white70 : const Color(0xFF1E3244)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}