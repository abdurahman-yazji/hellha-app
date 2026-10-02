import 'diagnosis_result.dart';

class DiagnosisHistoryItem {
  const DiagnosisHistoryItem({
    required this.id,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.result,
  });

  final String id;
  final String category;
  final String description;
  final DateTime createdAt;
  final DiagnosisResult result;

  factory DiagnosisHistoryItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistoryItem(
      id: json['id'].toString(),
      category: json['category']?.toString() ?? 'غير محدد',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      result: DiagnosisResult.fromJson(json),
    );
  }
}
