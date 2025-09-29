import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:medication_reminder_system/config/api_config.dart';

class OtpApi {
  
  /// สร้าง OTP สำหรับอีเมลที่ระบุ
  static Future<Map<String, dynamic>> generateOTP({
    required String email,
  }) async {
    try {
      debugPrint('OTP API: Generating OTP for $email');
      debugPrint('OTP URL: ${ApiConfig.otpUrl}');

      final response = await http.post(
        Uri.parse(ApiConfig.otpUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'action': 'generate',
          'email': email.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('OTP Generate response: ${response.statusCode}');
      debugPrint('OTP Generate body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 404 || response.statusCode == 429) {
        String responseBody = response.body.trim();
        
        if (responseBody.contains('<br />')) {
          final jsonStart = responseBody.indexOf('{');
          if (jsonStart != -1) {
            responseBody = responseBody.substring(jsonStart);
          }
        }
        
        final result = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (result['status'] == 'success') {
          return {
            'success': true,
            'message': result['message'],
            'data': result['data'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'เกิดข้อผิดพลาดจากระบบ กรุณาลองใหม่อีกครั้ง',
        };
      }
    } catch (e) {
      debugPrint('OTP Generate Error: $e');
      
      String errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// ตรวจสอบ OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      debugPrint('OTP API: Verifying OTP for $email');

      final response = await http.post(
        Uri.parse(ApiConfig.otpUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'action': 'verify',
          'email': email.trim(),
          'otp_code': otpCode.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('OTP Verify response: ${response.statusCode}');
      debugPrint('OTP Verify body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 404 || response.statusCode == 429) {
        String responseBody = response.body.trim();
        
        if (responseBody.contains('<br />')) {
          final jsonStart = responseBody.indexOf('{');
          if (jsonStart != -1) {
            responseBody = responseBody.substring(jsonStart);
          }
        }
        
        final result = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (result['status'] == 'success') {
          return {
            'success': true,
            'message': result['message'],
            'data': result['data'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'เกิดข้อผิดพลาดจากระบบ กรุณาลองใหม่อีกครั้ง',
        };
      }
    } catch (e) {
      debugPrint('OTP Verify Error: $e');
      
      String errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// รีเซ็ตรหัสผ่าน
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      debugPrint('Reset Password API: Resetting password for $email');

      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email.trim(),
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('Reset Password response: ${response.statusCode}');
      debugPrint('Reset Password body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 404 || response.statusCode == 429) {
        String responseBody = response.body.trim();
        
        if (responseBody.contains('<br />')) {
          final jsonStart = responseBody.indexOf('{');
          if (jsonStart != -1) {
            responseBody = responseBody.substring(jsonStart);
          }
        }
        
        final result = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (result['status'] == 'success') {
          return {
            'success': true,
            'message': result['message'],
            'data': result['data'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'เกิดข้อผิดพลาดจากระบบ กรุณาลองใหม่อีกครั้ง',
        };
      }
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      
      String errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// ตรวจสอบรูปแบบอีเมล
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }
}