import 'package:medication_reminder_system/api/api_helper.dart';
import 'package:medication_reminder_system/config/api_config.dart';

class MedicationApi {
  /// ดึงรายการยาทั้งหมด (RESTful GET /medications)
  static Future<Map<String, dynamic>> getMedications() async {
    try {
      final response = await ApiHelper.getWithTokenHandling(ApiConfig.getMedicationsUrl);
      return _buildResponse(response.statusCode, response.body);
    } catch (e) {
      rethrow;
    }
  }



  /// อัปเดตข้อมูลยา (RESTful PUT /medications/{id} with Multipart)
  static Future<Map<String, dynamic>> updateMedication({
    required String medicationId,
    required String medicationName,
    required String medicationNickname,
    required String description,
    required String dosageFormId,
    required String unitTypeId,
    dynamic imageFile,
  }) async {
    try {

      Map<String, String> fields = {
        'medication_name': medicationName,
        'medication_nickname': medicationNickname.isEmpty ? '-' : medicationNickname,
        'description': description.isEmpty ? '-' : description,
        'dosage_form_id': dosageFormId,
        'unit_type_id': unitTypeId,
      };


      final url = ApiConfig.updateMedicationUrl(medicationId);

      final streamedResponse = await ApiHelper.multipartWithTokenHandling(
        url,
        fields,
        imageFile: imageFile,
        imageFieldName: 'picture',
      );

      final responseBody = await streamedResponse.stream.bytesToString();
      return _buildResponse(streamedResponse.statusCode, responseBody);
    } catch (e) {
      rethrow;
    }
  }

  /// ลบข้อมูลยา (RESTful DELETE /medications/{id})
  static Future<Map<String, dynamic>> deleteMedication(
    String medicationId, {
    bool forceDelete = false,
  }) async {
    try {
    
      final url = ApiConfig.deleteMedicationUrl(medicationId);
      
 
      final requestData = {
        'force_delete': forceDelete,
      };
      
      final response = await ApiHelper.deleteWithTokenHandling(
        url,
        requestData,
      );
      return _buildResponse(response.statusCode, response.body);
    } catch (e) {
      rethrow;
    }
  }
  /// 🔁 Response formatter ใช้ร่วมกันทุก method
  static Map<String, dynamic> _buildResponse(int statusCode, String body) {
    return {
      'statusCode': statusCode,
      'body': body,
      'success': statusCode == 200,
    };
  }
}
