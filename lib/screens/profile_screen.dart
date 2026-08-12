import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/theme_service.dart';
import 'package:sikayet_uygulamasi/data/models/report.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/providers/report_provider.dart';
import 'login_screen.dart';
import '../data/models/user.dart';
import '../providers/theme_provider.dart';
import '../core/app_colors.dart';         // YENİ: Renk merkezimiz eklendi
import '../core/report_ui_helpers.dart';  // YENİ: getInitials ve renk fonksiyonları eklendi
import '../widgets/app_card.dart';        // YENİ: Modüler kart eklendi

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final reportAsync = ref.watch(reportListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // eğer user henüz yüklenmediyse boş dön
    if (user == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    int totalReports = 0;
    int stat2 = 0; // çözüldü (vatndaş) veya tamamlanan(personel)
    int stat3 = 0; // bekliyor (vatandaş) veya işlemde(personel)

    reportAsync.whenData((reports) {
      if (user.role == UserRole.citizen) {
        final myReports = reports.where((r) => r.userId == user.id).toList();
        totalReports = myReports.length;
        stat2 = myReports.where((r) => r.status == ReportStatus.resolved).length;
        stat3 = myReports
            .where((r) => r.status == ReportStatus.pending || r.status == ReportStatus.inProgress)
            .length;
      } else if (user.role == UserRole.staff) {
        final assignedReports = reports.where((r) => r.assignedStaffId == user.id).toList();
        totalReports = assignedReports.length;
        stat2 = assignedReports
            .where((r) => r.status == ReportStatus.resolved || r.status == ReportStatus.rejected || r.status == ReportStatus.invalid)
            .length;
        stat3 = assignedReports.where((r) => r.status == ReportStatus.inProgress).length;
      }
    });

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : AppColors.surfaceWarmLight, // DÜZELTİLDİ
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  PROFiL KARTI (HEADER)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 80,
                    bottom: 60,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.navy, // DÜZELTİLDİ
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            getInitials(user.name), // Helper'dan geliyor
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rol Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getRoleLabel(user.role),
                          style: const TextStyle(
                            color: AppColors.accent, // DÜZELTİLDİ
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // istatistik kartları
                if (user.role == UserRole.citizen || user.role == UserRole.staff) ...[
                  Positioned(
                    bottom: -40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCard(
                          user.role == UserRole.staff ? 'Atanan İş' : 'Toplam',
                          totalReports.toString(),
                          isDarkMode ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          user.role == UserRole.staff ? 'Tamamlanan' : 'Çözüldü',
                          stat2.toString(),
                          colorForStatus(ReportStatus.resolved, isDarkMode: isDarkMode), // DÜZELTİLDİ
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          user.role == UserRole.staff ? 'Sahada' : 'Bekliyor',
                          stat3.toString(),
                          colorForStatus(user.role == UserRole.staff ? ReportStatus.inProgress : ReportStatus.pending, isDarkMode: isDarkMode), // DÜZELTİLDİ
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 64), // kartların taşma payı

            // modüler menüler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HESAP BÖLÜMÜ
                  _buildSectionHeader('HESAP', colorScheme),
                  _buildMenuGroup(
                    children: [
                      _buildMenuTile(
                        icon: Icons.person_outline,
                        title: 'Kişisel Bilgiler',
                        showChevron: true,
                        onTap: () {},
                      ),
                      _buildDivider(isDarkMode, colorScheme),
                      _buildMenuTile(
                        icon: Icons.phone_outlined,
                        title: user.phoneNumber != null && user.phoneNumber!.isNotEmpty ? user.phoneNumber! : 'Telefon Ekle',
                        showChevron: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // tercihler bölümü
                  _buildSectionHeader('TERCİHLER', colorScheme),
                  _buildMenuGroup(
                    children: [
                      _buildMenuTile(
                        icon: Icons.notifications_none,
                        title: 'Bildirimler',
                        trailing: Switch(
                          value: true,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.navy, // DÜZELTİLDİ
                          onChanged: (val) {},
                        ),
                      ),
                      _buildDivider(isDarkMode, colorScheme),
                      _buildMenuTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Karanlık Mod',
                        trailing: Switch(
                          value: currentTheme == ThemeMode.dark,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.navy, // DÜZELTİLDİ
                          onChanged: (isDark) {
                            final newTheme = isDark ? ThemeMode.dark : ThemeMode.light;
                            ref.read(themeModeProvider.notifier).state = newTheme;
                            ThemeService().saveThemeMode(newTheme);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // diğer bölümü
                  _buildSectionHeader('DİĞER', colorScheme),
                  _buildMenuGroup(
                    children: [
                      _buildMenuTile(
                        icon: Icons.help_outline,
                        title: 'Yardım ve Destek',
                        showChevron: true,
                        onTap: () => _showHelpSupportSheet(context, colorScheme, isDarkMode),
                      ),
                      _buildDivider(isDarkMode, colorScheme),
                      _buildMenuTile(
                        icon: Icons.logout,
                        title: 'Çıkış Yap',
                        titleColor: Colors.red.shade700,
                        iconColor: Colors.red.shade700,
                        onTap: () => _showLogoutDialog(context, ref, colorScheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // yardımcı metotlar

  // üçlü istatistik kartı (AppCard'a geçirildi)
  Widget _buildStatCard(String title, String value, Color valueColor) {
    return SizedBox(
      width: 100,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // bölüm başlığı
  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // beyaz modüler kutu (AppCard'a geçirildi)
  Widget _buildMenuGroup({required List<Widget> children}) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  // menü elemanı
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Color? iconColor,
    bool showChevron = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: iconColor ?? AppColors.navy), // DÜZELTİLDİ
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      trailing: trailing ?? (showChevron ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20) : null),
      onTap: onTap,
    );
  }

  // menü arası çizgi
  Widget _buildDivider(bool isDarkMode, ColorScheme colorScheme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 20,
      color: isDarkMode ? colorScheme.outlineVariant : Colors.grey.shade100,
    );
  }

  // çıkış yap diyaloğu
  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Çıkış Yap'),
            ],
          ),
          content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Çıkış'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    await ref.read(authRepositoryProvider).logout();
    ref.read(currentUserProvider.notifier).state = null;

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // yardım ve destek
  void _showHelpSupportSheet(BuildContext context, ColorScheme colorScheme, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: isDarkMode ? colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kaydırma Çubuğu (Drag Handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Yardım ve Destek',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sistemle ilgili yaşadığınız teknik sorunlar veya talepleriniz için aşağıdaki iletişim kanallarını kullanabilirsiniz.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildMenuTile(
                icon: Icons.email_outlined,
                title: 'destek@belediye.gov.tr',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildDivider(isDarkMode, colorScheme),
              _buildMenuTile(
                icon: Icons.phone_in_talk_outlined,
                title: 'Alo 153 Çözüm Merkezi',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(context, ref, user) {}
}