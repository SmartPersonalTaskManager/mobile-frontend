import 'dart:convert';

import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/api_service.dart';

class TaskService {
  final ApiService _api = ApiService();

  Future<List<TaskItem>> getTasks(int userId) async {
    final response = await _api.get('/tasks/user/$userId', requiresAuth: true);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as List<dynamic>;
      return body.map((json) => TaskItem.fromJson(json)).toList();
    } else {
      throw ApiException("Failed to fetch tasks");
    }
  }

  Future<TaskItem> createTask({
    required String title,
    required int userId,
    String? description,
    String?
    mission, // This might need to be IDs in real app, assuming name or ID string for now
    String? context,
    DateTime? dueDate,
    bool urgent = false,
    bool important = false,
  }) async {
    String priorityVal;
    if (urgent && important) {
      priorityVal = "URGENT_IMPORTANT";
    } else if (!urgent && important) {
      priorityVal = "NOT_URGENT_IMPORTANT";
    } else if (urgent && !important) {
      priorityVal = "URGENT_NOT_IMPORTANT";
    } else {
      priorityVal = "NOT_URGENT_NOT_IMPORTANT";
    }

    final body = {
      'title': title,
      'description': description,
      'userId': userId,
      'isArchived': false,
      'isInbox': true,
      'priority': priorityVal,
      'status': 'NOT_STARTED',
      'dueDate': dueDate?.toIso8601String(),
      'context': context,
      // 'subMissionId': ... if we had ID
      // For now, depending on backend DTO, if it takes mixed fields.
      // If backend only takes subMissionId, we can't send name.
      // Assuming backend might ignore it or we need to resolve it.
      // We'll leave mission out of body if backend doesn't support "missionName".
    };

    final response = await _api.post('/tasks', body: body, requiresAuth: true);
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return TaskItem.fromJson(responseBody);
    } else {
      throw ApiException("Failed to create task");
    }
  }

  Future<TaskItem> updateTask(TaskItem task) async {
    final response = await _api.put('/tasks/${task.id}', body: task.toJson());
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return TaskItem.fromJson(body);
    } else {
      throw ApiException("Failed to update task");
    }
  }

  Future<void> deleteTask(int taskId) async {
    await _api.delete('/tasks/$taskId');
  }
}
