// ไฟล์: lib/api/api_helper.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:medication_reminder_system/jwt/jwt_manager.dart';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/widget/logout.dart';
import 'dart:developer' as developer;

/// Utility class สำหรับจัดการ API requests - ลดโค้ดซ้ำโดยใช้ JWTManager
class ApiHelper {
  
  // ==================== GET Requests ====================
  
  /// GET request พร้อมจัดการ token refresh และ retry
  static Future<http.Response> getWithTokenHandling(String url) async {
    return await _requestWithRetry(() async {
      final token = await _getValidToken();

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
      ).timeout(ApiConfig.defaultTimeout);

      // Log API call
      ApiConfig.logApiCall(
        'GET',
        url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      return response;
    });
  }

  /// GET request พร้อม query parameters
  static Future<http.Response> getWithParams(String endpoint, Map<String, String> params) async {
    final url = ApiConfig.buildGetUrl(endpoint, params);
    return await getWithTokenHandling(url);
  }

  // ==================== POST Requests ====================
  
  /// POST request พร้อมจัดการ token refresh และ retry
  static Future<http.Response> postWithTokenHandling(
    String url, 
    Map<String, dynamic> body
  ) async {
    return await _requestWithRetry(() async {
      final token = await _getValidToken();

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode(body),
      ).timeout(ApiConfig.defaultTimeout);
      return response;
    });
  }

  // ==================== PUT Requests ====================
  
  /// PUT request พร้อมจัดการ token refresh และ retry
  static Future<http.Response> putWithTokenHandling(
    String url, 
    Map<String, dynamic> body
  ) async {
    return await _requestWithRetry(() async {
      final token = await _getValidToken();

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode(body),
      ).timeout(ApiConfig.defaultTimeout);

      return response;
    });
  }

  // ==================== PATCH Requests ====================
  
  /// PATCH request พร้อมจัดการ token refresh และ retry
  static Future<http.Response> patchWithTokenHandling(
    String url, 
    Map<String, dynamic> body
  ) async {
    return await _requestWithRetry(() async {
      final token = await _getValidToken();

      final response = await http.patch(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
        body: json.encode(body),
      ).timeout(ApiConfig.defaultTimeout);

      return response;
    });
  }

  // ==================== DELETE Requests ====================

  /// DELETE request พร้อมจัดการ token refresh และ retry
  static Future<http.Response> deleteWithTokenHandling(
    String url, 
    [Map<String, dynamic>? body]  // ทำให้ body เป็น optional
  ) async {
    return await _requestWithRetry(() async {
      final token = await _getValidToken();

      final response = await http.delete(
        Uri.parse(url),
        headers: ApiConfig.getAuthHeaders(token),
        body: body != null ? json.encode(body) : null,
      ).timeout(ApiConfig.defaultTimeout);


      return response;
    });
  }

  // ==================== Multipart Requests ====================
  
  /// Multipart request พร้อมจัดการ token refresh และ retry
  static Future<http.StreamedResponse> multipartWithTokenHandling(
    String url,
    Map<String, String> fields,
    {File? imageFile, String? imageFieldName = 'image'}
  ) async {
    return await _multipartRequestWithRetry(() async {
      final token = await _getValidToken();
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(ApiConfig.getAuthHeaders(token));
      request.fields.addAll(fields);
      
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(imageFieldName!, imageFile.path),
        );
      }
      
      return await request.send().timeout(ApiConfig.uploadTimeout);
    });
  }

  // ==================== Private Helper Methods ====================
  
  /// ดึง token ที่ valid (ใช้ JWTManager.ensureValidToken)
  static Future<String> _getValidToken() async {
  final hasValid = await JWTManager.ensureValidToken();
  
  if (!hasValid) {
    // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
    throw Exception('กรุณาเข้าสู่ระบบใหม่');
  }
  
  final token = await JWTManager.getToken();
  
  if (token == null) {
    // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
    throw Exception('กรุณาเข้าสู่ระบบใหม่');
  }
  
  return token;
}

