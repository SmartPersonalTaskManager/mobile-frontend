import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sptm/models/mission.dart';
import 'package:sptm/services/api_service.dart';

class MissionServiceException implements Exception {
  final String message;

  const MissionServiceException(this.message);

  @override
  String toString() => message;
}

class MissionService {
  final ApiService _apiService;

  MissionService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<Mission>> fetchUserMissions(int userId) async {
    final response = await _apiService.get('/missions/user/$userId');
    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .map((item) => Mission.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw MissionServiceException(_errorMessage(response));
  }

  Future<Mission> createMission(int userId, String content) async {
    final response = await _apiService.post(
      '/missions?userId=$userId',
      body: content,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Mission.fromJson(payload);
    }

    throw MissionServiceException(_errorMessage(response));
  }

  Future<Mission> updateMission(int missionId, String content) async {
    final response = await _apiService.put(
      '/missions/$missionId',
      body: content,
    );
    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return Mission.fromJson(payload);
    }

    throw MissionServiceException(_errorMessage(response));
  }

  Future<void> deleteMission(int missionId) async {
    final response = await _apiService.delete('/missions/$missionId');
    if (response.statusCode == 204) {
      return;
    }

    throw MissionServiceException(_errorMessage(response));
  }

  Future<SubMission> addSubMission(
    int missionId,
    String title,
    String description,
  ) async {
    final response = await _apiService.post(
      '/missions/$missionId/submissions',
      body: {'title': title, 'description': description},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return SubMission.fromJson(payload);
    }

    throw MissionServiceException(_errorMessage(response));
  }

  Future<void> deleteSubMission(int subMissionId) async {
    final response = await _apiService.delete(
      '/missions/submissions/$subMissionId',
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    if (response.statusCode == 403) {
      throw const MissionServiceException(
        'Cannot delete a sub-mission with linked tasks.',
      );
    }

    throw MissionServiceException(_errorMessage(response));
  }

  Future<void> updateSubMission(int subMissionId, String title) async {
    final response = await _apiService.put(
      '/missions/submissions/$subMissionId',
      body: title,
    );
    if (response.statusCode == 200) {
      return;
    }

    throw MissionServiceException(_errorMessage(response));
  }

  String _errorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Request failed. (${response.statusCode})';
    }
    return response.body;
  }
}
