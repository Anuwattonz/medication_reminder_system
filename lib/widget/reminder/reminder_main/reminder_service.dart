// ไฟล์: lib/services/reminder_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medication_reminder_system/api/reminder_api.dart';
import 'package:medication_reminder_system/notification/notification_service.dart';
import 'package:medication_reminder_system/widget/reminder/reminder_main/reminder_models.dart';

class ReminderService {
  
  /// ดึงข้อมูลยาจาก API
  static Future<ReminderDataResult> fetchMedicationData({
    required String userId,
    required String connectId,
  }) async {
    try {
      final response = await MedicationReminderApi.getMedicationData(
        userId: userId,
        connectId: connectId,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          List<AppModel> loadedApps = [];

          final appsData = data['data']?['apps'];
          if (appsData != null && appsData is List) {
            for (var appJson in appsData) {
              try {
                loadedApps.add(AppModel.fromJson(appJson));
              } catch (e) {
                debugPrint('Error parsing app data: $e');
              }
            }
          }

          loadedApps.sort((a, b) => a.pillSlot.compareTo(b.pillSlot));

          return ReminderDataResult.success(loadedApps);
        } else {
          return ReminderDataResult.error(
            data['message'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล'
          );
        }
      } else {
        return ReminderDataResult.error('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      return ReminderDataResult.error('Exception: $e');
    }
  }

  /// อัปเดตสถานะ slot
  static Future<SlotUpdateResult> updateSlotStatus({
    required String userId,
    required String connectId,
    required int pillSlot,
    required String status,
  }) async {
    try {
      final response = await MedicationReminderApi.updateSlotStatus(
        userId: userId,
        connectId: connectId,
        pillSlot: pillSlot,
        status: status,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          return SlotUpdateResult.success('เปลี่ยนสถานะสำเร็จ');
        } else {
          return SlotUpdateResult.error(
            data['message'] ?? 'เกิดข้อผิดพลาด'
          );
        }
      } else {
        return SlotUpdateResult.error('เกิดข้อผิดพลาดในการเชื่อมต่อ');
      }
    } catch (e) {
      return SlotUpdateResult.error('เกิดข้อผิดพลาด: $e');
    }
  }

  /// อัปเดต notifications แบบ background
  static Future<void> updateNotificationsInBackground(List<AppModel> appsList) async {
    try {
      await NotificationService.updateActiveSlotNotifications(appsList);
      debugPrint('✅ อัปเดตการแจ้งเตือนสำเร็จ - จำนวน apps: ${appsList.length}');
    } catch (e) {
      debugPrint('❌ ไม่สามารถอัปเดตการแจ้งเตือนได้: $e');
    }
  }

  /// อัปเดต notification สำหรับ slot เดียว
  static Future<void> updateSingleSlotNotification(AppModel app) async {
    try {
      await NotificationService.updateSingleSlotNotification(app);
      debugPrint('✅ อัปเดตการแจ้งเตือน Slot ${app.pillSlot}: ${app.isActive ? 'เปิด' : 'ปิด'}');
    } catch (e) {
      debugPrint('❌ ไม่สามารถอัปเดตการแจ้งเตือนสำหรับ Slot ${app.pillSlot}: $e');
    }
  }

  /// สร้าง smart filter สำหรับ slots
  static Set<int> createSmartFilter(List<AppModel> apps) {
    Set<int> activeSlotsWithData = {};
    
    for (var app in apps) {
      if (app.isActive) {
        activeSlotsWithData.add(app.pillSlot);
      }
    }
    
    if (activeSlotsWithData.isNotEmpty) {
      return activeSlotsWithData;
    } else {
      return {1, 2, 3, 4, 5, 6, 7};
    }
  }

  /// กรองข้อมูล apps ตาม selected slots
  static List<AppModel> filterAppsBySlots(List<AppModel> apps, Set<int> selectedSlots) {
    return apps.where((app) => selectedSlots.contains(app.pillSlot)).toList();
  }

  /// หา slot data จาก slot number
  static AppModel? findSlotData(List<AppModel> apps, int slot) {
    try {
      return apps.firstWhere((app) => app.pillSlot == slot);
    } catch (e) {
      return null;
    }
  }

  /// ตรวจสอบว่าสามารถเปิดใช้งาน slot ได้หรือไม่
  static bool canActivateSlot(AppModel app) {
    return app.hasMedications && app.hasActiveDays;
  }

  /// สร้าง updated AppModel หลังจากเปลี่ยน status
  static AppModel createUpdatedApp(AppModel originalApp, String newStatus) {
    bool updatedCanToggle = originalApp.hasMedications || originalApp.hasActiveDays;
    
    return originalApp.copyWith(
      status: newStatus,
      canToggle: updatedCanToggle,
    );
  }
}

// ==================== Result Classes ====================

class ReminderDataResult {
  final bool success;
  final List<AppModel>? data;
  final String? error;

  ReminderDataResult.success(this.data) : success = true, error = null;
  ReminderDataResult.error(this.error) : success = false, data = null;
}

class SlotUpdateResult {
  final bool success;
  final String message;

  SlotUpdateResult.success(this.message) : success = true;
  SlotUpdateResult.error(this.message) : success = false;
}