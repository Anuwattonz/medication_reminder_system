// ไฟล์ใหม่: lib/jwt/network_checker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkChecker {
  /// เช็คอินเทอร์เน็ต
  static Future<bool> hasInternet() async {
    try {
      final bool isConnected = await InternetConnection().hasInternetAccess
          .timeout(const Duration(seconds: 8));
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  /// แสดงข้อความเตือนไม่มีเน็ต และปิดแอป
  static Future<void> showNoInternetAndExit(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // ปิดปุ่ม Back
        onPopInvokedWithResult: (didPop, result) {
          // ไม่ต้อง return ค่าแล้ว
        },
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 10),
              Text('ไม่มีอินเทอร์เน็ต'),
            ],
          ),
          content: const Text(
            'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต\nแล้วเปิดแอปใหม่อีกครั้ง',
          ),
          actions: [
            TextButton(
              onPressed: _exitApp,
              child: const Text(
                'ปิดแอป',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ปิดแอป
  static void _exitApp() {
    try {
      exit(0);
    } catch (e) {
      try {
        SystemNavigator.pop();
      } catch (e2) {
        //ข้าม
      }
    }
  }
}
