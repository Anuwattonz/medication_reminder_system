import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/reminder_setting_api.dart';

class SlotSettingController {
  // State variables
  TimeOfDay? selectedTime;
  Map<String, bool> selectedDays = {};
  List<dynamic> availableMedications = [];
  List<dynamic> selectedMedications = [];
  List<dynamic> timingOptions = [];
  int? selectedTimingId;
  bool isLoading = false;
  int? cachedUserId;
  int? cachedConnectId;
  int? cachedAppId;
  bool _isDisposed = false;

  // Constants
  static const List<String> dayNames = [
    'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];
  
  static const List<String> dayLabels = [
    'อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'
  ];

  // Callback for UI updates
  VoidCallback? onStateChanged;

  // Constructor
  SlotSettingController({this.onStateChanged});

  // Dispose method
  void dispose() {
    _isDisposed = true;
  }

  // Safe state update
  void _safeNotifyListeners() {
    if (!_isDisposed && onStateChanged != null) {
      onStateChanged!();
    }
  }

  void initializeData({
    int? userId,
    int? connectId,
    dynamic slotData,
  }) {
    for (String day in dayNames) {
      selectedDays[day] = false;
    }
    cachedUserId = userId;
    cachedConnectId = connectId;
    _extractSlotDataInfo(slotData);
    _initializeTimeFromSlotData(slotData);
  }

  void _extractSlotDataInfo(dynamic slotData) {
    if (slotData != null) {
      try {
        final appModel = slotData;
        cachedAppId = int.tryParse(appModel.appId?.toString() ?? '0');
      } catch (e) {
        // Silent fail
      }
    }
  }

  void _initializeTimeFromSlotData(dynamic slotData) {
    try {
      String? timing;
      if (slotData != null) {
        timing = slotData.timing;
      }
      
      if (timing != null && timing.isNotEmpty) {
        final timeParts = timing.split(':');
        if (timeParts.length >= 2) {
          selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } else {
        selectedTime = const TimeOfDay(hour: 8, minute: 0);
      }
    } catch (e) {
      selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String? getTimingName() {
    if (selectedTimingId == null || timingOptions.isEmpty) return null;
    for (var timing in timingOptions) {
      if (timing['timing_id'] == selectedTimingId) {
        return timing['timing']?.toString();
      }
    }
    return null;
  }

  bool canSave() {
    return selectedTime != null && selectedDays.values.any((isSelected) => isSelected == true);
  }

  Future<String?> loadAllData() async {
    isLoading = true;
    _safeNotifyListeners();
    
    try {
      final appId = cachedAppId;
      if (appId == null) {
        throw Exception('ไม่พบข้อมูล app_id');
      }

      final response = await ReminderSettingApi.getAllSlotData(appId.toString());
      
      if (response['status'] == 'success') {
        _processAllData(response);
      } else {
        throw Exception(response['message'] ?? 'ไม่สามารถโหลดข้อมูลได้');
      }
      
      return null; // Success
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
    } finally {
      isLoading = false;
      _safeNotifyListeners();
    }
  }

  // เพิ่มฟังก์ชันสำหรับ debug ข้อมูลยา
  void debugMedicationData(Map<String, dynamic> med) {
    // Silent - no debug output
  }

  // เพิ่มฟังก์ชันแปลง amount
  double _parseAmount(dynamic amount) {
    if (amount is String) return double.tryParse(amount) ?? 1.0;
    if (amount is num) return amount.toDouble();
    return 1.0;
  }

  void _processAllData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data == null) return;

    // 1. Process timing options
    timingOptions = ReminderSettingApi.extractTimingOptions(response);
    
    // 2. Process app data
    final appData = ReminderSettingApi.extractAppData(response);
    if (appData != null) {
      final pillSlot = appData['pill_slot'];
      final timingId = int.tryParse(pillSlot?.toString() ?? '');
      selectedTimingId = (timingId != null && timingId > 0) ? timingId : null;
    }
    
    // 3. Process day settings
    final daySettings = ReminderSettingApi.extractDaySettings(response);
    for (int i = 0; i < dayNames.length; i++) {
      final dayKey = dayNames[i];
      selectedDays[dayKey] = (daySettings[dayKey] ?? 0) == 1;
    }
    
    // 4. Process medication links (existing medications)
    final medicationLinks = ReminderSettingApi.extractMedicationLinks(response);
    if (medicationLinks.isNotEmpty) {
      selectedMedications = medicationLinks.map<Map<String, dynamic>>((link) {
        return {
          'medication_id': link['medication_id'],
          'medication_nickname': link['medication_nickname'],
          'medication_name': link['medication_name'],
          'amount': _parseAmount(link['amount'] ?? 1), // แก้ตรงนี้
          'description': link['description'],
          'picture': link['picture'],
          'picture_url': link['picture_url'],
          'dosage_form': link['dosage_form'],
          'dosage_name': link['dosage_name'],
          'dosage_form_id': link['dosage_form_id'],
          'unit_type': link['unit_type'],
          'unit_type_name': link['unit_type_name'],
          'unit_type_id': link['unit_type_id'],
        };
      }).toList();
    }
    
    // 5. Process available medications
    final availableMedsRaw = ReminderSettingApi.extractAvailableMedications(response);
    availableMedications = availableMedsRaw.map<Map<String, dynamic>>((med) {
      return Map<String, dynamic>.from(med);
    }).toList();
    
    _safeNotifyListeners();
  }

  // Simplified methods since we now load everything at once
  Future<void> loadTimingOptions() async {
    // This is now handled by loadAllData()
    // Keeping for backward compatibility
  }

  void findMatchingTimingId() {
    // This is now handled by loadAllData()
    // Keeping for backward compatibility
  }

  Future<void> loadAvailableMedications() async {
    // This is now handled by loadAllData()
    // Keeping for backward compatibility
  }

  Future<void> loadExistingMedications() async {
    // This is now handled by loadAllData()
    // Keeping for backward compatibility
  }

  Future<void> loadCurrentDaySettings() async {
    // This is now handled by loadAllData()
    // Keeping for backward compatibility
  }

  // Time selection
  Future<void> selectTime(TimeOfDay newTime) async {
    selectedTime = newTime;
    _safeNotifyListeners();
  }

  void selectQuickTime(int hour, int minute) {
    selectedTime = TimeOfDay(hour: hour, minute: minute);
    _safeNotifyListeners();
  }

  // Medication management
  void addSelectedMedications(List<dynamic> newMedications) {
    for (var newMed in newMedications) {
      bool exists = selectedMedications.any((existing) => 
        existing['medication_id'] == newMed['medication_id']);
      
      if (!exists) {
        Map<String, dynamic> medicationToAdd = Map<String, dynamic>.from(newMed);
        medicationToAdd['amount'] = 1.0; // เปลี่ยนเป็น double
        selectedMedications.add(medicationToAdd);
      }
    }
    _safeNotifyListeners();
  }

  void updateMedicationAmount(int index, double newAmount) { // เปลี่ยนเป็น double
    if (newAmount <= 0) return;
    selectedMedications[index]['amount'] = newAmount;
    _safeNotifyListeners();
  }

  void removeMedication(int index) {
    selectedMedications.removeAt(index);
    _safeNotifyListeners();
  }

  // Day management
  void toggleDay(String dayKey) {
    selectedDays[dayKey] = !(selectedDays[dayKey] ?? false);
    _safeNotifyListeners();
  }

  void selectAllDays() {
    for (String day in dayNames) {
      selectedDays[day] = true;
    }
    _safeNotifyListeners();
  }

  void selectWeekdays() {
    for (int i = 0; i < dayNames.length; i++) {
      selectedDays[dayNames[i]] = i >= 1 && i <= 5;
    }
    _safeNotifyListeners();
  }

  void clearAllDays() {
    for (String day in dayNames) {
      selectedDays[day] = false;
    }
    _safeNotifyListeners();
  }

  // Utility methods
  String getMedicationUnit(Map<String, dynamic> med) {
    // ลำดับการเช็ค: unit_type_name -> unit_type -> dosage_name -> dosage_form -> default
    
    // 1. เช็ค unit_type_name จาก API
    String? unitTypeName = med['unit_type_name']?.toString();
    if (unitTypeName != null && unitTypeName.isNotEmpty && unitTypeName != 'null') {
      return unitTypeName;
    }
    
    // 2. เช็ค unit_type (field เดิม)
    String? unitType = med['unit_type']?.toString();
    if (unitType != null && unitType.isNotEmpty && unitType != 'null') {
      return unitType;
    }
    
    // 3. เช็ค dosage_name จาก API
    String? dosageName = med['dosage_name']?.toString();
    if (dosageName != null && dosageName.isNotEmpty && dosageName != 'null') {
      return dosageName;
    }
    
    // 4. เช็ค dosage_form (field เดิม)
    String? dosageForm = med['dosage_form']?.toString();
    if (dosageForm != null && dosageForm.isNotEmpty && dosageForm != 'null') {
      return dosageForm;
    }
    
    // 5. Default fallback
    return 'เม็ด';
  }

  Future<Map<String, dynamic>> saveSettings() async {
    if (!canSave()) {
      List<String> missingFields = [];
      if (selectedTime == null) missingFields.add('เวลา');
      if (!selectedDays.values.any((isSelected) => isSelected == true)) missingFields.add('วันที่กิน');
      
      return {
        'success': false,
        'message': 'กรุณาเลือก: ${missingFields.join(', ')}'
      };
    }

    final hasSelectedDay = selectedDays.values.any((isSelected) => isSelected == true);
    final hasMedications = selectedMedications.isNotEmpty;
    
    final appId = cachedAppId;
    if (appId == null) {
      return {
        'success': false,
        'message': 'ไม่พบข้อมูล app_id'
      };
    }

    isLoading = true;
    _safeNotifyListeners();

    try {
      final timeString = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

      final medicationsForApi = selectedMedications.map((med) {
        final medicationId = med['medication_id'];
        final amount = med['amount'] ?? 1.0; // default เป็น double
        
        if (medicationId == null || medicationId <= 0) {
          throw Exception('medication_id ไม่ถูกต้อง: $medicationId');
        }
        
        return {
          'medication_id': medicationId,
          'amount': amount, // ส่งเป็น double
        };
      }).toList();

      final data = await ReminderSettingApi.saveAllSettings(
        appId: appId,
        timing: timeString,
        timingId: selectedTimingId,
        days: selectedDays,
        medications: medicationsForApi,
      );
      
      String message = 'บันทึกการตั้งค่าสำเร็จ';
      bool isWarning = false;

      if (data['data'] != null && data['data']['app_status'] == 0) {
        isWarning = true;
      }
            
      return {
        'success': true,
        'message': message,
        'isWarning': isWarning,
        'app_status': data['data']?['app_status'],
        'needsConfirmation': !hasMedications || !hasSelectedDay
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการบันทึก: $e'
      };
    } finally {
      isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Check if settings need confirmation
  Map<String, dynamic> checkSettingsCompletion() {
    final hasSelectedDay = selectedDays.values.any((isSelected) => isSelected == true);
    final hasMedications = selectedMedications.isNotEmpty;
    
    if (!hasMedications || !hasSelectedDay) {
      List<String> incompleteItems = [];
      if (!hasMedications) incompleteItems.add('ไม่มีรายการยา');
      if (!hasSelectedDay) incompleteItems.add('ไม่เลือกวันที่กิน');
      
      return {
        'needsConfirmation': true,
        'title': 'ข้อมูลไม่ครบถ้วน',
        'message': 'การตั้งค่าจะถูกบันทึกแต่จะอยู่ในสถานะ "ปิดใช้งาน"\n\nสาเหตุ: ${incompleteItems.join(' และ ')}\n\nต้องการดำเนินการต่อหรือไม่?'
      };
    }
    
    return {'needsConfirmation': false};
  }
}