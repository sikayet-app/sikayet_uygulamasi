import 'package:flutter_test/flutter_test.dart';
import 'package:sikayet_uygulamasi/data/models/report.dart';

void main() {
  group('Report Model', () {
    test('toMap() ve fromMap() birbirinin tersini doğru yapıyor', () {
      final original = Report(
        id: 'test-id-123',
        title: 'Yolda büyük bir çukur var',
        description: 'Araçlar zarar görüyor',
        category: ReportCategory.pothole,
        status: ReportStatus.pending,
        latitude: 36.8000,
        longitude: 34.6333,
        imagePaths: ['/data/user/0/com.example/report_images/abc.jpg'],
        createdAt: DateTime(2026, 7, 10, 14, 30),
        userId: 'test-user-1'
      );

      final map = original.toMap();
      final reconstructed = Report.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.description, original.description);
      expect(reconstructed.category, original.category);
      expect(reconstructed.status, original.status);
      expect(reconstructed.latitude, original.latitude);
      expect(reconstructed.longitude, original.longitude);
      expect(reconstructed.createdAt, original.createdAt);
    });
    test('fromMap() bilinmeyen kategori metniye çökmüyor, other a düşüyor', () {
      final map = {
        'id': 'x',
        'title': 't',
        'description': 'd',
        'category': 'bilinmeyen_kategori',
        'status': 'pending',
        'latitude': 36.0,
        'longitude': 34.0,
        'imagePaths': 'p',
        'createdAt': DateTime.now().toIso8601String(),
        'userId': 'test-user-1'
      };
      final report = Report.fromMap(map);
      expect(report.category, ReportCategory.other);
    });

    test('latitude int olarak gelse bile çökmüyor', () {
      final map = {
        'id': 'x',
        'title': 't',
        'description': 'd',
        'category': 'bilinmeyen_kategori',
        'status': 'pending',
        'latitude': 36,
        'longitude': 34,
        'imagePaths': 'p',
        'createdAt': DateTime.now().toIso8601String(),
        'userId': 'test-user-1'
      };
      final report = Report.fromMap(map);
      expect(report.latitude, 36.0);
    });

    test('copyWith() sadece belirtilen alanı değiştiriyor', () {
      final original = Report(
        id: 'id-1',
        title: 'Başlık',
        description: 'Açıklama',
        category: ReportCategory.garbage,
        latitude: 1.0,
        longitude: 2.0,
        imagePaths: ['p'],
        createdAt: DateTime(2026, 1, 1),
        userId: 'test-user-1'
      );

      final updated = original.copyWith(status: ReportStatus.resolved);

      expect(updated.status, ReportStatus.resolved);
      expect(updated.title, original.title);
      expect(updated.id, original.id);
    });
  });
}
