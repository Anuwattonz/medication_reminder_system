// ไฟล์: lib/api/register_api.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medication_reminder_system/config/api_config.dart';

/// คลาสสำหรับจัดการ API calls ที่เกี่ยวกับการสมัครสมาชิก
/// หมายเหตุ: register ไม่ต้องใช้ ApiHelper เพราะยังไม่มี token
class RegisterApi {
  // ==================== Register API ====================
  
  /// สมัครสมาชิกผ่าน API
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    debugPrint('📝 Calling register API...');
    debugPrint('👤 Username: $username');
    debugPrint('📧 Email: $email');
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'user': username.trim(),
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(ApiConfig.defaultTimeout);
      
      debugPrint('📡 Register API response status: ${response.statusCode}');
      debugPrint('📄 Register API response body: ${response.body}');
      
      // ✅ แก้ไข: ลบ requestData parameter ออก
      ApiConfig.logApiCall(
        'POST',
        ApiConfig.registerUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        
        return {
          'success': result['status'] == 'success',
          'message': result['message'] ?? (result['status'] == 'success' 
              ? 'ลงทะเบียนสำเร็จ กรุณาเข้าสู่ระบบ' 
              : 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'),
          'data': result,
          'status_code': response.statusCode,
        };
      } else {
        debugPrint('❌ Register API HTTP error ${response.statusCode}: ${response.body}');
        
        // พยายาม parse response body แม้ว่า status code จะไม่ใช่ 200
        try {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'message': result['message'] ?? 'เกิดข้อผิดพลาดจากระบบ',
            'data': result,
            'status_code': response.statusCode,
            'error': 'HTTP Error: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'เกิดข้อผิดพลาดจากระบบ (${response.statusCode})',
            'status_code': response.statusCode,
            'error': 'HTTP Error: ${response.statusCode} - ${response.body}',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Exception during register API call: $e');
      debugPrint('❌ Exception type: ${e.runtimeType}');
      
      String errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      String errorType = 'network';
      
      // ✅ แก้ไข: เปลี่ยนข้อความเป็นภาษาไทยล้วน
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
        errorType = 'timeout';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
        errorType = 'connection';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'ข้อมูลจากระบบไม่ถูกต้อง';
        errorType = 'format';
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error_type': errorType,
        'error': e.toString(),
      };
    }
  }

  // ==================== Validation Helpers ====================
  
  /// ตรวจสอบความถูกต้องของชื่อผู้ใช้
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'กรุณากรอกชื่อผู้ใช้';
    }
    
    final trimmed = username.trim();
    
    if (trimmed.length < 3) {
      return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';
    }
    
    if (trimmed.length > 50) {
      return 'ชื่อผู้ใช้ต้องไม่เกิน 50 ตัวอักษร';
    }
    
    // ตรวจสอบตัวอักษรที่ใช้ได้
    final validPattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
    if (!validPattern.hasMatch(trimmed)) {
      return 'ชื่อผู้ใช้สามารถใช้ได้เฉพาะ a-z, A-Z, 0-9, _, ., -';
    }
    
    return null;
  }
  
  /// ตรวจสอบความถูกต้องของอีเมล
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    
    final trimmed = email.trim();
    
    // ตรวจสอบรูปแบบอีเมลเบื้องต้น
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    
    // ตรวจสอบรูปแบบอีเมลแบบละเอียด
    final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailPattern.hasMatch(trimmed)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    
    return null;
  }
  
  /// ตรวจสอบความถูกต้องของรหัสผ่าน
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    
    if (password.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    
    if (password.length > 128) {
      return 'รหัสผ่านต้องไม่เกิน 128 ตัวอักษร';
    }
    
    return null;
  }
  
  /// ตรวจสอบการยืนยันรหัสผ่าน
  static String? validateConfirmPassword(String? confirmPassword, String? originalPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }
    
    if (confirmPassword != originalPassword) {
      return 'รหัสผ่านไม่ตรงกัน';
    }
    
    return null;
  }

  // ==================== Error Handling Helpers ====================
  
  /// ตรวจสอบว่าเป็น Network Error หรือไม่
  static bool isNetworkError(Map<String, dynamic> result) {
    if (result['success'] == false) {
      final errorType = result['error_type']?.toString() ?? '';
      final message = result['message']?.toString().toLowerCase() ?? '';
      
      return errorType == 'network' || 
             errorType == 'timeout' || 
             errorType == 'connection' ||
             message.contains('network') ||
             message.contains('timeout') ||
             message.contains('connection') ||
             message.contains('เชื่อมต่อ');
    }
    return false;
  }
  
  /// ตรวจสอบว่าเป็น Server Error หรือไม่
  static bool isServerError(Map<String, dynamic> result) {
    final statusCode = result['status_code'];
    return statusCode != null && statusCode >= 500;
  }
  
  /// ตรวจสอบว่าเป็น Client Error หรือไม่ (400-499)
  static bool isClientError(Map<String, dynamic> result) {
    final statusCode = result['status_code'];
    return statusCode != null && statusCode >= 400 && statusCode < 500;
  }

  // ==================== Retry Logic ====================
  
  /// สมัครสมาชิกพร้อม retry logic
  static Future<Map<String, dynamic>> registerWithRetry({
    required String username,
    required String email,
    required String password,
    int maxRetries = 3,
  }) async {
    Map<String, dynamic>? lastResult;
    
    for (int i = 0; i < maxRetries; i++) {
      debugPrint('🔄 Register attempt ${i + 1}/$maxRetries');
      
      lastResult = await register(
        username: username,
        email: email,
        password: password,
      );
      
      if (lastResult['success'] == true) {
        debugPrint('✅ Register successful on attempt ${i + 1}');
        return lastResult;
      } else {
        debugPrint('❌ Register failed on attempt ${i + 1}: ${lastResult['message']}');
        
        // ถ้าเป็น network error ให้ลองใหม่
        if (isNetworkError(lastResult)) {
          debugPrint('🌐 Network error detected, retrying...');
          
          // รอก่อนลองใหม่ (ยกเว้นครั้งสุดท้าย)
          if (i < maxRetries - 1) {
            final waitTime = Duration(seconds: 2 * (i + 1)); // 2, 4, 6 วินาที
            debugPrint('⏱️ Waiting ${waitTime.inSeconds}s before next attempt...');
            await Future.delayed(waitTime);
          }
        } else {
          // ถ้าไม่ใช่ network error (เช่น username ซ้ำ) ให้หยุดทันที
          debugPrint('❌ Non-network error detected, stopping retries');
          break;
        }
      }
    }
    
    debugPrint('❌ All register attempts failed');
    return lastResult ?? {
      'success': false,
      'message': 'การสมัครสมาชิกล้มเหลวหลังจากลองหลายครั้ง',
    };
  }
}