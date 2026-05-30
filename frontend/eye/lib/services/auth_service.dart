import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // adb reverse tcp:8000 tcp:8000 tunnels device localhost to the PC backend.
  // All platforms (web, Android physical/emulator, desktop) can use localhost.
  static String get _baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      // Emulators use 10.0.2.2; physical devices use localhost via adb reverse.
      // Detect emulator by checking if it's a known emulator build.
      return 'http://localhost:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyPatientId = 'patient_id';
  static const _keyPatientName = 'patient_name';
  static const _keyPatientEmail = 'patient_email';

  /// Login with email + password. Returns patient name on success.
  /// Throws an [Exception] with the server's error detail on failure.
  static Future<String> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokens(data);
      return data['full_name'] as String? ?? 'Patient';
    }
    final detail = _extractDetail(response.body);
    throw Exception(detail);
  }

  /// Register a new account. Returns patient name on success.
  static Future<String> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokens(data);
      return data['full_name'] as String? ?? 'Patient';
    }
    final detail = _extractDetail(response.body);
    throw Exception(detail);
  }

  /// Logout — revokes the refresh token on the server and clears local storage.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_keyRefreshToken);
    if (refreshToken != null) {
      try {
        await http
            .post(
              Uri.parse('$_baseUrl/auth/logout'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': refreshToken}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Logout locally even if the server call fails.
      }
    }
    await _clearTokens(prefs);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken) != null;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPatientName);
  }

  static Future<String?> getPatientEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPatientEmail);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static Future<void> _saveTokens(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, data['access_token'] as String);
    await prefs.setString(_keyRefreshToken, data['refresh_token'] as String);
    await prefs.setString(_keyPatientId, data['patient_id'] as String);
    if (data['full_name'] != null) {
      await prefs.setString(_keyPatientName, data['full_name'] as String);
    }
    if (data['email'] != null) {
      await prefs.setString(_keyPatientEmail, data['email'] as String);
    }
  }

  static Future<void> _clearTokens(SharedPreferences prefs) async {
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyPatientId);
    await prefs.remove(_keyPatientName);
    await prefs.remove(_keyPatientEmail);
  }

  static String _extractDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['detail']?.toString() ?? 'An error occurred';
    } catch (_) {
      return 'An error occurred';
    }
  }
}
