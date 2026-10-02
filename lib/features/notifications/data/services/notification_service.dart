import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/app_notification.dart';

class NotificationService {
  static const _timeout = Duration(seconds: 20);

  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('يجب تسجيل الدخول أولًا.');
    }

    final token = await user.getIdToken();

    if (token == null) {
      throw StateError('تعذر التحقق من جلسة الحساب.');
    }

    return token;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('انتهت جلسة الدخول. سجّل الدخول مجددًا.');
    }

    if (response.statusCode == 403) {
      throw Exception('لا يُسمح لهذا الحساب بتنفيذ العملية.');
    }

    if (response.statusCode == 404) {
      throw Exception('الإشعار أو المسار المطلوب غير موجود.');
    }

    if (response.statusCode != 200) {
      throw Exception('تعذر تنفيذ عملية الإشعارات.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw const FormatException('استجابة غير صالحة من خدمة الإشعارات.');
    }

    return data;
  }

  Future<List<AppNotification>> getMyNotifications() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/notifications'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(_timeout);

    final data = _decodeResponse(response);
    final items = data['notifications'];

    if (items is! List) {
      throw const FormatException('لم تصل قائمة الإشعارات.');
    }

    return items.map((item) {
      if (item is! Map) {
        throw const FormatException('بيانات إشعار غير صالحة.');
      }

      return AppNotification.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<int> getUnreadCount() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(_timeout);

    final data = _decodeResponse(response);
    final count = int.tryParse(data['unread_count'].toString());

    if (count == null || count < 0) {
      throw const FormatException('عدد الإشعارات غير صالح.');
    }

    return count;
  }

  Future<void> markAsRead(String notificationId) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse(
            '${ApiConfig.baseUrl}/notifications/'
            '${Uri.encodeComponent(notificationId)}/read',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        )
        .timeout(_timeout);

    _decodeResponse(response);
  }

  Future<void> markAllAsRead() async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        )
        .timeout(_timeout);

    _decodeResponse(response);
  }
}
