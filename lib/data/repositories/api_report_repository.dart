import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import '../models/report.dart';
import 'report_repository.dart';

class ApiReportRepository implements ReportRepository {
  late final Dio _dio;

  ApiReportRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {'Accept': 'application/json'},
      ),
    );

    //her istekten önce otomatik olarak token ı ekler.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('authToken');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
  @override
  Future<List<Report>> getReports() async {
    // Backend'deki index metodu pagination (sayfalama) ile 'data' içinde liste döner
    final response = await _dio.get('/reports');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => Report.fromMap(json)).toList();
  }

  @override
  Future<void> addReport(Report report) async {
    final formData = FormData.fromMap({
      'title': report.title,
      'description': report.description,
      'category': report.category.name, // Enum'u string yapıyoruz
      'latitude': report.latitude,
      'longitude': report.longitude,
    });

    for (var imagePath in report.imagePaths) {
      // imagePaths içinde yerel dosya yolları var, bunları MultipartFile'a çeviriyoruz
      formData.files.add(
        MapEntry(
          'images[]', // Backend bu ismi bekliyor
          await MultipartFile.fromFile(imagePath),
        ),
      );
    }

    await _dio.post('/reports', data: formData);
  }

  @override
  Future<void> updateStatus(String reportId, ReportStatus status) async {
    // Sadece durumu güncelleyen özel rota (Adminler için)
    await _dio.patch(
      '/reports/$reportId/status',
      data: {'status': status.name},
    );
  }

  @override
  Future<void> deleteReport(String id) async {
    await _dio.delete('/reports/$id');
  }

  @override
  Future<void> updateReport(Report report) async {
    // Laravel'e bunun bir PATCH (Yama/Güncelleme) işlemi olduğunu söylüyoruz.
    final formData = FormData.fromMap({
      '_method': 'PATCH',
      'title': report.title,
      'description': report.description,
      'category': report.category.name,
      'latitude': report.latitude,
      'longitude': report.longitude,
    });

    for (var imagePath in report.imagePaths) {
      // Sadece yeni seçilen (yerel) dosyaları gönderiyoruz.
      if (!imagePath.startsWith('http')) {
        formData.files.add(
          MapEntry('images[]', await MultipartFile.fromFile(imagePath)),
        );
      }
    }

    // İstek POST olarak gidiyor ama içindeki '_method' sayesinde backend bunu PATCH olarak işliyor.
    await _dio.post('/reports/${report.id}', data: formData);
  }

  @override
  Future<void> updateStatusWithNote(
    String reportId,
    ReportStatus status,
    String? note,
  ) async {
    await _dio.patch(
      '/reports/$reportId/status',
      data: {'status': status.name, 'resolution_note': note},
    );
  }

  @override
  Future<void> assignReport(String reportId, String staffId) async {
    await _dio.patch('/reports/$reportId/assign', data: {'staff_id': staffId});
  }
}
