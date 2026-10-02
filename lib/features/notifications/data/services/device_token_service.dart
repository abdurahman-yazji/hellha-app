import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class DeviceTokenService {
  Future<void> registerDevice({
    required User user,
    required String token,
    required String platform,
  }) {
    return _send(user: user, token: token, platform: platform, remove: false);
  }

  Future<void> unregisterDevice({
    required User user,
    required String token,
    required String platform,
  }) {
    return _send(user: user, token: token, platform: platform, remove: true);
  }

  Future<void> _send({
    required User user,
    required String token,
    required String platform,
    required bool remove,
  }) async {
    final normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw ArgumentError('رمز الجهاز مطلوب');
    }

    final auth = FirebaseAuth.instance;

    if (auth.currentUser?.uid != user.uid) {
      throw StateError('تغير الحساب أثناء تسجيل الجهاز');
    }

    final idToken = await user.getIdToken().timeout(
      const Duration(seconds: 20),
    );

    if (idToken == null || auth.currentUser?.uid != user.uid) {
      throw StateError('تعذر التحقق من جلسة المستخدم');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/device-tokens');

    final headers = <String, String>{
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({'token': normalizedToken, 'platform': platform});

    final response =
        await (remove
                ? http.delete(uri, headers: headers, body: body)
                : http.put(uri, headers: headers, body: body))
            .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw StateError('تعذر اعتماد جلسة المستخدم لخدمة الإشعارات');
    }

    if (response.statusCode != 200) {
      throw Exception(
        remove
            ? 'تعذر إلغاء تسجيل الجهاز للإشعارات'
            : 'تعذر تسجيل الجهاز للإشعارات',
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw const FormatException('استجابة غير صالحة من خدمة تسجيل الأجهزة');
    }
  }
}
