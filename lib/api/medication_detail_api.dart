// ไฟล์: lib/api/medication_detail_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class MedicationDetailApi {
  // ดึงรายละเอียดยา
  static Future<Map<String, dynamic>> getMedicationDetail(String medicationId) async {
    try {
      // ✅ แก้ไข: เรียก function ให้ถูกต้อง
      final url = ApiConfig.getMedicationDetailUrl(medicationId);
      
      debugPrint('🔗 [DETAIL_API] Request URL: $url');

      final response = await ApiHelper.getWithTokenHandling(url);

      debugPrint('🌐 HTTP Status: ${response.statusCode}');
      debugPrint('📄 HTTP Body: ${response.body}');

      final jsonResponse = _safeJsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
        return {'success': true, 'data': jsonResponse['data']};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'ไม่พบข้อมูลยา'};
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'เกิดข้อผิดพลาด (${response.statusCode})'
        };
      }
    } catch (e) {
      debugPrint('💥 [DETAIL_API] Exception: $e');
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'การเชื่อมต่อใช้เวลานานเกินไป'
            : 'เกิดข้อผิดพลาด: $e'
      };
    }
  }

  // ✅ decode JSON แบบปลอดภัย
  static Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [DETAIL_API] JSON decode error: $e');
      debugPrint('❌ [DETAIL_API] Raw response: $body');
      return {};
    }
  }
}