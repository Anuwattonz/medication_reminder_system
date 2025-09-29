import 'dart:convert';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class MedicationTimingApi {
  /// อัปเดต medication timings (ใช้ RESTful PUT method)
  static Future<Map<String, dynamic>> updateMedicationTimings({
    required String medicationId,
    required List<int> timingIds,
  }) async {
    try {
      final requestData = {
        'timing_ids': timingIds,
      };

      // ใช้ RESTful URL และ PUT method
      final url = ApiConfig.updateMedicationTimingsUrl(medicationId);
      
      // ใช้ putWithTokenHandling สำหรับ RESTful API
      final response = await ApiHelper.putWithTokenHandling(
        url,
        requestData,
      );

      final responseBody = response.body.trim();

      if (responseBody.isEmpty) {
        throw Exception('เซิร์ฟเวอร์ส่งข้อมูลว่างเปล่า');
      }

      if (!responseBody.startsWith('{') && !responseBody.startsWith('[')) {
        throw Exception('เซิร์ฟเวอร์ส่งข้อมูลผิดรูปแบบ: $responseBody');
      }

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
      } catch (e) {
        throw Exception('ไม่สามารถแปลงข้อมูลจากเซิร์ฟเวอร์ได้');
      }

      return {
        'statusCode': response.statusCode,
        'data': jsonResponse,
        'success': response.statusCode == 200 &&
            jsonResponse['status'] == 'success',
      };
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static String _handleError(dynamic error) {
    String errorMessage = 'เกิดข้อผิดพลาด';

    if (error.toString().contains('timeout') || error.toString().contains('ใช้เวลานานเกินไป')) {
      errorMessage = 'การเชื่อมต่อใช้เวลานานเกินไป';
    } else if (error.toString().contains('network') || error.toString().contains('connection')) {
      errorMessage = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
    } else if (error.toString().contains('ไม่สามารถรับรองความถูกต้องของ token ได้')) {
      errorMessage = 'กรุณาเข้าสู่ระบบใหม่';
    } else if (error.toString().contains('เซิร์ฟเวอร์ส่งข้อมูลผิดรูปแบบ')) {
      return error.toString();
    } else if (error.toString().contains('ไม่สามารถแปลงข้อมูลจากเซิร์ฟเวอร์ได้')) {
      errorMessage = 'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง';
    }

    return errorMessage;
  }
}