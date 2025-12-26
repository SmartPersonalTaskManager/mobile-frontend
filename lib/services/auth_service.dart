import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/services/api_service.dart';
import 'package:sptm/services/auth_storage.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);
}

class AuthService {
  final ApiService _apiService;
  final AuthStorage _authStorage;

  AuthService({ApiService? apiService, AuthStorage? authStorage})
    : _apiService = apiService ?? ApiService(),
      _authStorage = authStorage ?? AuthStorage();

  Future<void> register(String name, String email, String passwd) async {
    final response = await _apiService.post(
      '/auth/register',
      requiresAuth: false,
      body: {"username": name, "email": email, "password": passwd},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    if (response.statusCode == 403) {
      throw const AuthException("Registration forbidden.");
    }

    final message = response.body.isNotEmpty
        ? response.body
        : "Registration failed. (${response.statusCode})";
    throw AuthException(message);
  }

  Future<void> login(String email, String passwd) async {
    final loginValue = email.trim();
    final payload = <String, String>{"email": loginValue, "password": passwd};

    final response = await _apiService.post(
      '/auth/login',
      requiresAuth: false,
      body: payload,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token =
          body['token'] as String? ??
          body['accessToken'] as String? ??
          body['access_token'] as String? ??
          body['jwt'] as String?;
      final id = body['id'] ?? body['userId'];
      if (token == null) {
        throw const AuthException('Invalid response from server.');
      }

      await _authStorage.saveToken(token);
      final prefs = await SharedPreferences.getInstance();
      if (id != null) {
        await prefs.setInt("userId", (id as num).toInt());
      }
      await prefs.setString("email", email);
      final username = body['username'] as String?;
      if (username != null && username.trim().isNotEmpty) {
        final trimmed = username.trim();
        await prefs.setString("username", trimmed);
        await prefs.setString("name", trimmed);
      }
      return;
    }

    if (response.statusCode == 403) {
      throw const AuthException('Invalid credentials.');
    }

    final message = response.body.isNotEmpty
        ? response.body
        : "Login failed. (${response.statusCode})";
    throw AuthException(message);
  }

  Future<void> logout() async {
    await _authStorage.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("userId");
  }

  Future<bool> requestPasswdReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return true;
  }

  Future<bool> resetPasswdWithCode(
    String email,
    String code,
    String newPasswd,
  ) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (code == '123456') return true;
    return false;
  }
}
