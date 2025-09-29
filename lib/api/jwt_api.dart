// ไฟล์: lib/api/jwt_api.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medication_reminder_system/config/api_config.dart';

/// คลาสสำหรับจัดการ API calls ที่เกี่ยวข้องกับ JWT Authentication
class JWTApi {
  
  /// Refresh JWT Token ผ่าน API
static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
  try {
    final requestData = {'refresh_token': refreshToken};

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $refreshToken',
    };

    debugPrint('🔄 Refresh Token Request URL: ${ApiConfig.refreshTokenUrl}');
    debugPrint('🔄 Refresh Token Request Data: $requestData');

    final response = await http.post(
      Uri.parse(ApiConfig.refreshTokenUrl),
      headers: headers,
      body: jsonEncode(requestData),
    ).timeout(ApiConfig.authTimeout);
    
    debugPrint('🔄 Refresh Token Response Status: ${response.statusCode}');
    debugPrint('🔄 Refresh Token Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      debugPrint('🔄 Parsed Result: $result');
      
        // ส่ง response ตามที่ jwt_manager.dart คาดหวัง
        return {
          'success': result['status'] == 'success' || result['success'] == true,
          'status': result['status'],
          'message': result['message'],
          'data': result['data'],
          'auto_login_status': result['auto_login_status'],
          'require_login': result['require_login'],
          // สำหรับ format เก่า
          'token': result['token'],
          'user_data': result['user_data'],
        };
      } else {
        // พยายาม parse error response
        try {
          final errorResult = jsonDecode(response.body);
          return {
            'success': false,
            'status': 'error',
            'message': errorResult['message'] ?? 'HTTP Error: ${response.statusCode}',
            'require_login': errorResult['require_login'] ?? true,
            'auto_login_status': errorResult['auto_login_status'] ?? 'failed',
          };
        } catch (e) {
          return {
            'success': false,
            'status': 'error',
            'message': 'HTTP Error: ${response.statusCode}',
            'require_login': true,
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Refresh token API error: $e');
      
      String errorMessage = 'Network error';
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Connection error';
      }
      
      return {
        'success': false,
        'status': 'error',
        'message': errorMessage,
        'network_error': true,
      };
    }
  }

}