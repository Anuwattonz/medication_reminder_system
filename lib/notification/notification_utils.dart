import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationUtils {
  static const String timeZoneName = 'Asia/Bangkok';

  // ===== TIME PARSING METHODS =====

  /// Parse time string "HH:mm" to TimeOfDay
  static TimeOfDay? parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Invalid format
    }
    
    return null;
  }

  /// Format TimeOfDay to "HH:mm" string
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format TimeOfDay with unit
  static String formatTimeOfDayWithUnit(TimeOfDay time) {
    return '${formatTime(time)} น.';
  }

  // ===== DAY MANAGEMENT METHODS =====

  /// Get active days from days object
  static List<String> getActiveDays(dynamic days) {
    if (days == null) return [];
    
    final activeDays = <String>[];
    final dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    
    for (final dayName in dayNames) {
      final value = days[dayName];
      if (value == 1 || value == '1' || value == true) {
        activeDays.add(dayName);
      }
    }
    
    return activeDays;
  }

  /// Translate day name to Thai
  static String translateDayToThai(String dayName) {
    const dayMap = {
      'sunday': 'อาทิตย์',
      'monday': 'จันทร์', 
      'tuesday': 'อังคาร',
      'wednesday': 'พุธ',
      'thursday': 'พฤหัสบดี',
      'friday': 'ศุกร์',
      'saturday': 'เสาร์',
    };
    return dayMap[dayName.toLowerCase()] ?? dayName;
  }

  // ===== SCHEDULING METHODS =====

  /// Get next scheduled time for notification
  static tz.TZDateTime? getNextScheduledTime(TimeOfDay timeOfDay, List<String> activeDays) {
    if (activeDays.isEmpty) return null;

    final now = tz.TZDateTime.now(tz.getLocation(timeZoneName));
    final today = now.weekday % 7; // Convert to 0=Sunday format

    // Map day names to weekday numbers
    const dayToWeekday = {
      'sunday': 0,
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
    };

    // Convert active days to weekday numbers
    final activeWeekdays = activeDays
        .map((day) => dayToWeekday[day])
        .where((weekday) => weekday != null)
        .cast<int>()
        .toList();

    if (activeWeekdays.isEmpty) return null;

    // Try today first
    if (activeWeekdays.contains(today)) {
      final todayScheduled = tz.TZDateTime(
        tz.getLocation(timeZoneName),
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      
      if (todayScheduled.isAfter(now)) {
        return todayScheduled;
      }
    }

    // Find next available day
    for (int i = 1; i <= 7; i++) {
      final checkDay = (today + i) % 7;
      if (activeWeekdays.contains(checkDay)) {
        final nextDate = now.add(Duration(days: i));
        return tz.TZDateTime(
          tz.getLocation(timeZoneName),
          nextDate.year,
          nextDate.month,
          nextDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );
      }
    }

    return null;
  }

  // ===== SLOT MANAGEMENT METHODS =====

  /// Get meal name from slot number
  static String getMealName(int slot) {
    const mealNames = {
      1: 'เช้าก่อนอาหาร',
      2: 'เช้าหลังอาหาร', 
      3: 'กลางวันก่อนอาหาร',
      4: 'กลางวันหลังอาหาร',
      5: 'เย็นก่อนอาหาร',
      6: 'เย็นหลังอาหาร',
      7: 'ก่อนนอน',
    };
    return mealNames[slot] ?? 'ไม่ระบุเวลา';
  }

  /// Get int value safely
  static int getIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// แก้ไข createMedicationText - ให้แสดงข้อความทั่วไปแทนรายการยา
  static String createMedicationText(dynamic medicationLinks) {
    // ไม่ต้องแสดงรายการยาแล้ว แสดงข้อความทั่วไป
    return 'ถึงเวลารับประทานยาแล้ว';
  }

  // ===== VALIDATION METHODS =====

  /// แก้ไข hasValidData - ไม่ตรวจสอบ medicationLinks แล้ว
  static bool hasValidData(dynamic app) {
    return app.status.toString() == '1' && 
           getActiveDays(app.days).isNotEmpty && 
           parseTime(app.timing) != null;
           // ลบการตรวจสอบ medicationLinks ออก
  }

  /// Get active apps only
  static List<dynamic> getActiveApps(List<dynamic> apps) {
    return apps.where((app) => app.status.toString() == '1').toList();
  }

  /// Extract slot from notification ID
  static int extractSlot(int id) {
    return (id ~/ 100).clamp(1, 7);
  }

  // ===== NOTIFICATION CONTENT METHODS =====

  /// Create notification title - เอาอีโมตออก
  static String createNotificationTitle(String mealName) {
    return 'เวลารับประทานยาแล้ว - $mealName';
  }

  /// Create notification body (เดิม - ที่มีข้อมูลยา)
  static String createNotificationBody(TimeOfDay timeOfDay, String medicationText) {
    return '${formatTimeOfDayWithUnit(timeOfDay)}\n$medicationText';
  }

  /// Create notification body แบบง่าย - เอาอีโมตออก
  static String createNotificationBodySimple(TimeOfDay timeOfDay) {
    return '${formatTimeOfDayWithUnit(timeOfDay)}\nถึงเวลารับประทานยาแล้ว';
  }

  /// Get DateTimeComponents for scheduling
  static DateTimeComponents getDateTimeComponents(List<String> activeDays) {
    if (activeDays.length == 7) {
      return DateTimeComponents.time; // ทุกวัน เวลาเดิม
    } else {
      return DateTimeComponents.dayOfWeekAndTime; // เฉพาะวันที่เลือก
    }
  }

  // ===== HELPER METHODS =====

  /// Get slot number from meal name (helper method)
  static int getSlotFromMealName(String mealName) {
    const mealToSlot = {
      'เช้าก่อนอาหาร': 1,
      'เช้าหลังอาหาร': 2,
      'กลางวันก่อนอาหาร': 3,
      'กลางวันหลังอาหาร': 4,
      'เย็นก่อนอาหาร': 5,
      'เย็นหลังอาหาร': 6,
      'ก่อนนอน': 7,
    };
    return mealToSlot[mealName] ?? 1;
  }

  /// Create simple notification text (helper method)
  static String createSimpleNotificationText(String mealName, TimeOfDay timeOfDay) {
    return 'เวลา${getMealName(getSlotFromMealName(mealName))} ${formatTimeOfDayWithUnit(timeOfDay)}';
  }
}