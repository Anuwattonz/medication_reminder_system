// ไฟล์: lib/api/reminder_api.dart
import 'package:http/http.dart' as http;
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class MedicationReminderApi {
  // ดึงข้อมูลยาของผู้ใช้
  static Future<http.Response> getMedicationData({
    required String userId,
    required String connectId,
  }) async {
    try {
      final response = await ApiHelper.getWithTokenHandling(ApiConfig.getReminderUrl);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // อัพเดทสถานะ slot
  static Future<http.Response> updateSlotStatus({
    required String userId,
    required String connectId,
    required int pillSlot,
    required String status,
  }) async {
    final requestBody = {
      'user_id': userId,
      'connect_id': connectId,
      'pill_slot': pillSlot,
      'status': status,
    };

    try {
      final response = await ApiHelper.postWithTokenHandling(
        ApiConfig.updateAppStatusUrl,
        requestBody
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}