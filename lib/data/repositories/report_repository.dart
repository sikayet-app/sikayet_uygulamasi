import '../models/report.dart';

abstract class ReportRepository {
  Future<List<Report>> getReports({String? status, String? category});
  Future<void> addReport(Report report);
  Future<void> updateStatus(String id, ReportStatus status);
  Future<void> deleteReport(String id);
  Future<void> updateReport(Report report);
  Future<void> updateStatusWithNote(
    String reportId,
    ReportStatus status,
    String? note,
  );
  Future<void> assignReport(String reportId, String staffId);
  Future<void> updateAssignedStaff(String reportId, String staffId);
}
