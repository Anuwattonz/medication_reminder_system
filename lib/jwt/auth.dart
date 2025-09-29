// ไฟล์: lib/jwt/auth.dart
// Simple Facade - ไม่มี logic ซ้ำ ใช้ JWTManager เป็นหลัก

import 'package:flutter/material.dart';
import 'package:medication_reminder_system/jwt/jwt_manager.dart';
import 'package:medication_reminder_system/widget/logout.dart';

export 'package:medication_reminder_system/jwt/jwt_manager.dart';
export 'package:medication_reminder_system/jwt/auth_checker.dart';
export 'package:medication_reminder_system/api/jwt_api.dart';
export 'package:medication_reminder_system/widget/logout.dart';

/// Simple Authentication Facade - รวมทุกอย่างไว้ที่เดียวโดยไม่ซ้ำ
class Auth {
  
  // ==================== Authentication Methods (ใช้ JWTManager โดยตรง) ====================
  
  /// ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่
  static Future<bool> isLoggedIn() async {
    return await JWTManager.hasValidToken();
  }
  
  /// ✅ เพิ่ม guard method ที่หายไป - ตรวจสอบ Authentication ก่อนเข้าหน้า
  static Future<bool> guard(BuildContext context) async {
    return await requireAuth(context);
  }
  
  /// ตรวจสอบ Authentication ก่อนเข้าหน้า (ย้ายมาจาก auth_helper)
  static Future<bool> requireAuth(BuildContext context) async {
    debugPrint('🔒 Checking authentication requirement...');
    
    final isAuthenticated = await JWTManager.ensureValidToken(maxRetries: 3);
    
    if (!isAuthenticated) {
      debugPrint('❌ Authentication failed, redirecting to login');
      if (context.mounted) {
        await LogoutHelper.navigateToLoginWithContext(context);
      }
      return false;
    }
    
    debugPrint('✅ Authentication successful');
    return true;
  }

  /// ตรวจสอบ Authentication แบบไม่มี Navigation (ย้ายมาจาก auth_helper)
  static Future<bool> isAuthenticated() async {
    debugPrint('🔍 Checking authentication status...');
    
    final isAuthenticated = await JWTManager.ensureValidToken(maxRetries: 2);
    
    debugPrint('🔍 Authentication status: $isAuthenticated');
    return isAuthenticated;
  }
  
  // ==================== User Data Access (ใช้ JWTManager โดยตรง) ====================
  
  /// ดึงข้อมูล Session ปัจจุบัน (ใหม่ - ใช้แทนการเรียกหลาย method)
  static Future<UserSession?> getCurrentSession() async {
    return await JWTManager.getCurrentSession();
  }
  
  /// ดึงข้อมูลผู้ใช้ปัจจุบัน (ปรับใหม่ - ใช้ getCurrentSession)
  static Future<Map<String, dynamic>?> currentUser() async {
    final session = await JWTManager.getCurrentSession();
    if (session == null) return null;
    
    // รวม token data และ saved data
    final result = <String, dynamic>{};
    
    if (session.tokenData != null) {
      result.addAll(session.tokenData!);
    }
    
    if (session.savedUserData != null) {
      result.addAll(session.savedUserData!);
    }
    
    // เพิ่มข้อมูลสำคัญ
    result['user_id'] = session.userId;
    result['username'] = session.username;
    result['connect_id'] = session.connectionId;
    result['has_connection'] = session.hasConnection;
    
    return result;
  }
  
  /// ดึง User ID ปัจจุบัน
  static Future<String?> currentUserId() async {
    return await JWTManager.getUserId();
  }
  
  /// ดึง Username ปัจจุบัน
  static Future<String?> currentUsername() async {
    return await JWTManager.getUsername();
  }
  
  /// ตรวจสอบว่ามีการเชื่อมต่ออุปกรณ์หรือไม่
  static Future<bool> hasDeviceConnection() async {
    return await JWTManager.hasConnection();
  }
  
  /// ดึง Connection ID ปัจจุบัน
  static Future<String?> currentConnectionId() async {
    return await JWTManager.getConnectionId();
  }

  // ==================== Token Methods ====================
  
  /// ✅ เพิ่ม refreshToken method ที่หายไป
  static Future<bool> refreshToken() async {
    return await JWTManager.tryRefreshToken();
  }

  // ==================== Logout Methods (Simple Wrappers) ====================
  
  /// Logout ง่ายๆ
  static Future<void> logout(BuildContext context) async {
    await LogoutHelper.performFullLogout(reason: 'Auth.logout() called');
  }
  
  /// แสดง Logout Dialog
  static Future<void> showLogoutDialog(BuildContext context) async {
    await LogoutHelper.logoutWithConfirmation(context);
  }
  
  /// Logout แบบด่วน (สำหรับ token หมดอายุ)
  static Future<void> quickLogout() async {
    await LogoutHelper.quickLogout(reason: 'Auth.quickLogout() called');
  }
  
  /// Emergency logout
  static Future<void> emergencyLogout() async {
    await LogoutHelper.performFullLogout(reason: 'Auth.emergencyLogout() called');
  }

  /// Force logout
  static Future<void> forceLogout([String? reason]) async {
    await LogoutHelper.performFullLogout(reason: reason ?? 'Auth.forceLogout() called');
  }
}