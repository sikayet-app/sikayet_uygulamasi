import 'package:sikayet_uygulamasi/data/models/paginated_result.dart';
import 'package:sikayet_uygulamasi/data/models/stats.dart';

import '../models/report.dart';

abstract class ReportRepository {
  Future<List<Report>> getReports({String? status, String? category});
  Future<PaginatedResult<Report>> getReportsPage({
    int page = 1,
    String? status,
    String? category,
  });
  Future<void> addReport(Report report);
  Future<void> updateStatus(String id, ReportStatus status);
  Future<void> deleteReport(String id);
  Future<void> updateReport(Report report, {List<String> removedImagePaths});
  Future<void> updateStatusWithNote(
    String reportId,
    ReportStatus status,
    String? note,
  );
  Future<void> assignReport(String reportId, String staffId);
  Future<void> updateAssignedStaff(String reportId, String staffId);
  Future<DashboardStats> getDashboardStats();
  Future<MyStats> getMyStats();
}
