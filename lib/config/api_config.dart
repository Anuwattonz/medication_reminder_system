// ไฟล์: lib/config/api_config.dart
/// คลาสสำหรับจัดการ configuration ของ API endpoints ทั้งหมด
/// ✅ แก้ให้ตรงกับโครงสร้างไฟล์จริงทั้งหมด
class ApiConfig {
  // Base URL หลักของ API
  static const String _baseUrl = 'https://api-pill-reminder.coecore.com/api';
  static String get baseUrl => _baseUrl;

  // ==================== Authentication APIs ====================
  static String get loginUrl => '$_baseUrl/auth/login';
  static String get registerUrl => '$_baseUrl/auth/register';
  static String get refreshTokenUrl => '$_baseUrl/auth/refresh';
  //  เพิ่ม OTP APIs
  static String get otpUrl => '$_baseUrl/auth/otp';
  static String get resetPasswordUrl => '$_baseUrl/auth/reset-password';
  // ==================== Device Connection APIs ====================
  static String get connectDeviceUrl => '$_baseUrl/devices/connect';
  static String get updateDeviceUsernameUrl => '$_baseUrl/devices/username';
  
  // ==================== Medication APIs (RESTful) ====================
  // GET /medications - ดึงรายการยาทั้งหมด  
  static String get getMedicationsUrl => '$_baseUrl/medications';
  
  // GET /medications/{id} - ดึงข้อมูลยา 1 รายการ
  static String getMedicationDetailUrl(String medicationId) => '$_baseUrl/medications/$medicationId';
  
  // GET /medications/{id}/edit - ดึงข้อมูลยาสำหรับแก้ไข
  static String getMedicationEditUrl(String medicationId) => '$_baseUrl/medications/$medicationId/edit';
  
  // POST /medications - สร้างยาใหม่
  static String get createMedicationUrl => '$_baseUrl/medications';
  
  // PUT /medications/{id} - อัพเดทข้อมูลยา  
  static String updateMedicationUrl(String medicationId) => '$_baseUrl/medications/$medicationId';
  
  // DELETE /medications/{id} - ลบข้อมูลยา
  static String deleteMedicationUrl(String medicationId) => '$_baseUrl/medications/$medicationId';
  
  // PUT /medications/{id}/timings - อัพเดทเวลากินยา
  static String updateMedicationTimingsUrl(String medicationId) => '$_baseUrl/medications/$medicationId/timings';

  // ==================== Dosage Forms API ====================
  static String get getDosageFormsUrl => '$_baseUrl/dosage-forms';

  // ==================== Reminder APIs ====================
  static String get getReminderUrl => '$_baseUrl/reminders';
  static String get getReminderSlotsUrl => '$_baseUrl/reminders/slots';
  static String get postReminderSlotsUrl => '$_baseUrl/reminders/slots';  // POST ใช้ endpoint เดียวกัน
  static String get getReminderLinksUrl => '$_baseUrl/reminders/links';   // ✅ แก้แล้ว: ตรงกับ Router
  static String get updateReminderStatusUrl => '$_baseUrl/reminders/status';
  static String get updateReminderUrl => '$_baseUrl/reminders/update';
  
  // ==================== History APIs ====================
  // ✅ แก้ไข: เปลี่ยนจาก /reminders/history เป็น /history
  static String get getReminderHistoryUrl => '$_baseUrl/history';
  static String getReminderHistoryDetailUrl(String historyId) => '$_baseUrl/history/$historyId';
  static String get getSummaryUrl => '$_baseUrl/history/summary';

  // ==================== Settings APIs ====================
  static String get getSettingsUrl => '$_baseUrl/settings';
  static String get updateVolumeSettingsUrl => '$_baseUrl/settings/volume';

  // ==================== Legacy URLs (Backward Compatibility) ====================
  // สำหรับ backward compatibility - แมปไปใช้ RESTful endpoints
  
  // Medication legacy mappings
  static String get getMedicationInfoUrl => getMedicationsUrl;
  static String get postMedicationCreateUrl => createMedicationUrl;
  
  // Reminder legacy mappings  
  static String get getMedicationLinksUrl => getReminderLinksUrl;  // ✅ แก้แล้ว: ชี้ไป reminders/links
  static String get getSlotReminderUrl => getReminderSlotsUrl;
  static String get postSlotReminderUrl => postReminderSlotsUrl;
  static String get updateAppStatusUrl => updateReminderStatusUrl;

  // Auth legacy mappings
  static String get updateUsernameUrl => updateDeviceUsernameUrl;  // ✅ แก้แล้ว: ใช้ devices/username

  // ==================== Helper Methods ====================
  
  /// สร้าง URL สำหรับ GET request ที่มี query parameters
  static String buildGetUrl(String endpoint, Map<String, String> queryParams) {
    if (queryParams.isEmpty) {
      return endpoint;
    }
    
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$endpoint?$queryString';
  }
  // ==================== Timeout Configuration ====================
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration uploadTimeout = Duration(seconds: 5);
  static const Duration authTimeout = Duration(seconds: 5);
  // ==================== Headers Configuration ====================
  
  /// Default headers สำหรับ API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Headers สำหรับ authenticated requests
  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
  

  // ==================== HTTP Method Information ====================
  
  /// ข้อมูลเกี่ยวกับ HTTP Methods ที่ใช้ในระบบ
  static const Map<String, String> httpMethodUsage = {
    'GET': 'ดึงข้อมูล (Safe & Idempotent)',
    'POST': 'สร้างข้อมูลใหม่ (Not Safe, Not Idempotent)',
    'PUT': 'อัพเดทข้อมูลทั้งหมด (Not Safe, Idempotent)',
    'PATCH': 'อัพเดทข้อมูลบางส่วน (Not Safe, Not Idempotent)',
    'DELETE': 'ลบข้อมูล (Not Safe, Idempotent)',
  };

  // ==================== Migration Helper ====================
  
  /// ตรวจสอบว่าใช้ RESTful API หรือ legacy API
  static bool get useRestfulApi => true;
  
  /// ดึง URL ที่เหมาะสมตาม mode ปัจจุบัน
  static String getApiUrl(String restfulUrl, String legacyUrl) {
    return useRestfulApi ? restfulUrl : legacyUrl;
  }

  // ==================== Endpoint Mapping ตาม Router ====================
  
  /// แมป endpoints ตาม Router structure จริง
  static const Map<String, List<String>> endpointMapping = {
    'auth': ['login', 'register', 'refresh'],                                           // ✅ ลบ username ออก  
    'medications': ['index', 'create', 'show/{id}', 'edit/{id}', 'update/{id}', 'delete/{id}', 'timings/{id}'],
    'reminders': ['index', 'slots', 'links', 'status'],     // ✅ แก้ไข: ลบ history ออก
    'history': ['index', 'show/{id}'],                      // ✅ เพิ่ม: history แยกต่างหาก
    'settings': ['index', 'volume'],
    'devices': ['connect', 'username'],                                                 // ✅ username อยู่ที่ devices
    'dosage-forms': ['index'],
  };

  /// ตรวจสอบว่า endpoint ที่ระบุมีอยู่ใน Router หรือไม่
  static bool isValidEndpoint(String category, String action) {
    return endpointMapping[category]?.contains(action) ?? false;
  }

  // ==================== Logging Helper ====================
  
  /// สำหรับ log API calls (ถ้ามี)
  static void logApiCall(String method, String url, {int? statusCode, String? responseBody}) {
  }
}