import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_report_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return LocalReportRepository();
});

final reportListProvider = FutureProvider<List<Report>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getReports();
});
