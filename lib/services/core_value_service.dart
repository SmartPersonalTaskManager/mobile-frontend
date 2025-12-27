import 'dart:convert';

import 'package:sptm/models/core_value.dart';
import 'package:sptm/services/api_service.dart';

class CoreValueService {
  final ApiService _api;

  CoreValueService({ApiService? apiService}) : _api = apiService ?? ApiService();

  Future<List<CoreValue>> fetchUserCoreValues(int userId) async {
    final response = await _api.get('/core-values/user/$userId');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List<dynamic>;
      return body
          .map((json) => CoreValue.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw ApiException("Failed to fetch core values");
  }

  Future<CoreValue> createCoreValue({
    required int userId,
    required String text,
  }) async {
    final response = await _api.post(
      '/core-values?userId=$userId',
      body: {'text': text},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return CoreValue.fromJson(body);
    }
    throw ApiException("Failed to create core value");
  }

  Future<CoreValue> updateCoreValue({
    required int id,
    required String text,
  }) async {
    final response = await _api.put(
      '/core-values/$id',
      body: {'text': text},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return CoreValue.fromJson(body);
    }
    throw ApiException("Failed to update core value");
  }

  Future<void> deleteCoreValue(int id) async {
    final response = await _api.delete('/core-values/$id');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw ApiException("Failed to delete core value");
  }
}
