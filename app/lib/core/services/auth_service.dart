import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthResult {
  final bool success;
  final String message;
  
  AuthResult(this.success, this.message);
}

class AuthService {
  static const String _keyBaseUrl = 'base_url';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Save Base URL selected by user
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Ensure no trailing slash
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await prefs.setString(_keyBaseUrl, cleanUrl);
  }

  Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl);
  }

  /// Login with email and password
  Future<AuthResult> login(String email, String password) async {
    try {
      final baseUrl = await getBaseUrl();
      if (baseUrl == null) return AuthResult(false, 'Host URL not set');

      final uri = Uri.parse('$baseUrl/api/v1/auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // Try to parse JSON response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        // If response is not JSON
        return AuthResult(false, 'Server returned invalid format: ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success: Parse nested structure
        // Expected: { "success": true, "message": "...", "data": { "tokens": { "accessToken": "...", ... } } }
        try {
          final tokens = data['data']['tokens'];
          final accessToken = tokens['accessToken'];
          final refreshToken = tokens['refreshToken'];

          if (accessToken != null && refreshToken != null) {
            await _saveTokens(accessToken, refreshToken);
            final msg = data['message']?.toString() ?? 'Login successful';
            return AuthResult(true, msg);
          } else {
            return AuthResult(false, 'Tokens missing in server response');
          }
        } catch (e) {
          return AuthResult(false, 'Invalid response structure');
        }
      } else {
        // Error: Use server provided message if available
        // Expected: { "success": false, "message": "Invalid email...", ... }
        final msg = data['message']?.toString() ?? 'Login failed: ${response.statusCode}';
        return AuthResult(false, msg);
      }
    } catch (e) {
      return AuthResult(false, 'Connection error: $e');
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }

  /// Check if user has stored tokens
  Future<bool> hasTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    return accessToken != null && refreshToken != null;
  }

  /// Verify token by calling /api/v1/auth/me
  Future<bool> verifyToken() async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();
      if (baseUrl == null || accessToken == null) return false;

      final uri = Uri.parse('$baseUrl/api/v1/auth/me');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      if (response.statusCode == 401) {
        final newToken = await refreshToken();
        return newToken != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get FCM token and submit to server
  Future<AuthResult> submitFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return AuthResult(false, 'Failed to retrieve FCM token from device');

      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();

      if (baseUrl == null) return AuthResult(false, 'Base URL not set');
      if (accessToken == null) return AuthResult(false, 'Access Token not found');

      final uri = Uri.parse('$baseUrl/api/v1/auth/fcm-token');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
         try {
            final data = jsonDecode(response.body);
            final msg = data['message']?.toString() ?? 'FCM Token updated';
            return AuthResult(true, msg);
         } catch (_) {
            return AuthResult(true, 'FCM Token updated (No JSON response)');
         }
      } else {
         try {
            final data = jsonDecode(response.body);
            final msg = data['message']?.toString() ?? 'FCM Update failed: ${response.statusCode}';
            return AuthResult(false, msg);
         } catch (_) {
            return AuthResult(false, 'FCM Update failed: ${response.statusCode}');
         }
      }
    } catch (e) {
      return AuthResult(false, 'FCM Connection error: $e');
    }
  }

  /// Refresh Access Token
  /// Returns new access token or null if failed
  Future<String?> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString(_keyBaseUrl);
      final refreshToken = prefs.getString(_keyRefreshToken);

      if (baseUrl == null || refreshToken == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/auth/refresh-token');
      final response = await http.post(
         uri,
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode({'refreshToken': refreshToken}),
      );

       if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Assuming similar structure for refresh token response: data -> tokens or just data?
        // Usually refresh endpoints return similar structure. 
        // Based on user input, success pattern is standard wrapped in 'data'.
        // Let's try to handle both flat and nested for robustness or stick to nested if confident.
        // Given login response is nested, likely refresh is too.
        String? newAccessToken;
        String? newRefreshToken;

        if (data.containsKey('data') && data['data'] is Map) {
             final tokens = data['data']['tokens'] ?? data['data']; // Handle if tokens is direct or nested in tokens
             newAccessToken = tokens['accessToken'];
             newRefreshToken = tokens['refreshToken'];
        } else {
             // Fallback to flat
             newAccessToken = data['accessToken'];
             newRefreshToken = data['refreshToken'];
        }

        if (newAccessToken != null) {
          await prefs.setString(_keyAccessToken, newAccessToken);
          if (newRefreshToken != null) {
            await prefs.setString(_keyRefreshToken, newRefreshToken);
          }
          return newAccessToken;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
