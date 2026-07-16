import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'report_list_screen.dart';
import 'create_report_screen.dart';

// sekmeler arası geçiş yapacağımız için state
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // geçiş yapacağımız ekranların listesi
  final List<Widget> _screens = [
    const HomeScreen(),
    const ReportListScreen(),
    const Center(child: Text('İstatistik eklenecek')),
    const Center(child: Text('Profil eklenecek')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
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

            IconButton(
              icon: const Icon(Icons.pie_chart_outline),
              color: _currentIndex == 2 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.person_outline),
              color: _currentIndex == 3 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
