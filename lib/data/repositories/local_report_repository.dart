import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/report.dart';
import 'report_repository.dart';
import '../models/paginated_result.dart';
import '../models/stats.dart';


class LocalReportRepository implements ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Report>> getReports({String? status, String? category}) async {
    final maps = await _dbHelper.getAllReports();
    return maps.map((map) => Report.fromMap(map)).toList();
  }

  @override
  Future<void> addReport(Report report) async {
    await _dbHelper.insertReport(report);
  }

  @override
  Future<void> updateStatus(String id, ReportStatus status) async {
    await _dbHelper.updateStatus(id, status.name);
  }

  @override
  Future<void> deleteReport(String id) async {
    await _dbHelper.deleteReport(id);
  }

  @override
  Future<void> updateReport(Report report, {List<String> removedImagePaths  = const []}) async {
    await _dbHelper.insertReport(report);
  }

  @override
  Future<void> updateStatusWithNote(
    String reportId,
    ReportStatus status,
    String? note,
  ) async {
    await _dbHelper.updateStatusWithNote(reportId, status.name, note);
  }

  @override
  Future<void> assignReport(String reportId, String staffId) async {}

  @override
  Future<void> updateAssignedStaff(String reportId, String staffId) async {}
  @override
  Future<PaginatedResult<Report>> getReportsPage({
    int page = 1,
    String? status,
    String? category,
  }) async {
    return const PaginatedResult<Report>(
      items: [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }
  @override
  Future<DashboardStats> getDashboardStats() async {
    return DashboardStats(
      totalReports: 0,
      pendingReports: 0,
      inProgressReports: 0,
      resolvedReports: 0,
      rejectedReports: 0,
      unfoundedReports: 0,
      managingCount: 0,
      staffCount: 0,
      citizenCount: 0,
      categoryBreakdown: [],
      monthlyReports: [],
    );
  }
  @override
  Future<MyStats> getMyStats() async {
    return MyStats(
      role: 'citizen',
      assignedReports: 0,
      openReports: 0,
      resolvedReports: 0,
    );
  }
}
