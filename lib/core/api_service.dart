import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // ============== BASE URL CONFIGURATION ==============
  // Automatically selects correct URL based on platform
  static String get baseUrl {
  const backendIP = '10.54.16.25:8000';   // <---- YOUR WORKING IP

  if (kIsWeb) {
    // Flutter Web uses browser → needs direct IP
    return 'http://$backendIP';
  } else if (Platform.isAndroid) {
    // Physical Android device → also uses direct IP
    return 'http://$backendIP';
  } else if (Platform.isIOS) {
    // Physical iPhone → same LAN IP
    return 'http://$backendIP';
  }

  // Default (Windows/Linux desktop)
  return 'http://$backendIP';
}

  static const String apiVersion = '/api/v1';

  // ============== TOKEN MANAGEMENT ==============
  static String? _accessToken;
  static String? _refreshToken;

  static Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static bool get isLoggedIn => _accessToken != null;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ============== HTTP HELPERS ==============
  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response) async {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else if (response.statusCode == 401) {
      // Try refresh token
      final refreshed = await _refreshTokens();
      if (!refreshed) {
        await clearTokens();
      }
      return {'success': false, 'error': data['detail'] ?? 'Unauthorized'};
    } else {
      return {
        'success': false,
        'error': data['detail'] ?? 'Something went wrong'
      };
    }
  }

  static Future<bool> _refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  // ============== AUTH ENDPOINTS ==============

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          if (gender != null) 'gender': gender,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Verify OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final result = await _handleResponse(response);
      if (result['success'] && result['data'] != null) {
        await _saveTokens(
          result['data']['access_token'],
          result['data']['refresh_token'],
        );
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Resend OTP
  static Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  try {
    print('Attempting login to: $baseUrl$apiVersion/auth/login'); // Add this
    
    final response = await http.post(
      Uri.parse('$baseUrl$apiVersion/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10)); // Add timeout

    print('Response: ${response.statusCode}'); // Add this


      final result = await _handleResponse(response);
      if (result['success'] && result['data'] != null) {
        await _saveTokens(
          result['data']['access_token'],
          result['data']['refresh_token'],
        );
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/logout'),
        headers: _headers,
      );
      await clearTokens();
      return {'success': true, 'data': {'message': 'Logged out'}};
    } catch (e) {
      await clearTokens();
      return {'success': true, 'data': {'message': 'Logged out'}};
    }
  }

  /// Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(
      {required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Reset Password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl$apiVersion/auth/reset-password?email=$email&otp=$otp&new_password=$newPassword'),
        headers: {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ============== USER ENDPOINTS ==============

  /// Get current user
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/users/me'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (gender != null) body['gender'] = gender;

      final response = await http.patch(
        Uri.parse('$baseUrl$apiVersion/users/me'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get user profile with stats
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/users/profile'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get user dashboard
  static Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/users/dashboard'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ============== TEST ENDPOINTS ==============

  /// Get test dashboard
  static Future<Map<String, dynamic>> getTestDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/tests/dashboard'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Create test session
  static Future<Map<String, dynamic>> createTestSession(
      {required String category}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/tests/'),
        headers: _headers,
        body: jsonEncode({'category': category}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// List test sessions
  static Future<Map<String, dynamic>> listTestSessions({
    String? category,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (category != null) 'category': category,
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$baseUrl$apiVersion/tests/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get test session details
  static Future<Map<String, dynamic>> getTestSession(
      {required int sessionId}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/tests/$sessionId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Start test session
  static Future<Map<String, dynamic>> startTestSession(
      {required int sessionId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/tests/$sessionId/start'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Add test item (single)
  static Future<Map<String, dynamic>> addTestItem({
    required int sessionId,
    required String itemName,
    String? itemType,
    required Map<String, dynamic> rawData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/tests/$sessionId/items'),
        headers: _headers,
        body: jsonEncode({
          'item_name': itemName,
          if (itemType != null) 'item_type': itemType,
          'raw_data': rawData,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Add test items (batch)
  static Future<Map<String, dynamic>> addTestItemsBatch({
    required int sessionId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/tests/$sessionId/items/batch'),
        headers: _headers,
        body: jsonEncode({'items': items}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Complete test session (triggers ML processing)
  static Future<Map<String, dynamic>> completeTestSession(
      {required int sessionId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/tests/$sessionId/complete'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Cancel test session
  static Future<Map<String, dynamic>> cancelTestSession(
      {required int sessionId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$apiVersion/tests/$sessionId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ============== WELLNESS ENDPOINTS ==============

  /// Get wellness dashboard
  static Future<Map<String, dynamic>> getWellnessDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/wellness/dashboard'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Create wellness entry
  static Future<Map<String, dynamic>> createWellnessEntry({
    double? sleepHours,
    String? sleepQuality,
    double? screenTimeHours,
    double? gamingHours,
    int? stressLevel,
    String? mood,
    int? anxietyLevel,
    int? physicalActivityMinutes,
    String? exerciseType,
    int? waterIntakeGlasses,
    String? notes,
    String? entryDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (sleepHours != null) body['sleep_hours'] = sleepHours;
      if (sleepQuality != null) body['sleep_quality'] = sleepQuality;
      if (screenTimeHours != null) body['screen_time_hours'] = screenTimeHours;
      if (gamingHours != null) body['gaming_hours'] = gamingHours;
      if (stressLevel != null) body['stress_level'] = stressLevel;
      if (mood != null) body['mood'] = mood;
      if (anxietyLevel != null) body['anxiety_level'] = anxietyLevel;
      if (physicalActivityMinutes != null)
        body['physical_activity_minutes'] = physicalActivityMinutes;
      if (exerciseType != null) body['exercise_type'] = exerciseType;
      if (waterIntakeGlasses != null)
        body['water_intake_glasses'] = waterIntakeGlasses;
      if (notes != null) body['notes'] = notes;
      if (entryDate != null) body['entry_date'] = entryDate;

      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/wellness/data'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get wellness history
  static Future<Map<String, dynamic>> getWellnessHistory({
    int days = 30,
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl$apiVersion/wellness/history?days=$days&limit=$limit'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get today's wellness entry
  static Future<Map<String, dynamic>> getTodayWellness() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/wellness/today'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Update wellness entry
  static Future<Map<String, dynamic>> updateWellnessEntry({
    required int entryId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$apiVersion/wellness/$entryId'),
        headers: _headers,
        body: jsonEncode(data ?? {}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ============== REPORT ENDPOINTS ==============

  /// List reports
  static Future<Map<String, dynamic>> listReports({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/reports/?limit=$limit&offset=$offset'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Create report
  static Future<Map<String, dynamic>> createReport({
    String? title,
    String reportType = 'comprehensive',
    List<int>? sessionIds,
    String? category,
    String? dateRangeStart,
    String? dateRangeEnd,
    bool includeWellness = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'report_type': reportType,
        'include_wellness': includeWellness,
      };
      if (title != null) body['title'] = title;
      if (sessionIds != null) body['session_ids'] = sessionIds;
      if (category != null) body['category'] = category;
      if (dateRangeStart != null) body['date_range_start'] = dateRangeStart;
      if (dateRangeEnd != null) body['date_range_end'] = dateRangeEnd;

      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/reports/'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get report details
  static Future<Map<String, dynamic>> getReport({required int reportId}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/reports/$reportId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get report download URL
  static String getReportDownloadUrl({required int reportId}) {
    return '$baseUrl$apiVersion/reports/$reportId/download';
  }

  /// Delete report
  static Future<Map<String, dynamic>> deleteReport(
      {required int reportId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$apiVersion/reports/$reportId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ============== PROFILE IMAGE ENDPOINTS ==============

  /// Upload profile image - Works on Web and Mobile
  static Future<Map<String, dynamic>> uploadProfileImage(Uint8List bytes, String fileName) async {
    try {
      final uri = Uri.parse('$baseUrl$apiVersion/users/profile-image');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $_accessToken';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['detail'] ?? 'Upload failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Upload error: $e'};
    }
  }

  /// Remove profile image
  static Future<Map<String, dynamic>> removeProfileImage() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$apiVersion/users/profile-image'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ============== HEALTH CHECK ==============

  /// Check API health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============== FEEDBACK ENDPOINTS ==============

  /// Submit feedback
  static Future<Map<String, dynamic>> submitFeedback({
    required String category,
    required String message,
    int? rating,
    String? appVersion,
    String? deviceInfo,
  }) async {
    try {
      final body = <String, dynamic>{
        'category': category,
        'message': message,
      };
      if (rating != null) body['rating'] = rating;
      if (appVersion != null) body['app_version'] = appVersion;
      if (deviceInfo != null) body['device_info'] = deviceInfo;

      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/feedback/'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get user's feedbacks
  static Future<Map<String, dynamic>> getMyFeedbacks({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/feedback/my-feedbacks?page=$page&per_page=$perPage'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Delete feedback
  static Future<Map<String, dynamic>> deleteFeedback({required int feedbackId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$apiVersion/feedback/$feedbackId'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }
}