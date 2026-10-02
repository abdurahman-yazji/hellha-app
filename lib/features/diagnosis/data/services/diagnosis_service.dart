import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellha/core/config/api_config.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/diagnosis_history_item.dart';
import '../../domain/models/diagnosis_result.dart';

class DiagnosisService {
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

  Future<DiagnosisResult> diagnoseIssue({
    required String description,
    String? category,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{'description': description.trim()};

    final normalizedCategory = category?.trim();

    if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
      body['category'] = normalizedCategory;
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/diagnoses'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response from diagnosis service');
    }

    if (response.statusCode != 200) {
      throw Exception(decodedBody['message'] ?? 'Failed to diagnose the issue');
    }

    final diagnosisData = decodedBody['diagnosis'];

    if (diagnosisData is! Map) {
      throw Exception('Diagnosis data was not returned');
    }

    final diagnosisJson = Map<String, dynamic>.from(diagnosisData);

    diagnosisJson['id'] = decodedBody['diagnosis_id'];
    diagnosisJson['created_at'] = decodedBody['created_at'];

    return DiagnosisResult.fromJson(diagnosisJson);
  }

  Future<List<DiagnosisHistoryItem>> getMyDiagnoses() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/diagnoses'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    final decodedBody = jsonDecode(response.body);

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Invalid response from diagnosis service');
    }

    if (response.statusCode != 200) {
      throw Exception(
        decodedBody['message'] ?? 'Failed to load diagnosis history',
      );
    }

    final diagnosesData = decodedBody['diagnoses'];

    if (diagnosesData is! List) {
      throw Exception('Diagnosis history was not returned');
    }

    return diagnosesData
        .map(
          (item) => DiagnosisHistoryItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
