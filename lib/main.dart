import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/screens/home_screen.dart';
import 'package:sikayet_uygulamasi/screens/main_navigation_screen.dart';
import 'screens/report_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_gate.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'core/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await ThemeService().loadThemeMode();
  runApp(
    ProviderScope(
      child: MyApp(),
      overrides: [themeModeProvider.overrideWith((ref) => savedTheme)],
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Vatandaş Bildirim',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: currentThemeMode,
      home: const AuthGate(),
    );
  }
}
