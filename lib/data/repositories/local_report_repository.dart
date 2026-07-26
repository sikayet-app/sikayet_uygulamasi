import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/report.dart';
import 'report_repository.dart';

class LocalReportRepository implements ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Report>> getReports() async {
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
  Future<void> updateReport(Report report) async {
    await _dbHelper.insertReport(report);
  }
}
