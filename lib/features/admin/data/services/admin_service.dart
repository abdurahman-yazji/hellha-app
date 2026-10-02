import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class AdminService {
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

  Future<List<Map<String, dynamic>>> getPendingTechnicians() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/technicians/pending'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load pending technicians');
    }

    final technicians = data['technicians'] as List<dynamic>;

    return technicians
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getVerifiedTechnicians() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/admin/technicians/verified'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load verified technicians');
    }

    final technicians = data['technicians'] as List<dynamic>;

    return technicians
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> updateVerification({
    required String technicianProfileId,
    required bool isVerified,
  }) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/admin/technicians/'
            '$technicianProfileId/verification',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'is_verified': isVerified}),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ?? 'Failed to update technician verification',
      );
    }

    return Map<String, dynamic>.from(data['technician'] as Map);
  }


Future<List<Map<String, dynamic>>> getPendingSpecializationChanges() async {
  final token = await _getToken();

  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.baseUrl}/admin/specialization-change-requests',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      )
      .timeout(const Duration(seconds: 20));

  final data = jsonDecode(utf8.decode(response.bodyBytes));

  if (data is! Map<String, dynamic>) {
    throw const FormatException('استجابة غير صالحة من الخادم');
  }

  if (response.statusCode != 200) {
    throw StateError('تعذر تحميل طلبات تعديل التخصصات');
  }

  final requests = data['change_requests'];

  if (requests is! List) {
    throw const FormatException('لم تصل قائمة طلبات المراجعة');
  }

  return requests.map((item) {
    if (item is! Map) {
      throw const FormatException('بيانات طلب المراجعة غير صالحة');
    }

    return Map<String, dynamic>.from(item);
  }).toList();
}

Future<void> reviewSpecializationChange({
  required String requestId,
  required bool approved,
  String? reviewNote,
}) async {
  final token = await _getToken();

  final body = <String, dynamic>{
    'decision': approved ? 'approved' : 'rejected',
  };

  final normalizedNote = reviewNote?.trim();

  if (normalizedNote != null && normalizedNote.isNotEmpty) {
    body['review_note'] = normalizedNote;
  }

  final response = await http
      .patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/admin/specialization-change-requests/'
          '${Uri.encodeComponent(requestId)}/review',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 20));

  final data = jsonDecode(utf8.decode(response.bodyBytes));

  if (data is! Map<String, dynamic>) {
    throw const FormatException('استجابة غير صالحة من الخادم');
  }

  if (response.statusCode == 200) return;

  if (response.statusCode == 400 ||
      response.statusCode == 404 ||
      response.statusCode == 409) {
    final message = data['message'];

    throw StateError(
      message is String && message.trim().isNotEmpty
          ? message
          : 'تعذر مراجعة الطلب. حدّث القائمة وحاول مجددًا.',
    );
  }

  if (response.statusCode == 401 || response.statusCode == 403) {
    throw StateError(
      'تعذر التحقق من صلاحية المسؤول. أعد تسجيل الدخول.',
    );
  }

  throw Exception(
    'تعذر تأكيد حفظ القرار. حدّث القائمة للتحقق من حالة الطلب.',
  );
}


}
