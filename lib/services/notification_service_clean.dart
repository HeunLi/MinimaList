import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_compatibility_service.dart';

@pragma('vm:entry-point')
void backgroundNotificationHandler(NotificationResponse? details) async {}

Future<void> onNotificationTapped(NotificationResponse? payload) async {}

// Global key for dialog context (if needed)
final GlobalKey<NavigatorState> dialogKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  // Constants
  static const channelId = "daily_reminders";
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled_clean';
  static const String _morningReminderEnabledKey = 'morning_reminder_enabled_clean';
  static const int _dailyReminderNotificationId = 1001;
  static const int _morningReminderNotificationId = 1002;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    channelId,
    "Daily Task Reminders",
    channelDescription: "Daily reminders to check your tasks",
    playSound: true,
    priority: Priority.high,
    importance: Importance.high,
    enableVibration: true,
    enableLights: true,
    icon: '@mipmap/ic_launcher',
  );

  static const DarwinNotificationDetails _darwinNotificationDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final NotificationDetails notificationDetails = const NotificationDetails(
    android: _androidNotificationDetails,
    iOS: _darwinNotificationDetails,
  );

  Future<NotificationResponse?> getInitialNotification() async {
    final launchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      return NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: launchDetails!.notificationResponse!.payload);
    }
    return null;
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Handle iOS foreground notifications (if needed)
    if (dialogKey.currentContext != null) {
      showDialog(
        context: dialogKey.currentContext!,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(title ?? ''),
          content: Text(body ?? ''),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
              },
            )
          ],
        ),
      );
    }
  }

  Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsDarwin,
    );

    // Initialize timezone with system local timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    debugPrint('✅ Notification service initialized');
  }

  Future<void> requestAndroidPermission() async {
    try {
      // Request basic notification permission only
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        debugPrint('✅ Android notification permissions requested');
      } else {
        debugPrint('❌ Android notification plugin not available');
      }
    } catch (e) {
      debugPrint('❌ Error requesting Android permissions: $e');
    }
  }

  Future<void> requestIOSPermissions() async {
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      debugPrint('✅ iOS notification permissions requested');
    } catch (e) {
      debugPrint('❌ Error requesting iOS permissions: $e');
    }
  }

  // Enhanced Android permission request for problematic devices (especially Huawei)
  Future<bool> _requestAndroidPermissionsEnhanced() async {
    try {
      // Initialize device compatibility service
      await DeviceCompatibilityService.initialize();

      debugPrint('🔧 HUAWEI DEBUG: Starting enhanced permission request');
      debugPrint('🔧 HUAWEI DEBUG: Device type: ${DeviceCompatibilityService.deviceType}');
      debugPrint('🔧 HUAWEI DEBUG: Android version: ${DeviceCompatibilityService.androidVersionInfo}');
      debugPrint('🔧 HUAWEI DEBUG: Is problematic device: ${DeviceCompatibilityService.isProblematicDevice}');
      debugPrint('🔧 HUAWEI DEBUG: Requires exact alarm: ${DeviceCompatibilityService.requiresExactAlarmPermission}');

      // First request basic notification permission
      debugPrint('🔧 HUAWEI DEBUG: Requesting basic notification permission...');
      await requestAndroidPermission();

      // Check basic notification status immediately
      final basicNotificationStatus = await Permission.notification.isGranted;
      debugPrint('🔧 HUAWEI DEBUG: Basic notification permission granted: $basicNotificationStatus');

      // Check if this is a problematic device
      if (DeviceCompatibilityService.isProblematicDevice) {
        debugPrint('🔧 HUAWEI DEBUG: Problematic device detected: ${DeviceCompatibilityService.deviceType}');

        // Request additional permissions for Huawei and other devices
        final permissions = <Permission>[
          Permission.notification,
          Permission.ignoreBatteryOptimizations,
        ];

        // Add exact alarm permission for Android 12+ / EMUI 12+
        if (DeviceCompatibilityService.requiresExactAlarmPermission) {
          permissions.add(Permission.scheduleExactAlarm);
          debugPrint('🔧 HUAWEI DEBUG: Adding exact alarm permission for ${DeviceCompatibilityService.androidVersionInfo}');
        }

        debugPrint('🔧 HUAWEI DEBUG: Requesting ${permissions.length} permissions...');

        // Request all permissions and capture detailed results
        Map<Permission, PermissionStatus> statuses = await permissions.request();

        debugPrint('🔧 HUAWEI DEBUG: Permission request results:');
        for (var entry in statuses.entries) {
          debugPrint('🔧 HUAWEI DEBUG:   ${entry.key}: ${entry.value}');
        }

        // Check critical permissions with detailed logging
        debugPrint('🔧 HUAWEI DEBUG: Checking final permission status...');

        bool hasNotification = await Permission.notification.isGranted;
        debugPrint('🔧 HUAWEI DEBUG: Final notification permission: $hasNotification');

        bool hasBatteryOptimization = await Permission.ignoreBatteryOptimizations.isGranted;
        debugPrint('🔧 HUAWEI DEBUG: Battery optimization exemption: $hasBatteryOptimization');

        bool hasExactAlarm = true;
        if (DeviceCompatibilityService.requiresExactAlarmPermission) {
          hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;
          debugPrint('🔧 HUAWEI DEBUG: Exact alarm permission: $hasExactAlarm');
        } else {
          debugPrint('🔧 HUAWEI DEBUG: Exact alarm permission not required for this Android version');
        }

        debugPrint('🔧 HUAWEI DEBUG: Final permission summary:');
        debugPrint('🔧 HUAWEI DEBUG:   - Notification: $hasNotification');
        debugPrint('🔧 HUAWEI DEBUG:   - Battery Optimization: $hasBatteryOptimization');
        debugPrint('🔧 HUAWEI DEBUG:   - Exact Alarm: $hasExactAlarm');

        // Determine if we have minimum requirements
        bool meetsMinimumRequirements = hasNotification;

        if (!hasNotification) {
          debugPrint('🔧 HUAWEI DEBUG: ❌ FAILURE REASON: Notification permission denied');
          return false;
        }

        if (!hasBatteryOptimization && DeviceCompatibilityService.deviceType == 'huawei') {
          debugPrint('🔧 HUAWEI DEBUG: ⚠️  WARNING: Battery optimization not disabled - notifications may be unreliable');
        }

        if (!hasExactAlarm && DeviceCompatibilityService.requiresExactAlarmPermission) {
          debugPrint('🔧 HUAWEI DEBUG: ⚠️  WARNING: Exact alarm permission denied - using inexact scheduling');
        }

        debugPrint('🔧 HUAWEI DEBUG: Minimum requirements met: $meetsMinimumRequirements');
        return meetsMinimumRequirements;
      } else {
        debugPrint('🔧 HUAWEI DEBUG: Standard device - checking basic notification permission only');
        final hasBasicNotification = await Permission.notification.isGranted;
        debugPrint('🔧 HUAWEI DEBUG: Basic notification result: $hasBasicNotification');
        return hasBasicNotification;
      }
    } catch (e) {
      debugPrint('🔧 HUAWEI DEBUG: ❌ EXCEPTION in permission request: $e');
      debugPrint('🔧 HUAWEI DEBUG: ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<void> showNotification(int id, String title, String body, String payload) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification(
      int id,
      String title,
      String body,
      DateTime eventDate,
      TimeOfDay eventTime,
      String payload,
      String time,
      int? hours,
      [DateTimeComponents? dateTimeComponents]) async {
    eventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);

    final scheduledTime = eventDate.add(Duration(
      hours: eventTime.hour,
      minutes: eventTime.minute,
    ));

    tz.TZDateTime nextInstanceOfTime() {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      if (time == 'daily') {
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      } else if (time == 'hourly') {
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(Duration(hours: hours!));
        }
      }
      return scheduledDate;
    }

    // Use appropriate scheduling mode based on device and permissions
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

    // For devices that require exact alarm permissions and have them granted
    if (Platform.isAndroid &&
        DeviceCompatibilityService.requiresExactAlarmPermission &&
        await Permission.scheduleExactAlarm.isGranted) {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      debugPrint('📱 Using exact scheduling mode for ${DeviceCompatibilityService.deviceType}');
    } else {
      debugPrint('📱 Using inexact scheduling mode');
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      nextInstanceOfTime(),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: scheduleMode,
      payload: payload,
      matchDateTimeComponents: dateTimeComponents,
    );
  }

  // Check if daily reminder is enabled
  Future<bool> isDailyReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dailyReminderEnabledKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking daily reminder status: $e');
      return false;
    }
  }

  // Check if morning reminder is enabled
  Future<bool> isMorningReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_morningReminderEnabledKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking morning reminder status: $e');
      return false;
    }
  }

  // Enable daily reminder at 8 PM
  Future<bool> enableDailyReminder() async {
    try {
      debugPrint('🔧 HUAWEI DEBUG: === ENABLE DAILY REMINDER START ===');

      // Enhanced permission check and request for problematic devices
      if (Platform.isAndroid) {
        debugPrint('🔧 HUAWEI DEBUG: Android platform - requesting enhanced permissions');
        final success = await _requestAndroidPermissionsEnhanced();
        debugPrint('🔧 HUAWEI DEBUG: Enhanced permissions result: $success');

        if (!success) {
          debugPrint('🔧 HUAWEI DEBUG: ❌ Failed to get required permissions for daily reminder');
          return false;
        }
      } else {
        debugPrint('🔧 HUAWEI DEBUG: iOS platform - requesting iOS permissions');
        await requestIOSPermissions();
      }

      debugPrint('🔧 HUAWEI DEBUG: Permissions granted, proceeding with scheduling');

      // Cancel existing daily reminder
      debugPrint('🔧 HUAWEI DEBUG: Cancelling existing daily reminder...');
      await flutterLocalNotificationsPlugin.cancel(_dailyReminderNotificationId);

      // Schedule daily notification at 8 PM
      debugPrint('🔧 HUAWEI DEBUG: Scheduling new daily reminder...');
      await _scheduleDailyReminder();

      // Save setting
      debugPrint('🔧 HUAWEI DEBUG: Saving daily reminder setting...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dailyReminderEnabledKey, true);

      debugPrint('🔧 HUAWEI DEBUG: ✅ Daily reminder enabled for 8 PM');
      debugPrint('🔧 HUAWEI DEBUG: === ENABLE DAILY REMINDER SUCCESS ===');
      return true;
    } catch (e) {
      debugPrint('🔧 HUAWEI DEBUG: ❌ Exception in enableDailyReminder: $e');
      debugPrint('🔧 HUAWEI DEBUG: ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Disable daily reminder
  Future<bool> disableDailyReminder() async {
    try {
      // Cancel the notification
      await flutterLocalNotificationsPlugin.cancel(_dailyReminderNotificationId);

      // Save setting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dailyReminderEnabledKey, false);

      debugPrint('✅ Daily reminder disabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling daily reminder: $e');
      return false;
    }
  }

  // Enable morning reminder at 11 AM
  Future<bool> enableMorningReminder() async {
    try {
      debugPrint('🔧 HUAWEI DEBUG: === ENABLE MORNING REMINDER START ===');

      // Enhanced permission check and request for problematic devices
      if (Platform.isAndroid) {
        debugPrint('🔧 HUAWEI DEBUG: Android platform - requesting enhanced permissions');
        final success = await _requestAndroidPermissionsEnhanced();
        debugPrint('🔧 HUAWEI DEBUG: Enhanced permissions result: $success');

        if (!success) {
          debugPrint('🔧 HUAWEI DEBUG: ❌ Failed to get required permissions for morning reminder');
          return false;
        }
      } else {
        debugPrint('🔧 HUAWEI DEBUG: iOS platform - requesting iOS permissions');
        await requestIOSPermissions();
      }

      debugPrint('🔧 HUAWEI DEBUG: Permissions granted, proceeding with scheduling');

      // Cancel existing morning reminder
      debugPrint('🔧 HUAWEI DEBUG: Cancelling existing morning reminder...');
      await flutterLocalNotificationsPlugin.cancel(_morningReminderNotificationId);

      // Schedule morning notification at 11 AM
      debugPrint('🔧 HUAWEI DEBUG: Scheduling new morning reminder...');
      await _scheduleMorningReminder();

      // Save setting
      debugPrint('🔧 HUAWEI DEBUG: Saving morning reminder setting...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_morningReminderEnabledKey, true);

      debugPrint('🔧 HUAWEI DEBUG: ✅ Morning reminder enabled for 11 AM');
      debugPrint('🔧 HUAWEI DEBUG: === ENABLE MORNING REMINDER SUCCESS ===');
      return true;
    } catch (e) {
      debugPrint('🔧 HUAWEI DEBUG: ❌ Exception in enableMorningReminder: $e');
      debugPrint('🔧 HUAWEI DEBUG: ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Disable morning reminder
  Future<bool> disableMorningReminder() async {
    try {
      // Cancel the notification
      await flutterLocalNotificationsPlugin.cancel(_morningReminderNotificationId);

      // Save setting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_morningReminderEnabledKey, false);

      debugPrint('✅ Morning reminder disabled');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling morning reminder: $e');
      return false;
    }
  }

  // Schedule daily reminder at 8 PM using the same approach as your example
  Future<void> _scheduleDailyReminder() async {
    final today = DateTime.now();
    final eventTime = const TimeOfDay(hour: 20, minute: 0); // 8 PM

    await scheduleNotification(
      _dailyReminderNotificationId,
      '📋 Task Check Time!',
      'Time to review your tasks and plan ahead',
      today,
      eventTime,
      'daily_reminder',
      'daily',
      null,
      DateTimeComponents.time, // Repeat daily
    );

    debugPrint('⏰ Daily reminder scheduled for 8 PM');
  }

  // Schedule morning reminder at 11 AM
  Future<void> _scheduleMorningReminder() async {
    final today = DateTime.now();
    final eventTime = const TimeOfDay(hour: 11, minute: 0); // 11 AM

    await scheduleNotification(
      _morningReminderNotificationId,
      '☀️ Morning Task Check!',
      'Good morning! Time to review your daily tasks',
      today,
      eventTime,
      'morning_reminder',
      'daily',
      null,
      DateTimeComponents.time, // Repeat daily
    );

    debugPrint('⏰ Morning reminder scheduled for 11 AM');
  }

  // Send test notification
  Future<bool> sendTestNotification() async {
    try {
      await showNotification(
        999,
        '🧪 Test Notification',
        'This is how your daily reminder will look!',
        'test_payload',
      );

      debugPrint('✅ Test notification sent');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotificationRequests;
  }

  // Get status for debugging
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final pendingNotifications = await getNotifications();
      return {
        'uses_simple_approach': true,
        'only_basic_permissions': true,
        'daily_reminder_enabled': await isDailyReminderEnabled(),
        'morning_reminder_enabled': await isMorningReminderEnabled(),
        'pending_notifications_count': pendingNotifications.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}