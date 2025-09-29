// ไฟล์: lib/api/settings_api.dart
import 'package:http/http.dart' as http;
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class SettingsApi {
  // ==================== GET Requests ====================
  
  /// ดึงการตั้งค่าจาก API
  static Future<http.Response> getVolumeSettings(String connectId) async {
    // ✅ ใช้ URL builder แทน manual concatenation
    final url = ApiConfig.buildGetUrl(
      ApiConfig.getSettingsUrl, 
      {'connect_id': connectId}
    );
    return await ApiHelper.getWithTokenHandling(url);
  }

  // ==================== PUT Requests ====================
  
  /// อัพเดทการตั้งค่าเสียงผ่าน API
  static Future<http.Response> updateVolumeSettings({
    required String connectId, // เก็บไว้เป็น parameter แต่ไม่ส่งใน body
    required int volume,
    required int delay,
    required int alertOffset,
  }) async {
    // ✅ ลบ connect_id ออกจาก request body (PHP ใช้ JWT แทน)
    final requestData = {
      'volume': volume,
      'delay': delay,
      'alert_offset': alertOffset,
    };

    // ✅ ใช้ PUT method สำหรับ update operation
    return await ApiHelper.putWithTokenHandling(
      ApiConfig.updateVolumeSettingsUrl,
      requestData
    );
  }

  /// อัพเดทชื่อผู้ใช้ผ่าน API
  static Future<http.Response> updateUsername(String newUsername) async {
    final requestData = {'username': newUsername};

    // ✅ ใช้ PUT method สำหรับ update operation
    return await ApiHelper.putWithTokenHandling(
      ApiConfig.updateUsernameUrl,
      requestData
    );
  }
}