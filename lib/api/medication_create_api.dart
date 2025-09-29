// ไฟล์: lib/api/medication_create_api.dart
import 'dart:io';
import 'dart:convert';
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class ApiMedicationCreate {
  // ดึงข้อมูลรูปแบบยาและหน่วยยา
  static Future<Map<String, dynamic>> getDosageForms() async {
    try {
      final response = await ApiHelper.getWithTokenHandling(ApiConfig.getDosageFormsUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dosageFormsData = data['data'];

        if (data['status'] == 'success' && dosageFormsData is List && dosageFormsData.isNotEmpty) {
          final Map<int, Map<String, dynamic>> uniqueForms = {};
          for (var form in dosageFormsData) {
            final formId = form['dosage_form_id'];
            if (formId != null && form['dosage_name'] != null) {
              if (!uniqueForms.containsKey(formId) ||
                  ((form['unit_types'] ?? []).length > (uniqueForms[formId]?['unit_types'] ?? []).length)) {
                uniqueForms[formId] = form;
              }
            }
          }
          final availableDosageForms = uniqueForms.values.toList()
            ..sort((a, b) => a['dosage_form_id'].compareTo(b['dosage_form_id']));

          return {
            'success': true,
            'data': availableDosageForms,
          };
        }
      }

      return {
        'success': false,
        'error': 'invalid_response',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'network_error',
      };
    }
  }

  // สร้างข้อมูลยาใหม่
  static Future<Map<String, dynamic>> createMedication({
    required String medicationName,
    String? medicationNickname,
    String? description,
    required int dosageFormId,
    required int unitTypeId,
    required Set<int> timingIds,
    File? picture,
  }) async {
    try {
      // ส่งข้อมูลในรูปแบบที่ PHP เก่าต้องการ
      Map<String, String> fields = {
        'medication_name': medicationName.trim(),
        'medication_nickname': (medicationNickname ?? '').trim().isEmpty 
            ? '' 
            : (medicationNickname ?? '').trim(),
        'description': (description ?? '').trim().isEmpty 
            ? '' 
            : (description ?? '').trim(),
        'dosage_form_id': dosageFormId.toString(),
        'unit_type_id': unitTypeId.toString(),
        'timing_ids': timingIds.join(','), // ส่งเป็น string ตาม PHP เก่า
      };

      // ใช้ multipart เสมอไม่ว่าจะมีรูปหรือไม่
      final streamedResponse = await ApiHelper.multipartWithTokenHandling(
        ApiConfig.postMedicationCreateUrl,
        fields,
        imageFile: picture,
        imageFieldName: 'picture',
      );

      var responseData = await streamedResponse.stream.bytesToString();

      if (responseData.trim().isEmpty) {
        return {
          'success': false, 
          'error': 'empty_response',
          'message': 'เซิร์ฟเวอร์ส่งข้อมูลว่างเปล่า'
        };
      }

      if (!responseData.trim().startsWith('{')) {
        return {
          'success': false, 
          'error': 'invalid_response',
          'message': 'เซิร์ฟเวอร์ส่งข้อมูลผิดรูปแบบ: $responseData'
        };
      }

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseData);
      } catch (e) {
        return {
          'success': false, 
          'error': 'json_parse_error',
          'message': 'ไม่สามารถแปลงข้อมูลจากเซิร์ฟเวอร์ได้'
        };
      }

      // ตรวจสอบ response ตามรูปแบบ PHP เก่า
      if (streamedResponse.statusCode == 200 && jsonResponse['status'] == 'success') {
        return {
          'success': true,
          'data': jsonResponse['data'],
          'message': jsonResponse['message'] ?? 'สร้างข้อมูลยาสำเร็จ',
        };
      } else {
        return {
          'success': false,
          'error': 'api_error',
          'message': jsonResponse['message'] ?? 'เกิดข้อผิดพลาด',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'error': 'network_error',
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
      };
    }
  }

  // ดึงหน่วยยาสำหรับรูปแบบยาที่เลือก
  static List<Map<String, dynamic>> getUnitTypesForDosageForm(
    List<Map<String, dynamic>> availableDosageForms,
    int dosageFormId,
  ) {
    try {
      final dosageForm = availableDosageForms.firstWhere(
        (form) => form['dosage_form_id'] == dosageFormId,
        orElse: () => {},
      );
      if (dosageForm.isNotEmpty && dosageForm['unit_types'] is List) {
        return List<Map<String, dynamic>>.from(dosageForm['unit_types']);
      }
    } catch (_) {
      // ถ้าเกิด error ให้ return empty list
    }
    return [];
  }

  // ตรวจสอบความถูกต้องของข้อมูล
  static Map<String, dynamic> validateMedicationData({
    required String medicationName,
    required int? dosageFormId,
    required int? unitTypeId,
    required Set<int> timingIds,
    required List<Map<String, dynamic>> availableDosageForms,
  }) {
    if (medicationName.trim().isEmpty) {
      return {'isValid': false, 'error': 'empty_medication_name'};
    }
    if (medicationName.trim().length > 255) {
      return {'isValid': false, 'error': 'medication_name_too_long'};
    }
    if (dosageFormId == null) {
      return {'isValid': false, 'error': 'no_dosage_form'};
    }
    final availableUnitTypes = getUnitTypesForDosageForm(availableDosageForms, dosageFormId);
    if (availableUnitTypes.isEmpty) {
      return {'isValid': false, 'error': 'no_unit_types'};
    }
    if (unitTypeId == null) {
      return {'isValid': false, 'error': 'no_unit_type'};
    }
    if (!availableUnitTypes.any((unit) => unit['unit_type_id'] == unitTypeId)) {
      return {'isValid': false, 'error': 'invalid_unit_type'};
    }
    if (timingIds.isEmpty) {
      return {'isValid': false, 'error': 'no_timing'};
    }
    return {'isValid': true};
  }
}