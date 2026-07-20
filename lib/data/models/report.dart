enum ReportCategory { pothole, lighting, garbage, infrastructure, other }

enum ReportStatus { pending, inProgress, resolved }

class Report {
  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final double latitude; //enlem
  final double longitude; //boylam
  final List<String> imagePaths;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    // şikayet ilk oluşturulduğunda her zaman bekleme durumunda
    this.status = ReportStatus.pending,
    required this.longitude,
    required this.imagePaths,
    required this.createdAt,
  });

  // şikayetin durumunu çözüldü yapmak istediğimizde, eski şikayetin tüm verilerini al sadece durumunu değiştiren yeni bir nesne oluştur.
  Report copyWith({
    String? id,
    String? title,
    String? description,
    ReportCategory? category,
    ReportStatus? status,
    double? latitude,
    double? longitude,
    String? imagePaths,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // db den okuma için. factory, var olan veya yeni nesneyi döndürmemizi sağlar.
  // amaç: sqlite dan gelen karmaşık map yapısını temiz bir Report nesnesine çevirmek
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: ReportCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ReportCategory.other,
      ),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      imagePaths: map['imagePaths'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // db ye yazma.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

//yardımcı fonk. kullanıcıya enum isimlerini türkçe olarak göstermek için
String getCategoryLabel(ReportCategory category) {
  switch (category) {
    case ReportCategory.garbage:
      return "Çöp/Atık";
    case ReportCategory.pothole:
      return "Çukur";
    case ReportCategory.infrastructure:
      return "Altyapı";
    case ReportCategory.lighting:
      return "Aydınlatma";
    case ReportCategory.other:
      return "Diğer";
  }
}

String getStatusLabel(ReportStatus status) {
  switch (status) {
    case ReportStatus.pending:
      return "Beklemede";
    case ReportStatus.inProgress:
      return "İşlemde";
    case ReportStatus.resolved:
      return "Çözüldü";
  }
}
