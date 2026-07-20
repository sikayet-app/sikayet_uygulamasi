import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import '../data/models/report.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends ConsumerWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Şikayet Listesi')),
      body: reportAsync.when(
        data: (reports) => ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              title: Text(report.title),
              subtitle: Text(
                '${getCategoryLabel(report.category)} & ${getStatusLabel(report.status)}',
              ),
              leading: const Icon(Icons.report_problem_outlined),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(report: report),
                  ),
                );
              },
            );
          },
        ),
        error: (error, StackTrace) =>
            Center(child: Text('Bir hata oluştu: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
