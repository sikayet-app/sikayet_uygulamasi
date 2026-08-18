import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import 'package:sikayet_uygulamasi/screens/create_report_screen.dart';

class CreateReportFab extends ConsumerWidget {
  const CreateReportFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canCreateReport = user?.permissions.contains('add_report') ?? false;
    if (!canCreateReport) {
      return const SizedBox.shrink();
    }
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
