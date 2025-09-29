// ไฟล์: lib/widget/logout.dart
import 'package:flutter/material.dart';
import 'package:medication_reminder_system/jwt/jwt_manager.dart';
import 'package:medication_reminder_system/page/login_page.dart';

/// Utility class สำหรับจัดการการ logout ทั่วทั้งแอป
class LogoutHelper {
  
  static BuildContext? _globalContext;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static final List<VoidCallback> _cleanupCallbacks = [];
  
  /// Set global context สำหรับ navigation
  static void setGlobalContext(BuildContext context) {
    _globalContext = context;
  }
  
  /// Set navigator key สำหรับ navigation
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }
  
  /// ลงทะเบียน cleanup callback (สำหรับยกเลิกการแจ้งเตือน)
  static void registerCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.add(callback);
  }
  
  /// ลบ cleanup callback
  static void unregisterCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.remove(callback);
  }
  
  /// เรียก cleanup callbacks ทั้งหมด
  static void _executeCleanupCallbacks() {
    for (final callback in _cleanupCallbacks) {
      try {
        callback();
      } catch (e) {
        // Silent error handling
      }
    }
    _cleanupCallbacks.clear();
  }
  
  // ==================== Main Logout Methods ====================
  
  /// ทำการ logout แบบเต็มรูปแบบ - ล้างทุกอย่าง
  static Future<void> performFullLogout({String reason = 'User logout'}) async {
    try {
      _executeCleanupCallbacks();
      await JWTManager.setLogoutFlag();
      await JWTManager.clearAll();
      await _navigateToLogin();
    } catch (e) {
      await _navigateToLogin();
    }
  }
  
  /// Logout แบบด่วน (สำหรับกรณี token หมดอายุ) - ไม่แสดง dialog
  static Future<void> quickLogout({String reason = 'Token expired'}) async {
    try {
      _executeCleanupCallbacks();
      await JWTManager.setLogoutFlag();
      await JWTManager.clearAll();
      await _navigateToLogin();
    } catch (e) {
      await _navigateToLogin();
    }
  }
  
  /// Silent logout (สำหรับกรณี auth หมดอายุ) - ไม่แสดง dialog เลย
  static Future<void> silentLogout({String reason = 'Silent logout'}) async {
    try {
      _executeCleanupCallbacks();
      await JWTManager.setLogoutFlag();
      await JWTManager.clearAll();
      await _navigateToLogin();
    } catch (e) {
      await _navigateToLogin();
    }
  }
  
  /// Logout พร้อม confirmation dialog (สำหรับกรณี user กดปุ่ม logout เอง)
  static Future<void> logoutWithConfirmation(BuildContext context) async {
    if (!context.mounted) {
      await performFullLogout(reason: 'Context not mounted');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                color: Colors.red[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ออกจากระบบ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          'คุณต้องการออกจากระบบหรือไม่?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        _executeCleanupCallbacks();
        await JWTManager.setLogoutFlag();
        await JWTManager.clearAll();
        
        if (context.mounted) {
          await navigateToLoginWithContext(context);
        } else {
          await _navigateToLogin();
        }
      } catch (e) {
        await _navigateToLogin();
      }
    }
  }
  
  // ==================== Navigation Logic ====================
  
  /// Navigate ไปหน้า login
  static Future<void> _navigateToLogin() async {
    try {
      // วิธีที่ 1: ใช้ NavigatorKey (แนะนำ)
      if (_navigatorKey?.currentState != null) {
        _navigatorKey!.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }
      
      // วิธีที่ 2: ใช้ NavigatorKey.currentContext
      if (_navigatorKey?.currentContext != null && _navigatorKey!.currentContext!.mounted) {
        final navigator = Navigator.maybeOf(_navigatorKey!.currentContext!);
        if (navigator != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
          return;
        }
      }
      
      // วิธีที่ 3: ใช้ global context
      if (_globalContext != null && _globalContext!.mounted) {
        final navigator = Navigator.maybeOf(_globalContext!);
        if (navigator != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_globalContext!.mounted) {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          });
          return;
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }
  
  /// Navigate ไปหน้า login โดยใช้ context ที่ส่งมา
  static Future<void> navigateToLoginWithContext(BuildContext context) async {
    try {
      if (context.mounted) {
        final navigator = Navigator.maybeOf(context);
        if (navigator != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false,
          );
        } else {
          await _navigateToLogin();
        }
      } else {
        await _navigateToLogin();
      }
    } catch (e) {
      await _navigateToLogin();
    }
  }
  
  // ==================== Utility Methods ====================
  
  /// ตรวจสอบว่าควร logout หรือไม่จาก response
  static bool shouldLogoutFromResponse(Map<String, dynamic> response) {
    // ตรวจสอบ require_login flag
    if (response['require_login'] == true) {
      return true;
    }
    
    // ตรวจสอบ message ที่บอกให้ login ใหม่
    final message = response['message']?.toString().toLowerCase() ?? '';
    if (message.contains('please login again') || 
        message.contains('authentication failed') ||
        message.contains('เข้าสู่ระบบใหม่') ||
        message.contains('หมดอายุ') ||
        message.contains('token') && message.contains('invalid') ||
        message.contains('unauthorized')) {
      return true;
    }
    
    // ตรวจสอบ status ที่บอกให้ logout
    if (response['status'] == 'unauthorized' || 
        response['status'] == 'token_expired' ||
        response['status'] == 'authentication_failed') {
      return true;
    }
    
    return false;
  }
  
  /// ตรวจสอบว่าเป็น authentication error หรือไม่
  static bool isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('authentication') || 
           errorStr.contains('token') ||
           errorStr.contains('401') ||
           errorStr.contains('jwt') ||
           errorStr.contains('unauthorized') ||
           errorStr.contains('หมดอายุ') ||
           errorStr.contains('เข้าสู่ระบบใหม่');
  }
  
  // ==================== Emergency Methods ====================
  
  /// Emergency logout (สำหรับกรณีฉุกเฉิน)
  static Future<void> emergencyLogout({String reason = 'Emergency logout'}) async {
    try {
      _executeCleanupCallbacks();
      await JWTManager.clearAll();
      await _navigateToLogin();
    } catch (e) {
      await _navigateToLogin();
    }
  }
  
  // ==================== Response Handler Methods (แก้ไขให้ silent) ====================
  
  /// จัดการ API response ที่อาจต้อง logout - แบบ Silent (ไม่แสดง dialog)
  static Future<bool> handleApiAuthResponse(
    Map<String, dynamic> response, {
    BuildContext? context,
  }) async {
    if (shouldLogoutFromResponse(response)) {
      final reason = 'API auth error: ${response['message'] ?? 'Unknown'}';
      
      // ใช้ silentLogout แทน showAuthErrorDialog
      await silentLogout(reason: reason);
      return true;
    }
    
    return false;
  }
  
  /// จัดการ Exception ที่อาจเป็น auth error - แบบ Silent (ไม่แสดง dialog)
  static Future<bool> handleAuthException(
    dynamic exception, {
    BuildContext? context,
    String? customMessage,
  }) async {
    if (isAuthError(exception)) {
      final reason = 'Auth exception: ${exception.toString()}';
      
      // ใช้ silentLogout แทน showAuthErrorDialog
      await silentLogout(reason: reason);
      return true;
    }
    
    return false;
  }
  
  // ==================== Optional: Show Dialog Methods (เก็บไว้เผื่อใช้ในอนาคต) ====================
  
  /// แสดง Error Dialog สำหรับกรณี Authentication Failed (เก็บไว้เผื่อต้องการใช้ในบางกรณี)
  static Future<void> showAuthErrorDialog(
    BuildContext context, {
    String title = 'เซสชันหมดอายุ',
    String message = 'กรุณาเข้าสู่ระบบใหม่',
    String reason = 'Session expired',
  }) async {
    if (!context.mounted) {
      await performFullLogout(reason: reason);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              performFullLogout(reason: reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'ตกลง',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}