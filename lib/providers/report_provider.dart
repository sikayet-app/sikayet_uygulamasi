import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sikayet_uygulamasi/providers/auth_provider.dart';
import '../data/repositories/local_report_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report.dart';
import '../data/repositories/api_report_repository.dart';

enum SortOrder { newest, oldest }

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ApiReportRepository();
});

// api den veri çeken provider
// bu provider tüm kayıtları çeker ve filtrelere asla bağımlı değil
final reportListProvider = FutureProvider.autoDispose<List<Report>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return [];
  }
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getReports();
});

final filterCategoryProvider = StateProvider.autoDispose<ReportCategory?>(
  (ref) => null,
);
final filterStatusProvider = StateProvider.autoDispose<ReportStatus?>(
  (ref) => null,
);

final sortProvider = StateProvider.autoDispose<SortOrder>(
  (ref) => SortOrder.newest,
);

// liste ekranı için filtreli
final filteredReportListProvider = FutureProvider.autoDispose<List<Report>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(reportRepositoryProvider);
  final selectedStatus = ref.watch(filterStatusProvider);
  final selectedCategory = ref.watch(filterCategoryProvider);

  return repository.getReports(
    status: selectedStatus?.name,
    category: selectedCategory?.name,
  );
});

// haritada anlık arama için
final mapSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final mapSearchResultsProvider = Provider.autoDispose<List<Report>>((ref) {
  final query = ref.watch(mapSearchQueryProvider).trim().toLowerCase();
  final reports = ref.watch(filteredReportListProvider).valueOrNull ?? [];

  if (query.isEmpty) return [];

  // Hem başlıkta hem de adreste arama yapar, ilk 5 sonucu döndürür
  return reports
      .where((r) {
        return r.title.toLowerCase().contains(query) ||
            (r.fullAddress?.toLowerCase().contains(query) ?? false);
      })
      .take(5)
      .toList();
});
