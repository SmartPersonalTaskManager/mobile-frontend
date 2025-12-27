import 'dart:convert';

import 'package:sptm/models/context_tag.dart';
import 'package:sptm/services/api_service.dart';

class ContextService {
  final ApiService _api = ApiService();

  Future<List<ContextTag>> fetchUserContexts(int userId) async {
    final response = await _api.get(
      '/contexts/user/$userId',
      requiresAuth: true,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List<dynamic>;
      return body
          .map((json) => ContextTag.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw ApiException("Failed to fetch contexts");
  }

  Future<ContextTag> createContext({
    required int userId,
    required String name,
    String icon = "tag",
  }) async {
    final response = await _api.post(
      '/contexts?userId=$userId',
      body: {'name': name, 'icon': icon},
      requiresAuth: true,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ContextTag.fromJson(body);
    }
    throw ApiException("Failed to create context");
  }

  Future<void> deleteContext(int id) async {
    await _api.delete('/contexts/$id', requiresAuth: true);
  }
}
