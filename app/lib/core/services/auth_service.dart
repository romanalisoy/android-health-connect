import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthResult {
  final bool success;
  final String message;

  AuthResult(this.success, this.message);
}

/// User information from /api/v1/auth/me
class UserInfo {
  final String? id;
  final String? fullName;
  final String? email;
  final String? profilePicture;
  final DateTime? birthdate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserInfo({
    this.id,
    this.fullName,
    this.email,
    this.profilePicture,
    this.birthdate,
    this.createdAt,
    this.updatedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      fullName: json['full_name'] ?? json['fullName'],
      email: json['email'],
      profilePicture: json['profile_picture'] ?? json['profilePicture'],
      birthdate: json['birthdate'] != null ? DateTime.tryParse(json['birthdate']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  /// Get initials from full name for avatar placeholder
  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Get full profile picture URL with base URL prefix
  String? getFullProfilePictureUrl(String? baseUrl) {
    if (profilePicture == null || profilePicture!.isEmpty) return null;
    // If already a full URL, return as is
    if (profilePicture!.startsWith('http://') || profilePicture!.startsWith('https://')) {
      return profilePicture;
    }
    // Otherwise prepend base URL
    if (baseUrl == null) return profilePicture;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = profilePicture!.startsWith('/') ? profilePicture! : '/$profilePicture';
    return '$cleanBaseUrl$cleanPath';
  }
}

/// Weather information from /api/v1/weather
class WeatherInfo {
  final String city;
  final String weather;
  final String temperature;
  final String iconUrl;

  WeatherInfo({
    required this.city,
    required this.weather,
    required this.temperature,
    required this.iconUrl,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      city: json['city'] ?? 'Unknown',
      weather: json['weather'] ?? 'Unknown',
      temperature: json['temperature'] ?? '--°',
      iconUrl: json['icon'] ?? '',
    );
  }
}

class AuthService {
  static const String _keyBaseUrl = 'base_url';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Cached user info (persists until app closes)
  UserInfo? _cachedUserInfo;

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

  /// Get user info from /api/v1/auth/me
  /// Returns cached info if available, otherwise fetches from server
  Future<UserInfo?> getUserInfo({bool forceRefresh = false}) async {
    // Return cached info if available and not forcing refresh
    if (_cachedUserInfo != null && !forceRefresh) {
      return _cachedUserInfo;
    }

    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();
      if (baseUrl == null || accessToken == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/auth/me');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Handle nested structure: { "success": true, "data": { ... } }
        final userData = data['data'] ?? data;
        _cachedUserInfo = UserInfo.fromJson(userData);
        return _cachedUserInfo;
      }

      // Try refresh token if 401
      if (response.statusCode == 401) {
        final newToken = await refreshToken();
        if (newToken != null) {
          return getUserInfo(forceRefresh: true);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear cached user info (call on logout)
  void clearUserCache() {
    _cachedUserInfo = null;
  }

  /// Get weather from /api/v1/weather
  /// Requires latitude and longitude
  Future<WeatherInfo?> getWeather(double lat, double lon) async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();
      if (baseUrl == null || accessToken == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/weather');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'lat': lat, 'lon': lon}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Handle nested structure: { "success": true, "data": { ... } }
        final weatherData = data['data'] ?? data;
        return WeatherInfo.fromJson(weatherData);
      }

      // Try refresh token if 401
      if (response.statusCode == 401) {
        final newToken = await refreshToken();
        if (newToken != null) {
          return getWeather(lat, lon);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Change password
  /// PUT /api/v1/auth/change-password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();

      if (baseUrl == null) return AuthResult(false, 'Host URL not set');
      if (accessToken == null) return AuthResult(false, 'Not authenticated');

      final uri = Uri.parse('$baseUrl/api/v1/auth/change-password');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'password_confirmation': passwordConfirmation,
        }),
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return AuthResult(false, 'Server returned invalid format: ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final msg = data['message']?.toString() ?? 'Password changed successfully';
        return AuthResult(true, msg);
      } else {
        // Try refresh token if 401
        if (response.statusCode == 401) {
          final newToken = await refreshToken();
          if (newToken != null) {
            return changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
              passwordConfirmation: passwordConfirmation,
            );
          }
        }
        final msg = data['message']?.toString() ?? 'Failed to change password: ${response.statusCode}';
        return AuthResult(false, msg);
      }
    } catch (e) {
      return AuthResult(false, 'Connection error: $e');
    }
  }

  /// Update profile information
  /// PUT /api/v1/auth/me
  Future<AuthResult> updateProfile({
    required String fullName,
    required String email,
    String? birthdate,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();

      if (baseUrl == null) return AuthResult(false, 'Host URL not set');
      if (accessToken == null) return AuthResult(false, 'Not authenticated');

      final uri = Uri.parse('$baseUrl/api/v1/auth/me');
      final body = <String, dynamic>{
        'full_name': fullName,
        'email': email,
      };
      if (birthdate != null) {
        body['birthdate'] = birthdate;
      }

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return AuthResult(false, 'Server returned invalid format: ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Clear cached user info to force refresh
        _cachedUserInfo = null;
        final msg = data['message']?.toString() ?? 'Profile updated successfully';
        return AuthResult(true, msg);
      } else {
        // Try refresh token if 401
        if (response.statusCode == 401) {
          final newToken = await refreshToken();
          if (newToken != null) {
            return updateProfile(
              fullName: fullName,
              email: email,
              birthdate: birthdate,
            );
          }
        }
        final msg = data['message']?.toString() ?? 'Failed to update profile: ${response.statusCode}';
        return AuthResult(false, msg);
      }
    } catch (e) {
      return AuthResult(false, 'Connection error: $e');
    }
  }

  /// Upload profile picture
  /// POST /api/v1/auth/profile-picture (multipart/form-data)
  Future<AuthResult> uploadProfilePicture(String filePath) async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();

      if (baseUrl == null) return AuthResult(false, 'Host URL not set');
      if (accessToken == null) return AuthResult(false, 'Not authenticated');

      final uri = Uri.parse('$baseUrl/api/v1/auth/profile-picture');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $accessToken';

      // Determine MIME type from file extension
      final extension = filePath.split('.').last.toLowerCase();
      MediaType? contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'gif':
          contentType = MediaType('image', 'gif');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        filePath,
        contentType: contentType,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return AuthResult(false, 'Server returned invalid format: ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Clear cached user info to force refresh
        _cachedUserInfo = null;
        final msg = data['message']?.toString() ?? 'Profile picture updated';
        return AuthResult(true, msg);
      } else {
        // Try refresh token if 401
        if (response.statusCode == 401) {
          final newToken = await refreshToken();
          if (newToken != null) {
            return uploadProfilePicture(filePath);
          }
        }
        final msg = data['message']?.toString() ?? 'Failed to upload picture: ${response.statusCode}';
        return AuthResult(false, msg);
      }
    } catch (e) {
      return AuthResult(false, 'Connection error: $e');
    }
  }

  /// Get body stats
  /// GET /api/v1/body-stats/latest
  Future<BodyStats?> getBodyStats() async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();

      if (baseUrl == null) return null;
      if (accessToken == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/body-stats/latest'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        print('DEBUG getBodyStats response: ${response.body}');
        // Handle both direct object and nested data object
        final statsData = data['data'] ?? data;
        print('DEBUG statsData: $statsData');
        final bodyStats = BodyStats.fromJson(statsData);
        print('DEBUG parsed weight: ${bodyStats.weight}, height: ${bodyStats.height}');
        return bodyStats;
      } else if (response.statusCode == 401) {
        final newToken = await refreshToken();
        if (newToken != null) {
          return getBodyStats();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching body stats: $e');
      return null;
    }
  }

  /// Update body stats
  /// PUT /api/v1/body-stats
  Future<AuthResult> updateBodyStats(Map<String, double> data) async {
    try {
      final baseUrl = await getBaseUrl();
      final accessToken = await getAccessToken();

      if (baseUrl == null) return AuthResult(false, 'Host URL not set');
      if (accessToken == null) return AuthResult(false, 'Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/body-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final msg = responseData['message']?.toString() ?? 'Body stats updated';
        return AuthResult(true, msg);
      } else if (response.statusCode == 401) {
        final newToken = await refreshToken();
        if (newToken != null) {
          return updateBodyStats(data);
        }
        return AuthResult(false, 'Session expired');
      } else {
        final msg = responseData['message']?.toString() ?? 'Failed to update body stats';
        return AuthResult(false, msg);
      }
    } catch (e) {
      return AuthResult(false, 'Connection error: $e');
    }
  }
}

/// Body Stats data model
class BodyStats {
  final double? weight;
  final double? height;
  final double? neck;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulders;
  final double? rightBicep;
  final double? leftBicep;
  final double? rightForearm;
  final double? leftForearm;
  final double? rightThigh;
  final double? leftThigh;
  final double? rightCalve;
  final double? leftCalve;
  final DateTime? updatedAt;

