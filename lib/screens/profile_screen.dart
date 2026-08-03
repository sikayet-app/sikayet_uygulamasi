import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/theme_service.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'login_screen.dart';
import '../data/models/user.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentTheme = ref.watch(themeModeProvider);
    //eğer user henüz yüklenmediyse boş dön
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),

            Text(
              user.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.role == UserRole.admin
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                getRoleLabel(user.role),
                style: TextStyle(
                  color: user.role == UserRole.admin
                      ? Colors.red[800]
                      : Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Uygulama Ayarları',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Açık'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Koyu'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistem'),
                    icon: Icon(Icons.settings_suggest),
                  ),
                ],
                selected: {currentTheme},
                onSelectionChanged: (Set<ThemeMode> newSelection) async {
                  ref.read(themeModeProvider.notifier).state =
                      newSelection.first;
                  ThemeService().saveThemeMode(newSelection.first);
                },
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(
                  double.infinity,
                  50,
                ), // butonu yatayda tam genişliğe yay
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                // çıkış yapmadan önce kullanıcıdan onay iste
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Çıkış Yap'),
                      content: const Text(
                        'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            false,
                          ), // iptal seçeneği
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            true,
                          ), //onay seçeneği
                          child: const Text(
                            'Çıkış',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
                // kullanıcı iptal ettiyse veya dışarı tıkladıysa işlemi durdur
                if (confirm != true) return;

                if (!context.mounted) return;

                // db ve sharedPreferences dan oturumu sil
                await ref.read(authRepositoryProvider).logout();
                //riverpod state ini temizle
                ref.read(currentUserProvider.notifier).state = null;
                //login ekranına dön ve arkada kalan tüm sayfaları sil
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
