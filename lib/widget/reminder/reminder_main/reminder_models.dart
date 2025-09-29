// ไฟล์: lib/models/reminder_models.dart

class AppModel {
  final String appId;
  final String status;
  final String timing;
  final int pillSlot;
  final Map<String, dynamic> days;
  final List<MedicationLink> medicationLinks;
  final bool canToggle;
  final int medicationCount; // ✅ เพิ่ม field ใหม่
  final Map<String, dynamic>? debugInfo;

  AppModel({
    required this.appId,
    required this.status,
    required this.timing,
    required this.pillSlot,
    required this.days,
    required this.medicationLinks,
    required this.canToggle,
    required this.medicationCount, // ✅ เพิ่ม required parameter
    this.debugInfo,
  });

factory AppModel.fromJson(Map<String, dynamic> json) {
  List meds = json['medication_links'] ?? [];
  Map<String, dynamic> daysData = Map<String, dynamic>.from(json['days'] ?? {});
  
  bool hasMedications = meds.isNotEmpty;
  bool hasDaySettings = daysData.values.any((value) => 
    value == '1' || value == 1 || value == true
  );
  
  bool calculatedCanToggle = hasMedications || hasDaySettings || 
                            (json['can_toggle'] == true || json['can_toggle'] == 1);
  
  // ✅ แก้ไข: ให้แน่ใจว่า pillSlot เป็น int เสมอ
  int parsedPillSlot;
  final pillSlotValue = json['pill_slot'];
  
  if (pillSlotValue is int) {
    parsedPillSlot = pillSlotValue;
  } else if (pillSlotValue is String) {
    parsedPillSlot = int.tryParse(pillSlotValue) ?? 0;
  } else {
    parsedPillSlot = 0;
  }

  // ✅ เพิ่ม: parse medication_count จาก API
  int parsedMedicationCount = 0;
  final medicationCountValue = json['medication_count'];
  
  if (medicationCountValue is int) {
    parsedMedicationCount = medicationCountValue;
  } else if (medicationCountValue is String) {
    parsedMedicationCount = int.tryParse(medicationCountValue) ?? 0;
  } else {
    // ถ้าไม่มี medication_count ให้ใช้ length ของ medication_links แทน
    parsedMedicationCount = meds.length;
  }
  
  return AppModel(
    appId: json['app_id'].toString(),
    status: json['status'].toString(),
    timing: json['timing'].toString(),
    pillSlot: parsedPillSlot,
    days: daysData,
    medicationLinks: meds.map((e) => MedicationLink.fromJson(e)).toList(growable: false),
    canToggle: calculatedCanToggle,
    medicationCount: parsedMedicationCount, // ✅ เพิ่ม field ใหม่
    debugInfo: json['debug_info'] != null ? Map<String, dynamic>.from(json['debug_info']) : null,
  );
}

  // ✅ เพิ่ม utility methods
  bool get hasActiveDays {
    return days.values.any((value) => value == '1' || value == 1 || value == true);
  }

  bool get hasMedications {
    return medicationCount > 0; // ✅ ใช้ medicationCount แทน medicationLinks.isNotEmpty
  }

  bool get isActive {
    return status == '1';
  }

  String get displayTime {
    if (timing.isEmpty) return 'ไม่ระบุเวลา';
    
    String time = timing;
    time = time.replaceAll(RegExp(r'(\s*นาฬิกา|\s*น\.)'), '');

    if (time.contains(':')) {
      List<String> timeParts = time.split(':');
      if (timeParts.length >= 2) {
        time = '${timeParts[0]}:${timeParts[1]}';
      }
    }

    return time.trim();
  }

  String get activeDaysString {
    final dayMap = {
      'sunday': 'อา.',
      'monday': 'จ.',
      'tuesday': 'อ.',
      'wednesday': 'พ.',
      'thursday': 'พฤ.',
      'friday': 'ศ.',
      'saturday': 'ส.',
    };

    final activeDays = <String>[];
    days.forEach((day, value) {
      if (value == '1' || value == 1 || value == true) {
        activeDays.add(dayMap[day.toLowerCase()] ?? day);
      }
    });
    return activeDays.isEmpty ? 'ไม่มีกำหนด' : activeDays.join(', ');
  }

  // สร้าง copy ของ AppModel พร้อมเปลี่ยนค่าบางอย่าง
  AppModel copyWith({
    String? appId,
    String? status,
    String? timing,
    int? pillSlot,
    Map<String, dynamic>? days,
    List<MedicationLink>? medicationLinks,
    bool? canToggle,
    int? medicationCount, // ✅ เพิ่ม parameter ใหม่
    Map<String, dynamic>? debugInfo,
  }) {
    return AppModel(
      appId: appId ?? this.appId,
      status: status ?? this.status,
      timing: timing ?? this.timing,
      pillSlot: pillSlot ?? this.pillSlot,
      days: days ?? this.days,
      medicationLinks: medicationLinks ?? this.medicationLinks,
      canToggle: canToggle ?? this.canToggle,
      medicationCount: medicationCount ?? this.medicationCount, // ✅ เพิ่ม field ใหม่
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }
}

// ส่วนที่เหลือของ MedicationLink, SlotData classes ยังเหมือนเดิม
class MedicationLink {
  final String medicationLinkId;
  final String amount;
  final String medicationNickname;
  final String? timingName;
  final String? unitName;
  final String? unitVolumeMl;

  MedicationLink({
    required this.medicationLinkId,
    required this.amount,
    required this.medicationNickname,
    this.timingName,
    this.unitName,
    this.unitVolumeMl,
  });

  factory MedicationLink.fromJson(Map<String, dynamic> json) {
    return MedicationLink(
      medicationLinkId: json['medication_link_id'].toString(),
      amount: json['amount'].toString(),
      medicationNickname: json['medication_nickname'].toString(),
      timingName: json['timing_name']?.toString(),
      unitName: json['unit_name']?.toString(),
      unitVolumeMl: json['unit_volume_ml']?.toString(),
    );
  }

  String get displayName {
    return medicationNickname.isNotEmpty ? medicationNickname : 'ยา';
  }

  String get displayAmount {
    return '$amount ${unitName ?? 'หน่วย'}';
  }
}

class SlotData {
  final int appId;
  final int pillSlot;
  final String timing;
  final String status;
  final Map<String, dynamic> days;
  final List<dynamic> medicationLinks;
  final Map<String, dynamic>? debugInfo;

  SlotData({
    required this.appId,
    required this.pillSlot,
    required this.timing,
    required this.status,
    required this.days,
    required this.medicationLinks,
    this.debugInfo,
  });

  factory SlotData.fromAppModel(AppModel app) {
    return SlotData(
      appId: int.parse(app.appId),
      pillSlot: app.pillSlot,
      timing: app.timing,
      status: app.status,
      days: app.days,
      medicationLinks: app.medicationLinks.map((link) => {
        'medication_link_id': link.medicationLinkId,
        'amount': link.amount,
        'medication_nickname': link.medicationNickname,
        'timing_name': link.timingName,
        'unit_name': link.unitName,
        'unit_volume_ml': link.unitVolumeMl,
      }).toList(),
      debugInfo: app.debugInfo,
    );
  }
}