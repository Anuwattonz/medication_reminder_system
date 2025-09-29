// ไฟล์: lib/api/summary_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class SummaryApi {
  /// ดึงสรุปสถิติการกินยา
  /// [period] - ช่วงเวลา: 'all', 'month', 'week'
  /// [startDate] - วันที่เริ่มต้น (format: YYYY-MM-DD)
  /// [endDate] - วันที่สิ้นสุด (format: YYYY-MM-DD)
  static Future<Map<String, dynamic>> getSummary({
    String period = 'all',
    String? startDate,
    String? endDate,
  }) async {
    try {
      // สร้าง query parameters
      final queryParams = <String, String>{
        'period': period,
      };
      
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      
      // สร้าง URL พร้อม query parameters
      final url = ApiConfig.buildGetUrl(
        ApiConfig.getSummaryUrl, 
        queryParams
      );

      debugPrint('🌐 [SUMMARY_API] Request URL: $url');
      debugPrint('📋 [SUMMARY_API] Parameters: period=$period, start=$startDate, end=$endDate');

      final response = await ApiHelper.getWithTokenHandling(url);

      debugPrint('📨 [SUMMARY_API] Response Status: ${response.statusCode}');
      debugPrint('📝 [SUMMARY_API] Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}');

      return _buildResponse(response.statusCode, response.body);
    } catch (e) {
      debugPrint('❌ [SUMMARY_API] Exception: $e');
      throw Exception(_handleError(e));
    }
  }

  /// สร้าง response ในรูปแบบมาตรฐาน
  static Map<String, dynamic> _buildResponse(int statusCode, String body) {
    try {
      final jsonData = json.decode(body);
      
      debugPrint('✅ [SUMMARY_API] JSON Parse Success');
      debugPrint('📊 [SUMMARY_API] Response Data: status=${jsonData['status']}, message=${jsonData['message']}');
      
      // ตรวจสอบ summary data ถ้ามี
      if (jsonData['data'] != null && jsonData['data']['summary'] != null) {
        final summary = jsonData['data']['summary'];
        debugPrint('📈 [SUMMARY_API] Summary: total=${summary['total_reminders']}, taken=${summary['taken_count']}, rate=${summary['compliance_rate']}%');
      }
      
      return {
        'statusCode': statusCode,
        'success': statusCode == 200 && jsonData['status'] == 'success',
        'data': jsonData,
        'message': jsonData['message'] ?? '',
        'rawBody': body,
      };
    } catch (e) {
      debugPrint('❌ [SUMMARY_API] JSON Parse Error: $e');
      debugPrint('📝 [SUMMARY_API] Raw Body: $body');
      
      return {
        'statusCode': statusCode,
        'success': false,
        'data': null,
        'message': 'JSON parse error: $e',
        'rawBody': body,
        'error': 'json_parse_error',
      };
    }
  }

  /// จัดการ error messages
  static String _handleError(dynamic error) {
    String errorMessage = 'เกิดข้อผิดพลาด';

    if (error.toString().contains('timeout') || error.toString().contains('ใช้เวลานานเกินไป')) {
      errorMessage = 'การเชื่อมต่อใช้เวลานานเกินไป';
    } else if (error.toString().contains('network') || error.toString().contains('connection')) {
      errorMessage = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
    } else if (error.toString().contains('ไม่สามารถรับรองความถูกต้องของ token ได้')) {
      errorMessage = 'กรุณาเข้าสู่ระบบใหม่';
    } else if (error.toString().contains('Token refresh failed')) {
      errorMessage = 'กรุณาเข้าสู่ระบบใหม่';
    }

    debugPrint('🔄 [SUMMARY_API] Error Handled: $errorMessage');
    return errorMessage;
  }

  }
