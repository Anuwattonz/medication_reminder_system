import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medication_reminder_system/jwt/jwt_manager.dart';
import 'package:medication_reminder_system/config/api_config.dart';

class LoginApi {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Login API: calling with $email');

      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(ApiConfig.authTimeout);

      final res = jsonDecode(response.body);
      debugPrint('📥 Login response: ${response.statusCode} - ${res['status']}');

      if (response.statusCode == 200 && res['status'] == 'success') {
        final processedData = await _processSecureLoginData(res);
        return {
          'success': true,
          'data': processedData,
          'message': 'เข้าสู่ระบบสำเร็จ',
        };
      } else {
        return {
          'success': false,
          'message': res['message'] ?? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> _processSecureLoginData(Map<String, dynamic> res) async {
    try {
      await JWTManager.clearAll();

      final data = res['data'] ?? res;
      final jwtToken = data['token'];
      final refreshToken = data['refresh_token'];

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('ไม่พบ JWT Token จากเซิร์ฟเวอร์');
      }

      await JWTManager.saveToken(jwtToken);
      if (refreshToken?.isNotEmpty == true) {
        await JWTManager.saveRefreshToken(refreshToken);
      }

      await _clearLogoutFlag();
      final session = await JWTManager.getCurrentSession();
      if (session == null) throw Exception('ไม่สามารถสร้าง session จาก JWT token ได้');

      final connections = _resolveConnections(data, session);
      final hasConnection = connections.isNotEmpty;

      return {
        'user': {
          'user_id': session.userId,
          'user': session.username,
        },
        'connections': connections,
        'hasConnection': hasConnection,
        'jwtToken': jwtToken,
        'refreshToken': refreshToken,
      };
    } catch (e) {
      await JWTManager.clearAll();
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _resolveConnections(Map<String, dynamic> data, session) {
    List<Map<String, dynamic>> connections = [];

    if (data['has_connection'] == true && data['connections'] != null) {
      connections = List<Map<String, dynamic>>.from(
        (data['connections'] as List).map((conn) => {
          'connect_id': conn['connect_id'],
          'user_id': conn['user_id'],
        }),
      );
    }

    if (session.hasConnection && session.connectionId != null) {
      return [{
        'connect_id': session.connectionId,
        'user_id': session.userId,
      }];
    }

    return connections;
  }

  static Future<void> _clearLogoutFlag() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'user_logged_out');
    } catch (_) {}
  }

  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  static Future<String> createWelcomeMessage(Map<String, dynamic> userData) async {
    return 'เข้าสู่ระบบสำเร็จ';
  }

  static bool isNetworkError(Map<String, dynamic> result) {
    if (result['success'] == false) {
      final message = result['message']?.toString().toLowerCase() ?? '';
      return message.contains('เชื่อมต่อ') ||
             message.contains('network') ||
             message.contains('timeout') ||
             message.contains('connection') ||
             message.contains('server');
    }
    return false;
  }

  static Future<Map<String, dynamic>> retryLogin({
    required String email,
    required String password,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await login(email: email, password: password);
      if (result['success'] == true) return result;

      if (!isNetworkError(result)) return result;
      if (attempt < maxRetries) await Future.delayed(Duration(seconds: attempt));
    }

    return {
      'success': false,
      'message': 'การเข้าสู่ระบบล้มเหลวหลังจากลองหลายครั้ง',
    };
  }

  static void debugApiResponse(String apiName, Map<String, dynamic> result) {
    debugPrint('🔍 $apiName: ${result['success']} - ${result['message']}');
    final data = result['data'] as Map<String, dynamic>?;
    if (data != null) {
      debugPrint('🔍 Data keys: ${data.keys.toList()}');
      debugPrint('🔍 User: ${data['user']}');
      debugPrint('🔍 Has Connection: ${data['hasConnection']}');
    }
  }
}
