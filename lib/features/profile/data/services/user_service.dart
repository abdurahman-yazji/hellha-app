import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class UserService {
  Future<Map<String, dynamic>> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }

    return data['user'];
  }

  Future<Map<String, dynamic>> syncUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to sync user');
    }

    return data['user'];
  }
}
