import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/app_colors.dart';
import '../core/report_ui_helpers.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? colorScheme.surface
            : AppColors.surfaceWarmLight,
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode
          ? colorScheme.surface
          : AppColors.surfaceWarmLight,
      appBar: AppBar(
        title: const Text('Kişisel Bilgiler'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Büyük Avatar ve İsim
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  getInitials(user.name),
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 40),

            // Bilgi Kartları
            _buildProfileCard(
              label: 'AD SOYAD',
              value: user.name,
              icon: Icons.person_outline,
              colorScheme: colorScheme,
              isDarkMode: isDarkMode,
            ),
            _buildProfileCard(
              label: 'E-POSTA',
              value: user.email,
              icon: Icons.email_outlined,
              colorScheme: colorScheme,
              isDarkMode: isDarkMode,
            ),
            _buildProfileCard(
              label: 'TELEFON NUMARASI',
              value: (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  ? user.phoneNumber!
                  : 'Belirtilmemiş',
              icon: Icons.phone_outlined,
              colorScheme: colorScheme,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Tasarıma Uygun Kart Şablonu
  Widget _buildProfileCard({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? colorScheme.outline.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Sol Taraftaki İkon Kutusu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? colorScheme.surfaceContainerHigh
                  : const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),

          // Sağ Taraftaki Metinler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.outline,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
