import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/local_report_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report.dart';

enum SortOrder { newest, oldest }

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return LocalReportRepository();
});

final reportListProvider = FutureProvider<List<Report>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getReports();
});

final filterCategoryProvider = StateProvider<ReportCategory?>((ref) => null);
final filterStatusProvider = StateProvider<ReportStatus?>((ref) => null);

final sortProvider = StateProvider<SortOrder>((ref) => SortOrder.newest);

final filteredReportListProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final reportAsync = ref.watch(reportListProvider);
  final selectedCategory = ref.watch(filterCategoryProvider);
  final selectedStatus = ref.watch(filterStatusProvider);
  final currentSort = ref.watch(sortProvider);
});
