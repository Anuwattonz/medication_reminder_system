import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';
import 'package:medication_reminder_system/jwt/jwt_manager.dart';

class QRScanApi {
  /// เชื่อมต่ออุปกรณ์ผ่าน QR Code
  static Future<Map<String, dynamic>> connectDevice({
    required String userId,
    required String machineSN,
  }) async {
    try {
      final requestData = {
        'user_id': userId,
        'machine_sn': machineSN,
      };

      final response = await ApiHelper.postWithTokenHandling(
        ApiConfig.connectDeviceUrl,
        requestData,
      );

      return {
        'statusCode': response.statusCode,
        'body': response.body,
        'success': response.statusCode == 200 || response.statusCode == 201,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// ประมวลผล API Response สำหรับการเชื่อมต่ออุปกรณ์
  static Future<Map<String, dynamic>> processConnectDeviceResponse({
    required int statusCode,
    required String responseBody,
  }) async {
    try {
      if (statusCode == 200 || statusCode == 201) {
        try {
          final result = jsonDecode(responseBody);

          if (result['status'] == 0 || result['status'] == 'success') {
            final data = result['data'];
            
            // ⭐ บันทึก token ใหม่ที่ API ส่งมา (มี connect_id แล้ว)
            if (data != null) {
              if (data['token'] != null) {
                await JWTManager.saveToken(data['token']);
                debugPrint('✅ Saved new JWT token with connection');
              }
              
              if (data['refresh_token'] != null) {
                await JWTManager.saveRefreshToken(data['refresh_token']);
                debugPrint('✅ Saved new refresh token');
              }
              
              // บันทึกข้อมูล connection
              if (data['connection'] != null) {
                await JWTManager.saveUserData({
                  'connection': data['connection'],
                  'has_connection': true,
                  'connected_at': DateTime.now().toIso8601String(),
                });
                debugPrint('✅ Saved connection data');
              }
            }
            
            String? connectId = data?['connect_id']?.toString();

            return {
              'success': true,
              'connectId': connectId,
              'message': result['message'] ?? 'เชื่อมต่ออุปกรณ์สำเร็จ',
              'data': result,
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ',
              'data': result,
            };
          }
        } catch (e) {
          debugPrint('❌ JSON parse error: $e');
          return {
            'success': false,
            'message': 'ข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง',
            'error': 'json_parse_error',
          };
        }
      } else if (statusCode == 400 || statusCode == 404 || statusCode == 409) {
        try {
          final result = jsonDecode(responseBody);
          String errorMessage = result['message'] ?? 'เกิดข้อผิดพลาด';

          if (result['error_code'] != null) {
            switch (result['error_code']) {
              case 'MACHINE_NOT_FOUND':
                errorMessage = 'ไม่พบเครื่องนี้ในระบบ กรุณาตรวจสอบ QR Code';
                break;
              case 'ALREADY_CONNECTED':
                errorMessage = 'เครื่องนี้ถูกเชื่อมต่อกับผู้ใช้อื่นแล้ว';
                break;
              case 'USER_ALREADY_HAS_MACHINE':
                errorMessage = 'คุณมีเครื่องเชื่อมต่ออยู่แล้ว';
                break;
            }
          }

          return {
            'success': false,
            'message': errorMessage,
            'errorCode': result['error_code'],
            'data': result,
          };
        } catch (_) {
          String fallbackMessage;
          switch (statusCode) {
            case 400:
              fallbackMessage = 'ข้อมูลที่ส่งไปไม่ถูกต้อง';
              break;
            case 404:
              fallbackMessage = 'ไม่พบเครื่องที่ต้องการเชื่อมต่อ';
              break;
            case 409:
              fallbackMessage = 'เครื่องหรือผู้ใช้มีการเชื่อมต่ออยู่แล้ว';
              break;
            default:
              fallbackMessage = 'เกิดข้อผิดพลาด ($statusCode)';
          }

          return {
            'success': false,
            'message': fallbackMessage,
            'error': 'response_parse_error',
          };
        }
      } else {
        String errorMessage = (statusCode >= 500)
            ? 'เซิร์ฟเวอร์มีปัญหา กรุณาลองใหม่อีกครั้ง'
            : 'เกิดข้อผิดพลาด ($statusCode)';

        return {
          'success': false,
          'message': errorMessage,
          'error': 'http_error',
          'statusCode': statusCode,
        };
      }
    } catch (e) {
      debugPrint('❌ Process response error: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการประมวลผลข้อมูล',
        'error': 'processing_error',
      };
    }
  }

  /// ประมวลผล QR Code ที่สแกนได้
  static String processScanedQRCode(String rawQRCode) {
    try {
      String machineSN;

      try {
        final decoded = jsonDecode(rawQRCode);
        machineSN = decoded['machine_SN'] ?? decoded['machine_sn'] ?? rawQRCode;
      } catch (_) {
        machineSN = rawQRCode;
      }

      return machineSN;
    } catch (_) {
      return rawQRCode;
    }
  }
}