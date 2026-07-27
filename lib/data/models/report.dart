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
  final String userId;
  final String? senderName;

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
    required this.userId,
    this.senderName,
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
    List<String>? imagePaths,
    DateTime? createdAt,
    String? userId,
    String? senderName,
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
      userId: userId ?? this.userId,
      senderName: senderName ?? this.senderName,
    );
  }

  // db den okuma için. factory, var olan veya yeni nesneyi döndürmemizi sağlar.
  // amaç: sqlite dan gelen karmaşık map yapısını temiz bir Report nesnesine çevirmek
  factory Report.fromMap(Map<String, dynamic> map) {
    // 1. Kullanıcı bilgisi: API'den geliyorsa gömülü 'user' objesi var,
    // yoksa (local/test durumunda) düz 'userId' alanına bak.
    String userId;
    String? senderName;
    if (map['user'] != null && map['user'] is Map) {
      final userMap = map['user'] as Map;
      userId = userMap['id'].toString();
      senderName = userMap['name'] as String?;
    } else {
      userId = map['userId'].toString();
    }

    // 2. Fotoğraflar: API 'image_urls' kullanıyor, local 'imagePaths' kullanıyor.
    final rawImages = map['image_urls'] ?? map['imagePaths'];
    List<String> imagePaths;
    if (rawImages is List) {
      imagePaths = rawImages.map((e) => e.toString()).toList();
    } else if (rawImages is String) {
      imagePaths = rawImages.isEmpty ? [] : rawImages.split(',');
    } else {
      imagePaths = [];
    }

    // 3. Tarih: API 'created_at', local 'createdAt'.
    final rawCreatedAt = map['created_at'] ?? map['createdAt'];

    return Report(
      id: map['id'].toString(),
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
      imagePaths: imagePaths,
      createdAt: DateTime.parse(rawCreatedAt.toString()),
      userId: userId,
      senderName: senderName,
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
      'imagePaths': imagePaths.join(','),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
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
