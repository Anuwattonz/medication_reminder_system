// ไฟล์: lib/jwt/auth_checker.dart
// ✅ แก้ไขแค่ส่วนสำคัญ - เพิ่มการเช็คเน็ตและจัดการ network error

import 'package:flutter/material.dart';
import 'package:medication_reminder_system/page/tabbar_page.dart';
import 'package:medication_reminder_system/page/settings_page.dart';
import 'package:medication_reminder_system/page/login_page.dart';
import 'package:medication_reminder_system/jwt/auth.dart';
import 'package:medication_reminder_system/api/api_helper.dart';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/jwt/network_checker.dart'; // ✅ เพิ่ม import นี้

/// หน้าสำหรับตรวจสอบ Authentication และนำทางไปหน้าที่เหมาะสม
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  String _statusMessage = 'กำลังเข้าสู่ระบบ...';

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 AuthChecker initState called');
    _checkAuthenticationStatus();
  }

  /// ตรวจสอบสถานะ Authentication พร้อมเช็คอินเทอร์เน็ตก่อน
  Future<void> _checkAuthenticationStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // ✅ เพิ่ม: เช็คอินเทอร์เน็ตก่อนอื่น
      final hasInternet = await NetworkChecker.hasInternet();
      if (!hasInternet) {
        debugPrint('❌ No internet connection detected');
        
        if (mounted) {
          await NetworkChecker.showNoInternetAndExit(context);
        }
        return; // ✅ หยุดที่นี่ ไม่ logout
      }

      debugPrint('✅ Internet connection confirmed');
      
      // ตรวจสอบ logout flag ก่อนอื่น
      if (await _isUserLoggedOut()) {
        debugPrint('🚪 User was logged out, going to login');
        _goToLogin();
        return;
      }
      
      // ตรวจสอบว่ามี token ในเครื่องหรือไม่
      final token = await JWTManager.getToken();
      if (token == null) {
        debugPrint('❌ No token found locally');
        await _clearDataAndGoToLogin();
        return;
      }

      // ✅ เช็คกับ server (ตอนนี้รู้แล้วว่ามีเน็ต)
      final serverTokenValid = await _validateTokenWithServer();
      
      if (!serverTokenValid) {
        debugPrint('❌ Server token validation failed');
        await _clearDataAndGoToLogin();
        return;
      }

      debugPrint('✅ Server token validation successful');
      
      // ใช้ Auth.isAuthenticated() แทน JWTManager โดยตรง
      final isAuthenticated = await Auth.isAuthenticated();
      
      if (!isAuthenticated) {
        debugPrint('❌ Local authentication failed, going to login');
        await _clearDataAndGoToLogin();
        return;
      }

      debugPrint('✅ Authentication successful');
      
      // ใช้ Auth.getCurrentSession() แทน
      final session = await Auth.getCurrentSession();
      
      if (session?.userId == null) {
        debugPrint('❌ No user data in session');
        await _clearDataAndGoToLogin();
        return;
      }

      // แสดงข้อมูลผู้ใช้
      debugPrint('👤 User: ${session!.username} (ID: ${session.userId})');
      debugPrint('🔗 Has connection: ${session.hasConnection}');
      debugPrint('🔌 Connection ID: ${session.connectionId}');

      await _updateStatus('เข้าสู่ระบบสำเร็จ!');
      await Future.delayed(const Duration(seconds: 1));

      // ตัดสินใจนำทางจาก JWT session โดยตรง
      if (session.hasConnection && session.connectionId != null) {
        debugPrint('✅ Has device connection, going to TabBar');
        _goToTabBar(session);
      } else {
        debugPrint('⚙️ No device connection, going to Settings');
        _goToSettings(session);
      }

    } catch (e) {
      debugPrint('❌ Error during authentication check: $e');
      
      // ✅ เพิ่ม: ตรวจสอบ network error แยกต่างหาก
      if (_isNetworkError(e)) {
        if (mounted) {
          await NetworkChecker.showNoInternetAndExit(context);
        }
        return; // ✅ หยุดที่นี่ ไม่ logout
      }
      
      // ถ้าไม่ใช่ network error ให้ไป login ตามปกติ
      await _updateStatus('เกิดข้อผิดพลาด');
      await Future.delayed(const Duration(seconds: 2));
      await _clearDataAndGoToLogin();
    }
  }

  /// ✅ เพิ่ม: ตรวจสอบว่าเป็น network error หรือไม่
  bool _isNetworkError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('failed to connect') ||
           errorString.contains('เชื่อมต่อ') ||
           errorString.contains('การเชื่อมต่อหมดเวลา') ||
           errorString.contains('ไม่สามารถเชื่อมต่อเครือข่าย');
  }

  /// ✅ แก้ไข: ตรวจสอบ token กับ server โดยไม่ auto-logout เมื่อ network error
  Future<bool> _validateTokenWithServer() async {
    try {
      debugPrint('🔍 [SERVER_CHECK] Testing token with server...');
      
      final response = await ApiHelper.getWithTokenHandling(
        ApiConfig.getReminderUrl
      );
      
      debugPrint('🔍 [SERVER_CHECK] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ [SERVER_CHECK] Token valid - API call successful');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('❌ [SERVER_CHECK] Token invalid - 401 Unauthorized');
        return false;
      } else {
        debugPrint('⚠️ [SERVER_CHECK] Unexpected response: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ [SERVER_CHECK] Error: $e');
      
      // ✅ แก้ไข: ถ้าเป็น network error ให้ throw ต่อไป เพื่อให้ caller จัดการ
      if (_isNetworkError(e)) {
        rethrow; // ให้ _checkAuthenticationStatus() จัดการ
      }
      
      return false; // Auth error อื่นๆ
    }
  }

  /// ตรวจสอบ logout flag
  Future<bool> _isUserLoggedOut() async {
    return await JWTManager.hasLogoutFlag();
  }

  /// อัปเดตสถานะ
  Future<void> _updateStatus(String message) async {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// ล้างข้อมูลและไปหน้า Login
  Future<void> _clearDataAndGoToLogin() async {
    await JWTManager.clearAll();
    _goToLogin();
  }

  /// นำทางไปหน้า Login
  void _goToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  /// นำทางไปหน้า TabBar ด้วยข้อมูลจาก JWT
  void _goToTabBar(UserSession session) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CustomTabBar(
          userData: {
            'user_id': session.userId,
            'username': session.username,
          },
          connections: [{
            'connect_id': session.connectionId,
            'user_id': session.userId,
          }],
        )),
      );
    }
  }

  /// นำทางไปหน้า Settings ด้วยข้อมูลจาก JWT
  void _goToSettings(UserSession session) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ เปลี่ยนจาก Colors.teal.shade50 เป็น Colors.white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo หรือไอคอน
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medication,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Progress indicator
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            
            const SizedBox(height: 24),
            
            // Status message
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Sub message
            Text(
              'โปรดรอสักครู่...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}