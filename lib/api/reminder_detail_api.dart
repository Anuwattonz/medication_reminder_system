// ไฟล์: lib/api/reminder_detail_api.dart
import 'package:http/http.dart' as http;
import 'package:medication_reminder_system/config/api_config.dart';
import 'package:medication_reminder_system/api/api_helper.dart';

class ReminderSlotDetailApi {
  static Future<http.Response> getMedicationLinks({
    required String appId,
  }) async {
    final url = '${ApiConfig.getReminderLinksUrl}?app_id=$appId';
    final response = await ApiHelper.getWithTokenHandling(url);

    ApiConfig.logApiCall(
      'GET',
      url,
      statusCode: response.statusCode,
      responseBody: response.body,
    );

    return response;
  }
}

class SlotMedicationDetail {
  final int medicationLinkId;
  final int appId;
  final int medicationId;
  final double amount;
  final String medicationName;
  final String? picture;
  final String? pictureUrl;
  final String amountWithUnit;

  SlotMedicationDetail({
    required this.medicationLinkId,
    required this.appId,
    required this.medicationId,
    required this.amount,
    required this.medicationName,
    this.picture,
    this.pictureUrl,
    required this.amountWithUnit,
  });

  factory SlotMedicationDetail.fromJson(Map<String, dynamic> json) {
    return SlotMedicationDetail(
      medicationLinkId: int.tryParse(json['medication_link_id']?.toString() ?? '0') ?? 0,
      appId: int.tryParse(json['app_id']?.toString() ?? '0') ?? 0,
      medicationId: int.tryParse(json['medication_id']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      medicationName: json['medication_name']?.toString() ?? '',
      picture: json['picture']?.toString(),
      pictureUrl: json['picture_url']?.toString(),
      amountWithUnit: json['amount_with_unit']?.toString() ?? '0 เม็ด',
    );
  }

  String get displayName => medicationName;
  String get displayAmount => amountWithUnit;
}

class SlotDetailsResponse {
  final String status;
  final String message;
  final List<SlotMedicationDetail> medicationLinks;
  final AppInfo? appInfo;

  SlotDetailsResponse({
    required this.status,
    required this.message,
    required this.medicationLinks,
    this.appInfo,
  });

  factory SlotDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final linksJson = data['medication_links'] as List<dynamic>? ?? [];
    
    return SlotDetailsResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      medicationLinks: linksJson
          .map((item) => SlotMedicationDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
      appInfo: data['app_info'] != null 
          ? AppInfo.fromJson(data['app_info'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class AppInfo {
  final int appId;
  final int? pillSlot;
  final String? status;
  final String? timing;

  AppInfo({
    required this.appId,
    this.pillSlot,
    this.status,
    this.timing,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      appId: _parseToInt(json['app_id']) ?? 0,
      pillSlot: _parseToInt(json['pill_slot']),
      status: json['status']?.toString(),
      timing: json['timing']?.toString(),
    );
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool get hasSlotInfo => pillSlot != null && status != null && timing != null;
  bool get isActive => status == '1';
  String get statusText => isActive ? 'เปิดใช้งาน' : 'ปิดใช้งาน';
}