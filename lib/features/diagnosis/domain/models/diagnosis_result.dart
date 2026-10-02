class DiagnosisResult {
  const DiagnosisResult({
    this.id,
    this.createdAt,
    required this.predictedFault,
    required this.severity,
    required this.tools,
    required this.guide,
    required this.safetyWarnings,
    required this.requiresTechnician,
  });

  final String? id;
  final DateTime? createdAt;
  final String predictedFault;
  final String severity;
  final List<String> tools;
  final List<String> guide;
  final List<String> safetyWarnings;
  final bool requiresTechnician;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'];

    return DiagnosisResult(
      id: json['id']?.toString(),
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse(createdAtValue.toString())?.toLocal(),
      predictedFault: json['predicted_fault']?.toString() ?? 'عطل غير محدد',
      severity: json['severity']?.toString() ?? 'medium',
      tools: _parseStringList(json['tools']),
      guide: _parseStringList(json['guide']),
      safetyWarnings: _parseStringList(json['safety_warnings']),
      requiresTechnician: json['requires_technician'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'predicted_fault': predictedFault,
      'severity': severity,
      'tools': tools,
      'guide': guide,
      'safety_warnings': safetyWarnings,
      'requires_technician': requiresTechnician,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
