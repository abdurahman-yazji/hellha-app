import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class CertificateService {
  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولًا');
    }

    final token = await user.getIdToken();

    if (token == null) {
      throw Exception('تعذر الحصول على رمز المصادقة');
    }

    return token;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('استجابة غير صالحة من خدمة الشهادات');
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getMyCertificates() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/technicians/me/certificates'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الشهادات');
    }

    final certificates = data['certificates'];

    if (certificates is! List) {
      throw Exception('لم يتم إرجاع قائمة الشهادات');
    }

    return certificates
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createCertificate({
    required String certificateName,
    String? issuingOrganization,
    String? issueDate,
    String? expiryDate,
    String? documentUrl,
    XFile? image,
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/technicians/me/certificates'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['certificate_name'] = certificateName.trim();

    void addOptionalField(String key, String? value) {
      final text = value?.trim();

      if (text != null && text.isNotEmpty) {
        request.fields[key] = text;
      }
    }

    addOptionalField('issuing_organization', issuingOrganization);
    addOptionalField('issue_date', issueDate);
    addOptionalField('expiry_date', expiryDate);
    addOptionalField('document_url', documentUrl);

    if (image != null) {
      const maxBytes = 5 * 1024 * 1024;

      if (await image.length() > maxBytes) {
        throw Exception('حجم الصورة يجب ألا يتجاوز 5 ميجابايت');
      }

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty || bytes.length > maxBytes) {
        throw Exception('الصورة فارغة أو يتجاوز حجمها 5 ميجابايت');
      }

      final format = _detectImageFormat(bytes);

      if (format == null) {
        throw Exception('اختر صورة JPEG أو PNG أو WebP');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'certificate.$format',
          contentType: MediaType('image', format),
        ),
      );
    }

    // MultipartRequest sets Content-Type and its boundary automatically.
    final client = http.Client();

    try {
      final response = await (() async {
        final streamedResponse = await client.send(request);
        return http.Response.fromStream(streamedResponse);
      })().timeout(const Duration(seconds: 20));

      final data = _decodeResponse(response);

      if (response.statusCode == 413) {
        throw Exception('حجم الصورة أكبر من الحد المسموح');
      }

      if (response.statusCode != 201) {
        throw Exception(data['message'] ?? 'تعذر إضافة الشهادة');
      }

      final certificate = data['certificate'];

      if (certificate is! Map) {
        throw Exception('لم يتم إرجاع بيانات الشهادة');
      }

      return Map<String, dynamic>.from(certificate);
    } finally {
      client.close();
    }
  }

  Future<Uint8List> getCertificateImage(String certificateId) async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/technicians/me/certificates/'
            '$certificateId/image',
          ),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل صورة الشهادة');
    }

    final contentType = response.headers['content-type'] ?? '';

    if (!contentType.toLowerCase().startsWith('image/')) {
      throw Exception('استجابة الصورة غير صالحة');
    }

    return response.bodyBytes;
  }

  Future<void> deleteCertificate(String certificateId) async {
    final token = await _getToken();

    final response = await http
        .delete(
          Uri.parse(
            '${ApiConfig.baseUrl}/technicians/me/certificates/'
            '$certificateId',
          ),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('تعذر حذف الشهادة');
    }
  }

  static String? _detectImageFormat(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpeg';
    }

    const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    if (bytes.length >= pngSignature.length) {
      var isPng = true;

      for (var i = 0; i < pngSignature.length; i++) {
        if (bytes[i] != pngSignature[i]) {
          isPng = false;
          break;
        }
      }

      if (isPng) return 'png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }

    return null;
  }
}
