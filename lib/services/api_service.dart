import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sptm/core/constants.dart';
import 'package:sptm/services/auth_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
}

class ApiService {
  final http.Client _client;
  final AuthStorage _authStorage;

  ApiService({http.Client? client, AuthStorage? authStorage})
    : _client = client ?? http.Client(),
      _authStorage = authStorage ?? AuthStorage();

  Future<http.Response> get(
    String path, {
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) {
    return _request('GET', path, requiresAuth: requiresAuth, headers: headers);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) {
    return _request(
      'DELETE',
      path,
      body: body,
      requiresAuth: requiresAuth,
      headers: headers,
    );
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${AppStrings.apiBaseURL}$path');

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    if (requiresAuth) {
      final token = await _authStorage.readToken();
      if (token != null) {
        requestHeaders['Authorization'] = token.startsWith('Bearer ')
            ? token
            : 'Bearer $token';
      }
    }

    final response = await _client
        .send(
          http.Request(method, uri)
            ..headers.addAll(requestHeaders)
            ..body = body == null ? '' : jsonEncode(body),
        )
        .then(http.Response.fromStream);

    if (response.statusCode == 401) {
      await _authStorage.clearToken();
      throw const ApiException('Session expired.', statusCode: 401);
    }

    return response;
  }
}
