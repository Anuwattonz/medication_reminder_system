// ไฟล์: lib/api/reminder_setting_api.dart
import 'dart:convert';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class ReminderSettingApi {
  // ==================== Core API Methods ====================
  
  /// ดึงข้อมูลทั้งหมดสำหรับ slot reminder (API ใหม่)
  static Future<Map<String, dynamic>> getAllSlotData(String appId) async {
    try {
      // ✅ ใช้ buildGetUrl แทน buildSlotReminderUrl ที่ไม่มี
      final url = ApiConfig.buildGetUrl(
        ApiConfig.getSlotReminderUrl, 
        {'app_id': appId}
      );
      final response = await ApiHelper.getWithTokenHandling(url);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['status'] == 'success') {
          return result;
        } else {
          throw Exception(result['message'] ?? 'API returned error status');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// บันทึกการตั้งค่าทั้งหมด
  static Future<Map<String, dynamic>> saveAllSettings({
    required int appId,
    required String timing,
    int? timingId,
    required Map<String, bool> days,
    required List<Map<String, dynamic>> medications,
  }) async {
    try {
      final requestData = {
        'action': 'save_all_settings',
        'timing': timing,
        'timing_id': timingId,
        'days': days,
        'medications': medications,
      };

      // ✅ ใช้ buildGetUrl สำหรับ query parameters
      final url = ApiConfig.buildGetUrl(
        ApiConfig.updateReminderUrl, 
        {'app_id': appId.toString()}
      );
      
      // ✅ ใช้ PUT method สำหรับ update operation
      final response = await ApiHelper.putWithTokenHandling(
        url,
        requestData,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['status'] == 'success') {
          return result;
        } else {
          throw Exception(result['message'] ?? 'API returned error status');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Data Extraction Helpers ====================
  
  static List<Map<String, dynamic>> extractTimingOptions(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final options = List<Map<String, dynamic>>.from(response['data']['timing_options'] ?? []);
      return options;
    }
    return [];
  }

  static Map<String, dynamic>? extractAppData(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final appData = response['data']['app_data'];
      if (appData != null) {
        return appData;
      }
    }
    return null;
  }

  static Map<String, dynamic> extractDaySettings(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final settings = Map<String, dynamic>.from(response['data']['day_settings'] ?? {});
      return settings;
    }
    return {};
  }

  static List<Map<String, dynamic>> extractMedicationLinks(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final links = List<Map<String, dynamic>>.from(response['data']['medication_links'] ?? []);
      return links;
    }
    return [];
  }

  static List<Map<String, dynamic>> extractAvailableMedications(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final meds = List<Map<String, dynamic>>.from(response['data']['available_medications'] ?? []);
      return meds;
    }
    return [];
  }
}