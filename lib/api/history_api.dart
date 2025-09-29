// ไฟล์: lib/api/reminder_history_api.dart
import 'dart:convert';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class ReminderHistoryApi {
  /// ดึงรายการประวัติการแจ้งเตือนแบบ pagination
  /// [page] - หน้าที่ต้องการ (เริ่มจาก 1)
  /// [limit] - จำนวนรายการต่อหน้า (default: 10)
  static Future<Map<String, dynamic>> getHistory({int page = 1, int limit = 10}) async {
    try {
      final uri = Uri.parse(ApiConfig.getReminderHistoryUrl).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await ApiHelper.getWithTokenHandling(uri.toString());
      return _buildResponse(response.statusCode, response.body);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// ดึงรายละเอียดประวัติการแจ้งเตือนตาม ID
  static Future<Map<String, dynamic>> getHistoryDetail(int reminderMedicalId) async {
    try {
      final url = ApiConfig.getReminderHistoryDetailUrl(reminderMedicalId.toString());
      final response = await ApiHelper.getWithTokenHandling(url);
      return _buildResponse(response.statusCode, response.body);
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// สร้าง response ในรูปแบบมาตรฐาน
  static Map<String, dynamic> _buildResponse(int statusCode, String body) {
    try {
      final jsonData = json.decode(body);
      
      return {
        'statusCode': statusCode,
        'success': statusCode == 200 && jsonData['status'] == 'success',
        'data': jsonData,
        'message': jsonData['message'] ?? '',
        'rawBody': body,
      };
    } catch (e) {
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

    return errorMessage;
  }
}