  BodyStats({
    this.weight,
    this.height,
    this.neck,
    this.chest,
    this.waist,
    this.hips,
    this.shoulders,
    this.rightBicep,
    this.leftBicep,
    this.rightForearm,
    this.leftForearm,
    this.rightThigh,
    this.leftThigh,
    this.rightCalve,
    this.leftCalve,
    this.updatedAt,
  });

  factory BodyStats.fromJson(Map<String, dynamic> json) {
    return BodyStats(
      weight: _parseNestedValue(json['weight']),
      height: _parseNestedValue(json['height']),
      neck: _parseNestedValue(json['neck']),
      chest: _parseNestedValue(json['chest']),
      waist: _parseNestedValue(json['waist']),
      hips: _parseNestedValue(json['hips']),
      shoulders: _parseNestedValue(json['shoulders']),
      rightBicep: _parseNestedValue(json['right_arm'] ?? json['right_bicep'] ?? json['rightBicep']),
      leftBicep: _parseNestedValue(json['left_arm'] ?? json['left_bicep'] ?? json['leftBicep']),
      rightForearm: _parseNestedValue(json['right_forearm'] ?? json['rightForearm']),
      leftForearm: _parseNestedValue(json['left_forearm'] ?? json['leftForearm']),
      rightThigh: _parseNestedValue(json['right_thigh'] ?? json['rightThigh']),
      leftThigh: _parseNestedValue(json['left_thigh'] ?? json['leftThigh']),
      rightCalve: _parseNestedValue(json['right_calve'] ?? json['rightCalve']),
      leftCalve: _parseNestedValue(json['left_calve'] ?? json['leftCalve']),
      updatedAt: _parseRecordDate(json),
    );
  }

  /// Parse nested value from {value: X, record_date: Y} or direct value
  static double? _parseNestedValue(dynamic field) {
    if (field == null) return null;
    // If it's a Map with 'value' key (nested structure)
    if (field is Map) {
      final value = field['value'];
      return _parseDouble(value);
    }
    // Direct value (fallback for simple structure)
    return _parseDouble(field);
  }

  /// Parse record_date from any field that has it
  static DateTime? _parseRecordDate(Map<String, dynamic> json) {
    // Try to find record_date from any field
    for (final field in json.values) {
      if (field is Map && field['record_date'] != null) {
        return DateTime.tryParse(field['record_date'].toString());
      }
    }
    // Fallback to updated_at
    if (json['updated_at'] != null) {
      return DateTime.tryParse(json['updated_at'].toString());
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Calculate BMI from weight (kg) and height (cm)
  double? get bmi {
    if (weight == null || height == null || height == 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return '-';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}
