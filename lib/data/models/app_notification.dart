class AppNotification {
  final String id;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'].toString(),
      data: map['data'] as Map<String, dynamic>,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
