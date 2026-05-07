import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

import '../config/env_config.dart';

const Duration _authRequestTimeout = Duration(seconds: 20);

class AuthService {
  static final String baseUrl = EnvConfig.authUrl;
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password, {bool persistSession = true}) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_authRequestTimeout);
    } on TimeoutException {
      throw Exception('Login request timed out. Please try again.');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (persistSession) {
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'user', value: jsonEncode(data['user']));
      } else {
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'user');
      }
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  Future<User?> register(String fullName, String email, String password) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
              'role': 'customer'
            }),
          )
          .timeout(_authRequestTimeout);
    } on TimeoutException {
      throw Exception('Registration request timed out. Please try again.');
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }

  Future<void> saveUserMap(Map<String, dynamic> user) async {
    await _storage.write(key: 'user', value: jsonEncode(user));
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> getSavedUserMap() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userJson) as Map);
  }

  Future<User?> getSavedUser() async {
    final map = await getSavedUserMap();
    if (map == null) return null;
    return User.fromJson(map);
  }

  /// Storefront profile (requires customer JWT).
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    late final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${EnvConfig.baseUrl}/users/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_authRequestTimeout);
    } on TimeoutException {
      throw Exception('Profile request timed out. Please try again.');
    }
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_readApiError(response.body));
  }

  Future<Map<String, dynamic>> updateProfile(
    String token, {
    required String fullName,
    String? phone,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .patch(
            Uri.parse('${EnvConfig.baseUrl}/users/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'full_name': fullName,
              if (phone != null) 'phone': phone,
            }),
          )
          .timeout(_authRequestTimeout);
    } on TimeoutException {
      throw Exception('Profile update timed out. Please try again.');
    }
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_readApiError(response.body));
  }
}

String _readApiError(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['message'] ?? decoded['error'] ?? decoded['detail'] ?? body).toString();
    }
  } catch (_) {}
  return body;
}
