import '../models/report.dart';

abstract class ReportRepository {
  Future<List<Report>> getReports();
  Future<void> addReport(Report report);
  Future<void> updateStatus(String id, ReportStatus status);
  Future<void> deleteReport(String id);
}
