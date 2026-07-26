import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/screens/login_screen.dart';
import 'package:sikayet_uygulamasi/screens/main_navigation_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authCheckProvider);
    return authState.when(
      data: (user) =>
          user != null ? const MainNavigationScreen() : const LoginScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Hata: $error'))),
    );
  }
}
