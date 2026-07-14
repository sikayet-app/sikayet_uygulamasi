import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/report.dart';
import 'report_repository.dart';

class LocalReportRepository implements ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Report>> getReports() async {
    await _seedIfEmpty();
    final maps = await _dbHelper.getAllReports();
    return maps.map((map) => Report.fromMap(map)).toList();
  }

  Future<void> _seedIfEmpty() async {
    final count = await _dbHelper.getReportCount();
    if (count > 0) return;

    final seedReports = _generateSeedData();
    for (final report in seedReports) {
      await _dbHelper.insertReport(report);
    }
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

  List<Report> _generateSeedData() {
    final now = DateTime.now();
    const uuid = Uuid();
    return [
      Report(
        id: uuid.v4(),
        title: 'Üniversite Bulvarı Asfalt Çökmesi ',
        description: 'Yolda derin bir çukur oluşmuş,araçlar zorlanıyor',
        category: ReportCategory.pothole,
        status: ReportStatus.pending,
        latitude: 37.0263,
        longitude: 37.2882,
        imagePath: '',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Report(
        id: uuid.v4(),
        title: 'Karataş Sokak Lambası',
        description: 'Parkın köşesindeki 3 lamba yanmıyor',
        category: ReportCategory.lighting,
        status: ReportStatus.inProgress,
        latitude: 37.0145,
        longitude: 37.3120,
        imagePath: '',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Report(
        id: uuid.v4(),
        title: 'Sanko Park Yanı Rögar Taşması',
        description: 'Altyapı sorunu var, yola su taşıyor',
        category: ReportCategory.infrastructure,
        status: ReportStatus.resolved,
        latitude: 37.0658,
        longitude: 37.3698,
        imagePath: '',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}
