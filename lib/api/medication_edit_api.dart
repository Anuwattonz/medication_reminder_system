// ไฟล์: lib/api/medication_edit_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class MedicationInfoApi {
  /// ดึงข้อมูลยาสำหรับแก้ไข (RESTful GET)
  static Future<Map<String, dynamic>> getMedication(String medicationId) async {
    try {
      // ใช้ RESTful URL
      final url = ApiConfig.getMedicationEditUrl(medicationId);

      final response = await ApiHelper.getWithTokenHandling(url);

      final responseBody = response.body.trim();

      if (responseBody.isEmpty) {
        throw Exception('Empty response from server');
      }

      if (!responseBody.startsWith('{') && !responseBody.startsWith('[')) {
        throw Exception('Invalid response format: $responseBody');
      }

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseBody);
      } catch (e) {
        throw Exception('JSON parse error');
      }

      return {
        'statusCode': response.statusCode,
        'data': jsonResponse,
        'success': response.statusCode == 200 && jsonResponse['status'] == 'success',
      };
    } catch (e) {
      rethrow;
    }
  }

  /// อัพเดทข้อมูลยา (RESTful PUT with Multipart)
  static Future<Map<String, dynamic>> updateMedication({
    required String medicationId,
    required String medicationName,
    required String medicationNickname,
    required String description,
    required String dosageFormId,
    required String unitTypeId,
    File? imageFile,
  }) async {
    try {
      // ลบ medication_id จาก fields (อยู่ใน URL แล้ว)
      Map<String, String> fields = {
        'medication_name': medicationName,
        'medication_nickname': medicationNickname.isEmpty ? '-' : medicationNickname,
        'description': description.isEmpty ? '-' : description,
        'dosage_form_id': dosageFormId,
        'unit_type_id': unitTypeId,
      };

      // ใช้ RESTful URL
      final url = ApiConfig.updateMedicationUrl(medicationId);

      var response = await ApiHelper.multipartWithTokenHandling(
        url,
        fields,
        imageFile: imageFile,
        imageFieldName: 'picture',
      );

      var responseData = await response.stream.bytesToString();

      if (responseData.trim().isEmpty) {
        throw Exception('Empty response from server');
      }

      if (!responseData.trim().startsWith('{') && !responseData.trim().startsWith('[')) {
        throw Exception('Invalid response format: $responseData');
      }

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseData);
      } catch (e) {
        throw Exception('JSON parse error');
      }

      return {
        'statusCode': response.statusCode,
        'data': jsonResponse,
        'success': response.statusCode == 200 && jsonResponse['status'] == 'success',
      };
    } catch (e) {
      rethrow;
    }
  }
}