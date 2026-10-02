class MaintenanceRequest {
  const MaintenanceRequest({
    required this.id,
    required this.userId,
       this.diagnosisId,
    this.requestDescription,
    required this.specializationId,
    required this.contactPhone,
    required this.workArea,
    required this.addressDetails,
    required this.status,
    required this.createdAt,
    this.technicianProfileId,
    this.notes,
    this.latitude,
    this.longitude,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.closedAt,
    this.predictedFault,
    this.severity,
    this.diagnosisDescription,
    this.specializationName,
    this.technicianName,
    this.technicianPhone,
    this.technicianWorkArea,
    this.technicianRating,
    this.technicianCompletedJobs,
    this.customerName,
    this.customerEmail,
    this.reviewRating,
    this.reviewComment,
    this.reviewCreatedAt,
  });

  final String id;
  final String userId;
    final String? diagnosisId;
  final String? requestDescription;

  bool get isDirectRequest => diagnosisId == null;

  String get problemTitle =>
      predictedFault ?? requestDescription ?? 'طلب صيانة';

  String get problemDescription =>
      requestDescription ?? diagnosisDescription ?? 'لا يوجد وصف';
  final String specializationId;
  final String? technicianProfileId;
  final String contactPhone;
  final String workArea;
  final String addressDetails;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? closedAt;

  final String? predictedFault;
  final String? severity;
  final String? diagnosisDescription;
  final String? specializationName;

  final String? technicianName;
  final String? technicianPhone;
  final String? technicianWorkArea;
  final double? technicianRating;
  final int? technicianCompletedJobs;

  final String? customerName;
  final String? customerEmail;
  final int? reviewRating;
  final String? reviewComment;
  final DateTime? reviewCreatedAt;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    final diagnosis = _parseMap(json['diagnosis']);
    final specialization = _parseMap(json['specialization']);
    final technician = _parseMap(json['technician']);
    final customer = _parseMap(json['customer']);
    final review = _parseMap(json['review']);

    return MaintenanceRequest(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      diagnosisId: json['diagnosis_id']?.toString(),
      requestDescription: json['request_description']?.toString(),      specializationId: json['specialization_id'].toString(),
      technicianProfileId: json['technician_profile_id']?.toString(),
      contactPhone: json['contact_phone']?.toString() ?? '',
      workArea: json['work_area']?.toString() ?? '',
      addressDetails: json['address_details']?.toString() ?? '',
      notes: json['notes']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: json['status']?.toString() ?? 'created',
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      assignedAt: _parseDate(json['assigned_at']),
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      closedAt: _parseDate(json['closed_at']),
      predictedFault: diagnosis?['predicted_fault']?.toString(),
      severity: diagnosis?['severity']?.toString(),
      diagnosisDescription: diagnosis?['description']?.toString(),
      specializationName: specialization?['name_ar']?.toString(),
      technicianName: technician?['name']?.toString(),
      technicianPhone: technician?['phone']?.toString(),
      technicianWorkArea: technician?['work_area']?.toString(),
      technicianRating: _parseDouble(technician?['average_rating']),
      technicianCompletedJobs: _parseInt(technician?['total_completed_jobs']),
      customerName: customer?['name']?.toString(),
      customerEmail: customer?['email']?.toString(),
      reviewRating: _parseInt(review?['rating']),
      reviewComment: review?['comment']?.toString(),
      reviewCreatedAt: _parseDate(review?['created_at']),
    );
  }

  static Map<String, dynamic>? _parseMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(value);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
