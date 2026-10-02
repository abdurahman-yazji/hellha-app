import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class TechnicianService {
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

  Future<List<Map<String, dynamic>>> getSpecializations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/specializations'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load specializations');
    }

    final specializations = data['specializations'] as List<dynamic>;

    return specializations
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createMyProfile({
    required String phone,
    required String workArea,
    required int yearsOfExperience,
    String? bio,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{
      'phone': phone.trim(),
      'work_area': workArea.trim(),
      'years_of_experience': yearsOfExperience,
    };

    final normalizedBio = bio?.trim();

    if (normalizedBio != null && normalizedBio.isNotEmpty) {
      body['bio'] = normalizedBio;
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/technicians'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 409) {
      throw StateError(
        'يوجد ملف فني لهذا الحساب بالفعل. '
        'ارجع للرئيسية وحدّث بيانات الحساب.',
      );
    }

    if (response.statusCode == 403) {
      throw StateError('لا يُسمح لهذا الحساب بإنشاء ملف فني.');
    }

    if (response.statusCode == 400) {
      throw StateError('تحقق من رقم الهاتف ومنطقة العمل وسنوات الخبرة.');
    }

    if (response.statusCode != 201) {
      throw Exception('تعذر إنشاء ملف الفني.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw const FormatException('استجابة غير صالحة من السيرفر.');
    }

    final technician = data['technician'];

    if (technician is! Map) {
      throw const FormatException('لم تصل بيانات ملف الفني.');
    }

    return Map<String, dynamic>.from(technician);
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/technicians/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load technician profile');
    }

    return Map<String, dynamic>.from(data['technician'] as Map);
  }

 Future<void> setMySpecializations(
  List<String> specializationIds,
) async {
  final token = await _getToken();

  final response = await http
      .put(
        Uri.parse('${ApiConfig.baseUrl}/technicians/me/specializations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'specialization_ids': specializationIds,
        }),
      )
      .timeout(const Duration(seconds: 20));

  final decoded = jsonDecode(utf8.decode(response.bodyBytes));

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('استجابة غير صالحة من الخادم');
  }

  if (response.statusCode != 202) {
    final message = decoded['message'];

    if (response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 409) {
      throw StateError(
        message is String && message.trim().isNotEmpty
            ? message
            : 'تعذر إرسال طلب تعديل التخصصات',
      );
    }

    throw Exception('تعذر إرسال طلب تعديل التخصصات');
  }
}

  Future<Map<String, dynamic>> updateMyProfile({
    String? phone,
    String? bio,
    String? workArea,
    int? yearsOfExperience,
    double? serviceRadiusKm,
    String? availabilityStatus,
  }) async {
    final token = await _getToken();

    final updates = <String, dynamic>{};

    if (phone != null) {
      updates['phone'] = phone;
    }

    if (bio != null) {
      updates['bio'] = bio;
    }

    if (workArea != null) {
      updates['work_area'] = workArea;
    }

    if (yearsOfExperience != null) {
      updates['years_of_experience'] = yearsOfExperience;
    }

    if (serviceRadiusKm != null) {
      updates['service_radius_km'] = serviceRadiusKm;
    }

    if (availabilityStatus != null) {
      updates['availability_status'] = availabilityStatus;
    }

    if (updates.isEmpty) {
      throw ArgumentError('At least one technician profile field is required');
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/technicians/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updates),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

if (data is! Map<String, dynamic>) {
  throw const FormatException('استجابة غير صالحة من الخادم');
}

if (response.statusCode != 200) {
  if (response.statusCode == 400 ||
      response.statusCode == 403 ||
      response.statusCode == 404 ||
      response.statusCode == 409) {
    final message = data['message'];

    throw StateError(
      message is String && message.trim().isNotEmpty
          ? message
          : 'تعذر تحديث الملف المهني',
    );
  }

  throw Exception('تعذر تأكيد تحديث الملف المهني');
}

final technician = data['technician'];

if (technician is! Map) {
  throw const FormatException('لم تصل بيانات الملف المهني');
}

return Map<String, dynamic>.from(technician);
  }

  Future<List<Map<String, dynamic>>> getAvailableTechnicians({
    required String specializationId,
    String? workArea,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final token = await user.getIdToken();

    if (token == null) {
      throw Exception('Unable to get authentication token');
    }

    final queryParameters = <String, String>{
      'specialization_id': specializationId,
    };

    final normalizedWorkArea = workArea?.trim();

    if (normalizedWorkArea != null && normalizedWorkArea.isNotEmpty) {
      queryParameters['work_area'] = normalizedWorkArea;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/technicians/available',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ?? 'Failed to load available technicians',
      );
    }

    final technicians = data['technicians'] as List<dynamic>;

    return technicians
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMySpecializations() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/technicians/me/specializations'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('استجابة غير صالحة من خدمة التخصصات');
    }

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل تخصصاتك الحالية');
    }

    final specializations = decodedBody['specializations'];

    if (specializations is! List) {
      throw Exception('لم يتم إرجاع قائمة التخصصات');
    }

    return specializations
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }


Future<Map<String, dynamic>?> getMySpecializationChangeRequest() async {
  final token = await _getToken();

  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.baseUrl}/technicians/me/'
          'specialization-change-request',
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
    throw StateError('تعذر تحميل حالة طلب تعديل التخصصات');
  }

  if (!data.containsKey('change_request')) {
    throw const FormatException('لم تصل حالة طلب تعديل التخصصات');
  }

  final request = data['change_request'];

  if (request == null) return null;

  if (request is! Map) {
    throw const FormatException('بيانات طلب التعديل غير صالحة');
  }

  return Map<String, dynamic>.from(request);
}



}
