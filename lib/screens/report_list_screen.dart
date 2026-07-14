import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/location_service.dart';
import '../providers/report_provider.dart';
import '../data/models/report.dart';
import '../core/location_service.dart';

class ReportListTestScreen extends ConsumerWidget {
  const ReportListTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler (Test)')),
      body: reportAsync.when(
        data: (reports) => ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              title: Text(report.title),
              subtitle: Text(
                '${getCategoryLabel(report.category)} • ${getStatusLabel(report.status)}',
              ),
              leading: const Icon(Icons.report_problem_outlined),
            );
          },
        ),
        error: (error, StackTrace) =>
            Center(child: Text('Bir hata oluştu: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final locationService = LocationService();
          try {
            final position = await locationService.getCurrentLocation();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Konum: ${position.latitude}, ${position.longitude}',
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
