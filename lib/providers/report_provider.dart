import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikayet_uygulamasi/core/permission.dart';
import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import '../data/repositories/local_report_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report.dart';
import '../data/repositories/api_report_repository.dart';

enum SortOrder { newest, oldest }

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ApiReportRepository();
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
  return reportAsync.whenData((reports) {
    var filtered = List<Report>.from(reports);
    if (selectedCategory != null) {
      filtered = filtered.where((r) => r.category == selectedCategory).toList();
    }
    filtered.sort(
      (a, b) => currentSort == SortOrder.newest
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return filtered;
  });
});

final visibleReportListProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final reportsAsync = ref.watch(reportListProvider);
  final currentUser = ref.watch(currentUserProvider);

  return reportsAsync.whenData((reports) {
    if (currentUser == null) return <Report>[];

    // Yöneticiler ve Sorumlular her şeyi görür
    if (canViewAllReports(currentUser.role)) return reports;

    // Personel sadece kendine atananları görür
    if (canViewAssignedReportsOnly(currentUser.role)) {
      return reports.where((r) => r.assignedStaffId == currentUser.id).toList();
    }

    // Vatandaş sadece kendi açtığı şikayetleri görür
    return reports.where((r) => r.userId == currentUser.id).toList();
  });
});
