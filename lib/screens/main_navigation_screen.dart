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
    final List<Widget> screens = [
      const HomeScreen(),
      const ReportListScreen(),
      const AdminDashboardScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_add_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateReportScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.map_outlined),
              // eğer seçiliyse mavi, değilse gri yap
              color: _currentIndex == 0 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.list_alt),
              color: _currentIndex == 1 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            const SizedBox(width: 40),

            if (canManageUsers)
              IconButton(
                icon: const Icon(Icons.dashboard),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                color: _currentIndex == 2 ? Colors.blue : Colors.grey,
              ),

            IconButton(
              icon: const Icon(Icons.person_outline),
              color: _currentIndex == screens.length - 1
                  ? Colors.blue
                  : Colors.grey,
              onPressed: () {
                setState(() {
                  _currentIndex = screens.length - 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
