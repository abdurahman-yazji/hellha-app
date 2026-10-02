class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.maintenanceRequestId,
    this.readAt,
  });

  final String id;
  final String? maintenanceRequestId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      maintenanceRequestId: json['maintenance_request_id']?.toString(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'].toString()).toLocal(),
    );
  }
}
