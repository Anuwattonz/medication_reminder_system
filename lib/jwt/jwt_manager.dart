// ไฟล์: lib/jwt/jwt_manager.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medication_reminder_system/api/jwt_api.dart';

class JWTManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _logoutFlagKey = 'user_logged_out';

  // ==================== Session Cache (ลดการเรียกซ้ำ) ====================
  
  static UserSession? _cachedSession;
  static DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// ล้าง session cache
  static void _clearSessionCache() {
    _cachedSession = null;
    _cacheTime = null;
  }

  /// ตรวจสอบว่า cache ยังใช้ได้หรือไม่
  static bool _isCacheValid() {
    if (_cachedSession == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheExpiry;
  }

  // ==================== Token Management ====================
  
  /// บันทึก JWT Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _clearSessionCache(); // ล้าง cache เมื่อมี token ใหม่
  }

  /// บันทึก Refresh Token
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// บันทึกข้อมูล User
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
    _clearSessionCache(); // ล้าง cache เมื่อมีข้อมูลใหม่
  }

  /// ดึง JWT Token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// ดึง Refresh Token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// ดึงข้อมูล User ที่เก็บไว้
  static Future<Map<String, dynamic>?> getSavedUserData() async {
    final userDataString = await _storage.read(key: _userDataKey);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ==================== Core Authentication (รวมทุก logic ไว้ที่เดียว) ====================
  
  /// ตรวจสอบและ refresh token หากจำเป็น - ใช้แทน logic ใน auth_helper
    static Future<bool> ensureValidToken({int maxRetries = 1}) async { // ← เปลี่ยนจาก 3 เป็น 1
      debugPrint('🔍 Checking token validity...');
      
      final token = await getToken();
      if (token == null) {
        debugPrint('❌ No token found');
        return false;
      }
      
      // ตรวจสอบ token validity
      if (await hasValidToken()) {
        debugPrint('✅ Token is valid');
        return true;
      }
      
      debugPrint('🔄 Token expired, attempting refresh...');
      
      // ลอง refresh token
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        debugPrint('🔄 Refresh attempt $attempt/$maxRetries');
        
        final refreshed = await tryRefreshToken();
        
        if (refreshed) {
          debugPrint('✅ Token refreshed successfully');
          return true;
        }
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
      
      debugPrint('❌ Token refresh failed after $maxRetries attempts');
      return false;
    }

  /// ตรวจสอบว่ามี Token หรือไม่และยังไม่หมดอายุ
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      final payload = _decodeJWT(token);
      final exp = payload['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp > currentTime;
    } catch (e) {
      return false;
    }
  }

  /// Decode JWT Token
  static Map<String, dynamic> _decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid JWT token');
    
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return json.decode(resp);
  }

  // ==================== Centralized User Data Access (ลดการเรียกซ้ำ) ====================
  
  /// ดึงข้อมูล User Session แบบครบครัน (มี cache) - ใช้แทนการเรียกหลาย method
  static Future<UserSession?> getCurrentSession() async {
    // ใช้ cache ถ้ายังใหม่
    if (_isCacheValid()) {
      return _cachedSession;
    }

    final token = await getToken();
    if (token == null) {
      _clearSessionCache();
      return null;
    }
    
    try {
      final tokenData = _decodeJWT(token);
      final savedData = await getSavedUserData();
      
      final session = UserSession(
        userId: tokenData['user_id']?.toString(),
        username: tokenData['username']?.toString() ?? tokenData['user']?.toString(),
        connectionId: tokenData['connect_id']?.toString(),
        hasConnection: tokenData['connect_id'] != null && 
                      tokenData['connect_id'].toString() != '0',
        savedUserData: savedData,
        tokenData: tokenData,
      );

      // Cache session
      _cachedSession = session;
      _cacheTime = DateTime.now();
      
      return session;
    } catch (e) {
      _clearSessionCache();
      return null;
    }
  }

  // ==================== Simple Access Methods (ใช้ cache session) ====================
  
  /// ดึงข้อมูล User จาก JWT Token
  static Future<Map<String, dynamic>?> getUserDataFromToken() async {
    final session = await getCurrentSession();
    return session?.tokenData;
  }

  /// ดึง User ID จาก JWT (ใช้ cache session)
  static Future<String?> getUserId() async {
    final session = await getCurrentSession();
    return session?.userId;
  }

  /// ดึง Username จาก JWT (ใช้ cache session)
  static Future<String?> getUsername() async {
    final session = await getCurrentSession();
    return session?.username;
  }

  /// ดึง Connection ID จาก JWT (ใช้ cache session)
  static Future<String?> getConnectionId() async {
    final session = await getCurrentSession();
    return session?.connectionId;
  }

  /// ตรวจสอบว่ามีการเชื่อมต่ออุปกรณ์หรือไม่ (ใช้ cache session)
  static Future<bool> hasConnection() async {
    final session = await getCurrentSession();
    return session?.hasConnection ?? false;
  }

  // ==================== Token Refresh ====================
  
  /// ลอง refresh token
  static Future<bool> tryRefreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await JWTApi.refreshToken(refreshToken);
      return await handleApiResponse(response);
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }
  
  /// จัดการ token refresh จาก API Response
  static Future<bool> handleApiResponse(Map<String, dynamic> apiResponse) async {
    try {
      _clearSessionCache(); // ล้าง cache เมื่อมีการ refresh
      
      // ตรวจสอบว่ามี auth field หรือไม่ (จาก jwt_middleware.php)
      if (apiResponse['auth'] != null) {
        final authData = apiResponse['auth'] as Map<String, dynamic>;
        
        if (authData['token_refreshed'] == true && authData['new_token'] != null) {
          final newToken = authData['new_token'] as String;
          await saveToken(newToken);
          
          if (authData['new_refresh_token'] != null) {
            await saveRefreshToken(authData['new_refresh_token']);
          }
          
          return true;
        }
      }
      
      // ✅ แก้ไข: ตรวจสอบ response format จาก refresh.php
      final data = apiResponse['data'] ?? {};
      
      if (apiResponse['status'] == 'success' && 
          data['auto_login_status'] == 'token_refreshed' && 
          data['new_token'] != null) {
        
        final newToken = data['new_token'] as String;
        await saveToken(newToken);
        
        // บันทึกข้อมูล user ใหม่
        if (data['user'] != null) {
          await saveUserData({
            'user': data['user'],
            'has_connection': data['has_connection'] ?? false,
            'connections': data['connections'] ?? [],
            'connect_id': data['connect_id'] ?? '0',
          });
        }
        
        return true;
      }
      
      // ตรวจสอบ format เก่า
      if (apiResponse['success'] == true && apiResponse['token'] != null) {
        final newToken = apiResponse['token'] as String;
        await saveToken(newToken);
        
        if (apiResponse['user_data'] != null) {
          await saveUserData(apiResponse['user_data']);
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error handling API response: $e');
      return false;
    }
  }

  // ==================== Logout Management ====================
  
  /// บันทึก logout flag
  static Future<void> setLogoutFlag() async {
    await _storage.write(key: _logoutFlagKey, value: 'true');
    _clearSessionCache();
  }

  /// ตรวจสอบ logout flag
  static Future<bool> hasLogoutFlag() async {
    final flag = await _storage.read(key: _logoutFlagKey);
    return flag == 'true';
  }

  /// ล้างข้อมูลทั้งหมด
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    _clearSessionCache();
  }

  /// ล้าง logout flag
  static Future<void> clearLogoutFlag() async {
    await _storage.delete(key: _logoutFlagKey);
  }

  // ==================== Backwards Compatibility (รักษาชื่อเดิมไว้) ====================
  
  /// รักษาชื่อเดิมไว้เพื่อไม่กระทบหน้าอื่น
  static Future<bool> refreshTokenWithRetry({int maxRetries = 3}) async {
    return await ensureValidToken(maxRetries: maxRetries);
  }
}

/// Data class สำหรับ User Session (ลดการเรียก getUserDataFromToken หลายครั้ง)
class UserSession {
  final String? userId;
  final String? username;
  final String? connectionId;
  final bool hasConnection;
  final Map<String, dynamic>? savedUserData;
  final Map<String, dynamic>? tokenData;

  UserSession({
    this.userId,
    this.username,
    this.connectionId,
    this.hasConnection = false,
    this.savedUserData,
    this.tokenData,
  });

  @override
  String toString() {
    return 'UserSession(userId: $userId, username: $username, hasConnection: $hasConnection)';
  }
}