import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/maintenance_request.dart';

class MaintenanceRequestService {
  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final token = await user.getIdToken();

    if (token == null) {
      throw Exception('Unable to get authentication token');
    }

    return token;
  }

  Future<MaintenanceRequest> createRequest({
    String? diagnosisId,
    String? requestDescription,   
    required String specializationId,
    required String technicianProfileId,
    required String contactPhone,
    required String workArea,
    required String addressDetails,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{
      'specialization_id': specializationId,
      'technician_profile_id': technicianProfileId,
      'contact_phone': contactPhone.trim(),
      'work_area': workArea.trim(),
      'address_details': addressDetails.trim(),
    };
        if (diagnosisId != null) {
      body['diagnosis_id'] = diagnosisId;
    }

    final description = requestDescription?.trim();

    if (description != null && description.isNotEmpty) {
      body['request_description'] = description;
    }

    if (diagnosisId == null &&
        (description == null ||
            description.runes.length < 10 ||
            description.runes.length > 2000)) {
      throw ArgumentError('أدخل وصف المشكلة بين 10 و2000 حرف');
    }

    final normalizedNotes = notes?.trim();

    if (normalizedNotes != null && normalizedNotes.isNotEmpty) {
      body['notes'] = normalizedNotes;
    }

    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/maintenance-requests'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

        if (response.statusCode == 404) {
      throw StateError(
        'الفني لم يعد متاحًا لهذا الطلب. ارجع وحدّث قائمة الفنيين.',
      );
    }

    final decodedBody = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response from maintenance service');
    }

    if (response.statusCode != 201) {
      throw Exception(
        decodedBody['message'] ?? 'Failed to create maintenance request',
      );
    }

    final requestData = decodedBody['maintenance_request'];

    if (requestData is! Map) {
      throw Exception('Maintenance request data was not returned');
    }

    return MaintenanceRequest.fromJson(Map<String, dynamic>.from(requestData));
  }

  Future<({MaintenanceRequest request, bool isTechnicianView})>
  getRequestDetails(String requestId) async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/maintenance-requests/'
            '${Uri.encodeComponent(requestId)}',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw StateError('الطلب غير موجود أو لم يعد متاحًا لهذا الحساب.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('لا يمكن فتح الطلب بهذا الحساب. تحقق من تسجيل الدخول.');
    }

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل تفاصيل الطلب.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic> ||
        data['success'] != true ||
        data['maintenance_request'] is! Map) {
      throw const FormatException('استجابة غير صالحة لبيانات الطلب.');
    }

    final role = data['viewer_role'];

    if (role != 'user' && role != 'technician') {
      throw const FormatException('دور الحساب غير متوقع.');
    }

    return (
      request: MaintenanceRequest.fromJson(
        Map<String, dynamic>.from(data['maintenance_request'] as Map),
      ),
      isTechnicianView: role == 'technician',
    );
  }

  Future<List<MaintenanceRequest>> getMyRequests() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/maintenance-requests'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response from maintenance service');
    }

    if (response.statusCode != 200) {
      throw Exception(
        decodedBody['message'] ?? 'Failed to load maintenance requests',
      );
    }

    final requestsData = decodedBody['maintenance_requests'];

    if (requestsData is! List) {
      throw Exception('Maintenance requests were not returned');
    }
    for (final item in requestsData) {
      if (item is Map && item['status'] == 'closed') {
        final parsed = MaintenanceRequest.fromJson(
          Map<String, dynamic>.from(item),
        );

        debugPrint(
          'REVIEW CHECK: id=${item['id']}, '
          'apiReview=${jsonEncode(item['review'])}, '
          'modelRating=${parsed.reviewRating}',
        );
      }
    }

    return requestsData
        .map(
          (item) => MaintenanceRequest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<MaintenanceRequest>> getTechnicianRequests() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/maintenance-requests/technician'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response from maintenance service');
    }

    if (response.statusCode != 200) {
      throw Exception(
        decodedBody['message'] ?? 'Failed to load technician requests',
      );
    }

    final requestsData = decodedBody['maintenance_requests'];

    if (requestsData is! List) {
      throw Exception('Maintenance requests were not returned');
    }

    return requestsData
        .map(
          (item) => MaintenanceRequest.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> updateTechnicianRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/maintenance-requests/'
            'technician/$requestId/status',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response from maintenance service');
    }

    if (response.statusCode != 200) {
      throw Exception(
        decodedBody['message'] ?? 'Failed to update request status',
      );
    }
  }

  Future<void> declineTechnicianRequest({required String requestId}) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/maintenance-requests/'
            'technician/$requestId/decline',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('استجابة غير صالحة من خدمة طلبات الصيانة');
    }

    if (response.statusCode == 409) {
      throw Exception(
        'تعذر الاعتذار؛ ربما تغيرت حالة الطلب. حدّث القائمة وحاول مجددًا.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('تعذر الاعتذار عن الطلب، حاول مجددًا.');
    }
  }

  Future<void> reassignMyRequest({
    required String requestId,
    required String technicianProfileId,
  }) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/maintenance-requests/'
            '$requestId/reassign',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'technician_profile_id': technicianProfileId}),
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('استجابة غير صالحة من خدمة طلبات الصيانة');
    }

    if (response.statusCode == 409) {
      throw Exception(
        'تعذر إسناد الطلب؛ ربما تغيرت حالته أو أصبح الفني غير متاح. '
        'حدّث الطلبات وحاول مجددًا.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('تعذر إرسال الطلب للفني المختار، حاول مجددًا.');
    }
  }

  Future<void> cancelMyRequest({required String requestId}) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/maintenance-requests/'
            '$requestId/cancel',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 409) {
      throw StateError(
        'تعذر إلغاء الطلب؛ ربما بدأ الفني العمل أو تغيرت حالة الطلب.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception('تعذر إلغاء الطلب');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw Exception('استجابة غير متوقعة من خدمة الصيانة');
    }
  }

  Future<void> reviewMyRequest({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('التقييم يجب أن يكون من 1 إلى 5');
    }

    final token = await _getToken();

    final body = <String, dynamic>{'rating': rating};

    final normalizedComment = comment?.trim();

    if (normalizedComment != null && normalizedComment.isNotEmpty) {
      body['comment'] = normalizedComment;
    }

    final response = await http
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/maintenance-requests/'
            '$requestId/review',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('استجابة غير صالحة من خدمة طلبات الصيانة');
    }

    if (response.statusCode == 409) {
      throw Exception(
        'لا يمكن تقييم الطلب حاليًا؛ قد يكون تم تقييمه '
        'مسبقًا أو أنه لم يكتمل بعد. حدّث قائمة الطلبات.',
      );
    }

    if (response.statusCode != 201) {
      throw Exception('تعذر حفظ التقييم، حاول مجددًا.');
    }
  }
}
