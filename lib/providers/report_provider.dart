import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/paginated_result.dart';
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

// sayfalamalı liste ekranı için state ve notifier

// ekranın o anki durumunu tutan State sınıfı
class ReportListState {
  final List<Report> reports;
  final int currentPage;
  final bool hasMore;
  final bool isLoading; // ilk yüklemede döner
  final bool isLoadingMore; // aşağı kaydırıp yeni sayfa çekerken döner
  final Object? error;

  const ReportListState({
    this.reports = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  ReportListState copyWith({
    List<Report>? reports,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
  }) {
    return ReportListState(
      reports: reports ?? this.reports,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error, // Yeni bir hata gelirse üzerine yazar, hata yoksa null kalır
    );
  }

}

// veriyi çeken ve state i güncelleyen Notifier sınıfı
class FilteredReportListNotifier extends StateNotifier<ReportListState> {
  final Ref _ref;

  FilteredReportListNotifier(this._ref) : super(const ReportListState()) {
    // Sınıf ilk çağrıldığında 1. sayfayı otomatik yükle
    loadFirstPage();
  }
  Future<void> loadFirstPage() async {
    state = const ReportListState(isLoading: true);
    try {
      final repo = _ref.read(reportRepositoryProvider);
      final status = _ref.read(filterStatusProvider);
      final category = _ref.read(filterCategoryProvider);

      final result = await repo.getReportsPage(
        page: 1,
        status: status?.name,
        category: category?.name,
      );

      state = ReportListState(
        reports: result.items,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = ReportListState(error: e, isLoading: false);
    }
  }
  Future<void> loadMore() async {
    // Zaten yükleniyorsa, daha fazla veri yoksa veya ilk sayfa yükleniyorsa işlemi durdur
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _ref.read(reportRepositoryProvider);
      final status = _ref.read(filterStatusProvider);
      final category = _ref.read(filterCategoryProvider);

      final result = await repo.getReportsPage(
        page: state.currentPage + 1,
        status: status?.name,
        category: category?.name,
      );

      state = state.copyWith(
        // Eski listeye yeni gelen sayfayı ekliyoruz (Infinite Scroll mantığı)
        reports: [...state.reports, ...result.items],
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

// liste ekranı için filtreli
final filteredReportListProvider = StateNotifierProvider.autoDispose<FilteredReportListNotifier, ReportListState>((
  ref,
)  {
  final notifier = FilteredReportListNotifier(ref);
  // EĞER KULLANICI FİLTRELERİ DEĞİŞTİRİRSE: Listeyi sıfırla ve 1. sayfadan tekrar başla!
  ref.listen<ReportStatus?>(filterStatusProvider, (_, __) => notifier.loadFirstPage());
  ref.listen<ReportCategory?>(filterCategoryProvider, (_, __) => notifier.loadFirstPage());

  return notifier;
});

// Sekmeler (Tabs) için özel sayfalama yöneticisi
class AssignmentTabNotifier extends StateNotifier<ReportListState> {
  final Ref _ref;
  final ReportStatus _fixedStatus;

  AssignmentTabNotifier(this._ref, this._fixedStatus) : super(const ReportListState()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = const ReportListState(isLoading: true);
    try {
      final repo = _ref.read(reportRepositoryProvider);
      
      // DİKKAT: Global filtrelere değil, kendine verilen sabit status'e bakar
      final result = await repo.getReportsPage(
        page: 1, 
        status: _fixedStatus.name
      );
      
      state = ReportListState(
        reports: result.items,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = ReportListState(error: e, isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _ref.read(reportRepositoryProvider);
      
      final result = await repo.getReportsPage(
        page: state.currentPage + 1,
        status: _fixedStatus.name,
      );
      
      state = state.copyWith(
        reports: [...state.reports, ...result.items],
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

// Sekmeler için kullanılacak Provider
final assignmentTabProvider = StateNotifierProvider.autoDispose.family<AssignmentTabNotifier, ReportListState, ReportStatus>((ref, status) {
  return AssignmentTabNotifier(ref, status);
});

// haritada anlık arama için
final mapSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final mapSearchResultsProvider = Provider.autoDispose<List<Report>>((ref) {
  final query = ref.watch(mapSearchQueryProvider).trim().toLowerCase();
  
  final state = ref.watch(filteredReportListProvider);
  final reports = state.reports;
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