/// แก้ไข: Execute HTTP request พร้อม retry และ token refresh (แก้ไข network error handling)
static Future<http.Response> _requestWithRetry(
  Future<http.Response> Function() requestFunction,
  {int maxRetries = 1}
) async {
  
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      final response = await requestFunction();
      
      // ถ้าสำเร็จ return ทันที
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      }
      
      // แก้ไข: ตรวจสอบ 401 แบบละเอียดก่อนลอง refresh
      if (response.statusCode == 401) {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['message']?.toString().toLowerCase() ?? '';
          
          // แก้ไข: ถ้า server บอกว่า token ไม่ถูกต้อง = secret key เปลี่ยน = logout ทันที
          if (errorMessage.contains('token ไม่ถูกต้อง') || 
              errorMessage.contains('invalid token') ||
              errorMessage.contains('token invalid')) {
            developer.log('Server rejected token (secret key may have changed) - performing auto logout',
              name: 'ApiHelper.requestWithRetry');
            await LogoutHelper.performFullLogout(reason: 'Server rejected token - invalid secret key');
            // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
            throw Exception('กรุณาเข้าสู่ระบบใหม่อีกครั้ง');
          }
        } catch (jsonError) {
          // ถ้า parse JSON ไม่ได้ แต่ยังเป็น 401 ให้ logout ทันที
          developer.log('401 error with unparseable response - performing auto logout',
            name: 'ApiHelper.requestWithRetry');
          await LogoutHelper.performFullLogout(reason: '401 error with invalid response');
          // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
          throw Exception('กรุณาเข้าสู่ระบบใหม่');
        }
        
        // แก้ไข: ถ้าเป็น 401 แบบอื่น (เช่น token หมดอายุ) และยังลองได้อีก
        if (attempt < maxRetries) {
          developer.log('Token expired (401), attempting refresh... (attempt ${attempt + 1}/${maxRetries + 1})',
            name: 'ApiHelper.requestWithRetry');
          
          final refreshSuccess = await JWTManager.ensureValidToken();
          
          if (refreshSuccess) {
            continue; // ลองใหม่ด้วย token ใหม่
          } else {
            developer.log('Token refresh failed, performing auto logout',
              name: 'ApiHelper.requestWithRetry');
            await LogoutHelper.performFullLogout(reason: 'Token refresh failed');
            // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
            throw Exception('กรุณาเข้าสู่ระบบใหม่');
          }
        }
      }
      
      // สำหรับ status codes อื่น ๆ ที่ไม่ใช่ 401
      return response;
      
    } catch (e) {
      developer.log('Request attempt ${attempt + 1} failed: $e',
        name: 'ApiHelper.requestWithRetry');
      
      // ✅ ปรับปรุง error messages ให้เป็นมิตรกับผู้ใช้
      if (e.toString().contains('TimeoutException')) {
        developer.log('Timeout error - letting caller handle',
          name: 'ApiHelper.requestWithRetry');
        throw Exception('การเชื่อมต่อใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
      }
      
      if (e.toString().contains('SocketException')) {
        developer.log('Network error - letting caller handle',
          name: 'ApiHelper.requestWithRetry');
        throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
      }
      
      if (LogoutHelper.isAuthError(e)) {
        developer.log('Authentication error detected - performing auto logout',
          name: 'ApiHelper.requestWithRetry');
        await LogoutHelper.performFullLogout(reason: 'Auth error during API call: $e');
        rethrow;
      }
      
      if (attempt == maxRetries) {
        // แก้ไข: ครบ retry แล้ว - ไม่ logout แต่ throw error ให้ caller จัดการ
        developer.log('Max retries reached - letting caller handle: $e',
          name: 'ApiHelper.requestWithRetry');
        // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
        throw Exception('การเชื่อมต่อมีปัญหา กรุณาลองใหม่อีกครั้ง');
      }
      
      final refreshSuccess = await JWTManager.ensureValidToken();
      if (!refreshSuccess) {
        developer.log('Token refresh failed during retry - performing auto logout',
          name: 'ApiHelper.requestWithRetry');
        await LogoutHelper.performFullLogout(reason: 'Token refresh failed during retry');
        // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
        throw Exception('กรุณาเข้าสู่ระบบใหม่');
      }
    }
  }
  
  // ✅ เปลี่ยนข้อความให้เป็นมิตรกับผู้ใช้
  throw Exception('การเชื่อมต่อมีปัญหา กรุณาลองใหม่อีกครั้ง');
}

  /// Execute Multipart request พร้อม retry และ token refresh
  static Future<http.StreamedResponse> _multipartRequestWithRetry(
    Future<http.StreamedResponse> Function() requestFunction,
    {int maxRetries = 1}
  ) async {
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await requestFunction();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return response;
        }
        
        if (response.statusCode == 401 && attempt < maxRetries) {
          developer.log('Multipart token expired (401), attempting refresh... (attempt ${attempt + 1}/${maxRetries + 1})',
            name: 'ApiHelper.multipartRequestWithRetry');
          
          final refreshSuccess = await JWTManager.ensureValidToken();
          
          if (refreshSuccess) {
            developer.log('Token refreshed successfully, retrying multipart request...',
              name: 'ApiHelper.multipartRequestWithRetry');
            continue;
          } else {
            developer.log('Multipart token refresh failed - performing logout',
              name: 'ApiHelper.multipartRequestWithRetry');
            await LogoutHelper.performFullLogout(reason: 'Multipart token refresh failed');
            throw Exception('Multipart token refresh failed');
          }
        }
        
        return response;
        
      } catch (e) {
        developer.log('Multipart request failed on attempt ${attempt + 1}: $e',
          name: 'ApiHelper.multipartRequestWithRetry');
        
        if (LogoutHelper.isAuthError(e)) {
          developer.log('Multipart authentication error detected - performing logout',
            name: 'ApiHelper.multipartRequestWithRetry');
          await LogoutHelper.performFullLogout(reason: 'Multipart auth error: $e');
          rethrow;
        }
        
        if (attempt == maxRetries) {
          rethrow;
        }
        
        final refreshSuccess = await JWTManager.ensureValidToken();
        if (!refreshSuccess) {
          developer.log('Multipart token refresh failed during retry - performing logout',
            name: 'ApiHelper.multipartRequestWithRetry');
          await LogoutHelper.performFullLogout(reason: 'Multipart token refresh failed during retry');
          rethrow;
        }
      }
    }
    
    throw Exception('Multipart request failed after $maxRetries retries');
  }

  // ==================== Response Processing ====================
  
  /// ประมวลผล API response และจัดการ token refresh อัตโนมัติ
  static Future<Map<String, dynamic>> processApiResponse(http.Response response) async {
    try {
      final jsonData = json.decode(response.body);
      
      // จัดการ token refresh จาก response
      if (jsonData is Map<String, dynamic>) {
        await JWTManager.handleApiResponse(jsonData);
      }
      
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': jsonData,
        'rawBody': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': 'JSON parse error: $e',
        'rawBody': response.body,
      };
    }
  }
}