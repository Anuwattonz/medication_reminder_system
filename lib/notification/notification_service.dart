import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medication_reminder_system/notification/notification_utils.dart';

/// NotificationService - Clean version using NotificationUtils
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  static FlutterLocalNotificationsPlugin? _plugin;
  static bool _isInitialized = false;

  // Cache for active notifications to prevent duplicates
  static final Set<String> _activeNotifications = <String>{};

  // Constants
  static const String _channelId = 'medication_reminder_channel';
  static const String _channelName = 'การแจ้งเตือนยา';
  static const String _channelDescription = 'การแจ้งเตือนสำหรับการกินยาตามเวลาที่กำหนด';

  /// Initialize service once
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeTimeZone();

      _plugin = FlutterLocalNotificationsPlugin();
      await _createNotificationChannel();
      await _setupCallback();

      _isInitialized = true;
    } catch (e) {
      developer.log('❌ [NotificationService] Init error: $e');
      rethrow;
    }
  }

  /// Initialize timezone
  static Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(NotificationUtils.timeZoneName));
  }

  /// Create notification channel
  static Future<void> _createNotificationChannel() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _plugin!.initialize(initializationSettings);

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    await _plugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Setup notification callback
  static Future<void> _setupCallback() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin!.initialize(settings, onDidReceiveNotificationResponse: _onTapped);
  }

  /// Handle notification tap
  static void _onTapped(NotificationResponse response) {
    try {
      final id = response.id ?? 0;
      final slot = NotificationUtils.extractSlot(id);

      developer.log('👆 [NotificationService] User tapped notification slot: $slot');
    } catch (e) {
      developer.log('❌ [NotificationService] Tap error: $e');
    }
  }

  /// Update notifications for all active slots
  static Future<void> updateActiveSlotNotifications(List<dynamic> apps) async {
    if (!_isInitialized) await initialize();

    try {
      final activeApps = NotificationUtils.getActiveApps(apps);
      final activeSlots = activeApps.map((app) => NotificationUtils.getIntValue(app.pillSlot)).toSet();

      // Cancel inactive slots
      for (int slot = 1; slot <= 7; slot++) {
        if (!activeSlots.contains(slot)) {
          await _cancelSlot(slot);
        }
      }

      // Clear cache for memory efficiency
      _activeNotifications.clear();

      int successCount = 0;

      // Schedule active slots
      for (final app in activeApps) {
        final slot = NotificationUtils.getIntValue(app.pillSlot);
        await _cancelSlot(slot); // Clear existing

        if (await _scheduleSlot(app)) {
          successCount++;
        }
      }

      developer.log('✅ [NotificationService] Updated: $successCount notifications');
    } catch (e) {
      developer.log('❌ [NotificationService] Update error: $e');
    }
  }

  /// Update single slot notification
  static Future<void> updateSingleSlotNotification(dynamic app) async {
    if (!_isInitialized) await initialize();

    try {
      final slot = NotificationUtils.getIntValue(app.pillSlot);

      await _cancelSlot(slot);

      if (app.status.toString() == '1') {
        await _scheduleSlot(app);
      }
    } catch (e) {
      developer.log('❌ [NotificationService] Slot update error: $e');
    }
  }

  /// Schedule notifications for a slot (one notification per slot with multiple days)
  static Future<bool> _scheduleSlot(dynamic app) async {
    try {
      if (!NotificationUtils.hasValidData(app)) {
        return false;
      }

      final activeDays = NotificationUtils.getActiveDays(app.days);
      final timeOfDay = NotificationUtils.parseTime(app.timing);

      if (activeDays.isEmpty || timeOfDay == null) {
        return false;
      }

      final slot = NotificationUtils.getIntValue(app.pillSlot);
      final mealName = NotificationUtils.getMealName(slot);

      // Use single notification ID for the slot
      final notificationId = slot * 100; // Simple ID based on slot
      final cacheKey = 'slot_$slot';

      // Skip if already scheduled to prevent duplicates
      if (_activeNotifications.contains(cacheKey)) {
        return true;
      }

      if (await _createSingleNotification(notificationId, slot, timeOfDay, mealName, activeDays)) {
        _activeNotifications.add(cacheKey);
        return true;
      }

      return false;
    } catch (e) {
      developer.log('❌ [NotificationService] Schedule error: $e');
      return false;
    }
  }

static Future<bool> _createSingleNotification(
  int notificationId,
  int slot,
  TimeOfDay timeOfDay,
  String mealName,
  List<String> activeDays,
) async {
  try {
    // คำนวณวันถัดไปที่ตรงกับ activeDays
    final nextDate = NotificationUtils.getNextScheduledTime(timeOfDay, activeDays);

    if (nextDate == null) {
      developer.log('⚠️ [NotificationService] No valid nextDate for slot $slot');
      return false;
    }

    final title = 'เวลารับประทานยา\n$mealName';
    final body = '${NotificationUtils.formatTimeOfDayWithUnit(timeOfDay)}\nถึงเวลารับประทานยาแล้ว';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      ongoing: false,
      showWhen: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 0, 255, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'เวลารับประทานยาแล้ว',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'การแจ้งเตือนรับประทานยา',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    // ใช้ one-time scheduling → ไม่ใช้ matchDateTimeComponents
    try {
      developer.log('📅 Scheduling slot $slot at $nextDate [days=$activeDays]');
      await _plugin!.zonedSchedule(
        notificationId,
        title,
        body,
        nextDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
    } catch (e) {
      developer.log('⚠️ [NotificationService] exact schedule failed, fallback to inexact');
      await _plugin!.zonedSchedule(
        notificationId,
        title,
        body,
        nextDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
    }

    return true;
  } catch (e) {
    developer.log('❌ [NotificationService] Create single notification error: $e');
    return false;
  }
}


  /// Cancel notifications for specific slot
  static Future<void> _cancelSlot(int slot) async {
    try {
      // Cancel the single notification for this slot
      final id = slot * 100;
      await _plugin?.cancel(id);
      _activeNotifications.remove('slot_$slot');
    } catch (e) {
      developer.log('❌ [NotificationService] Cancel slot error: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _plugin?.cancelAll();
      _activeNotifications.clear();
    } catch (e) {
      developer.log('❌ [NotificationService] Cancel all error: $e');
    }
  }

  /// Check notification permission
  static Future<bool> checkNotificationPermission() async {
    if (!_isInitialized) await initialize();
    try {
      final result = await _plugin!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      developer.log('❌ [NotificationService] Permission check error: $e');
      return false;
    }
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    if (!_isInitialized) await initialize();
    try {
      final result = await _plugin!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    } catch (e) {
      developer.log('❌ [NotificationService] Permission request error: $e');
      return false;
    }
  }
}