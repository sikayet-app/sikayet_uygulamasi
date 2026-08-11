import 'package:flutter/material.dart';
import 'package:sikayet_uygulamasi/data/models/user.dart';
import 'package:sikayet_uygulamasi/screens/admin_dashboard_screen.dart';
import 'package:sikayet_uygulamasi/screens/user_management_screen.dart';
import 'home_screen.dart';
import 'report_list_screen.dart';
import 'create_report_screen.dart';
import 'profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// sekmeler arası geçiş yapacağımız için state
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canManageUsers =
        user?.role == UserRole.admin || user?.role == UserRole.managing;
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> screens = [
      const HomeScreen(),
      const ReportListScreen(),
      if (canManageUsers) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
     
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.2),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),

          const NavigationDestination(
            icon: Icon(Icons.list_alt),
            selectedIcon: Icon(Icons.view_list),
            label: 'Kayıtlar',
          ),
          if (canManageUsers)
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Yönetim',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
