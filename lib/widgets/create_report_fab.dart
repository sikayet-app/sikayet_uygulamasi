import 'package:flutter/material.dart';
import 'package:sikayet_uygulamasi/screens/create_report_screen.dart';

class CreateReportFab extends StatelessWidget {
  const CreateReportFab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      heroTag: null,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreateReportScreen()),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text(
        'Talep Oluştur',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
