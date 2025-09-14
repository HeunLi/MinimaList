import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Simple keys for settings
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const int _dailyReminderNotificationId = 1001;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);
      await _createNotificationChannel();
      _initialized = true;

      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      _initialized = false;
    }
  }

  // Create a simple notification channel
  static Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const channel = AndroidNotificationChannel(
      'daily_reminders',
      'Daily Task Reminders',
      description: 'Daily reminders to check your tasks',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(channel);
    debugPrint('✅ Notification channel created');
  }

  // Request notification permissions
  static Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();

      if (status.isGranted && Platform.isAndroid) {
        // Try to get additional permissions but don't fail if they're not granted
        await Permission.scheduleExactAlarm.request();
        await Permission.ignoreBatteryOptimizations.request();
      }

      debugPrint('📱 Notification permission: ${status.isGranted}');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  // Check if daily reminder is enabled
  static Future<bool> isDailyReminderEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dailyReminderEnabledKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking daily reminder status: $e');
      return false;
    }
  }

  // Enable daily reminder at 8 PM
  static Future<bool> enableDailyReminder() async {
    try {
      if (!_initialized) await initialize();

      // Check permissions first
      final hasPermission = await Permission.notification.isGranted;
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      // Schedule the daily notification
      await _scheduleDailyReminder();

      // Save setting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dailyReminderEnabledKey, true);

      debugPrint('✅ Daily reminder enabled for 8 PM');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling daily reminder: $e');
      return false;
    }
  }

  // Disable daily reminder
  static Future<bool> disableDailyReminder() async {
    try {
      if (!_initialized) await initialize();

      // Cancel the notification
      await _notifications.cancel(_dailyReminderNotificationId);

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

  // Schedule the daily reminder at 8 PM
  static Future<void> _scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Task Reminders',
      channelDescription: 'Daily reminders to check your tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate next 8 PM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 20); // 8 PM

    // If 8 PM has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      _dailyReminderNotificationId,
      '📋 Task Check Time!',
      'Time to review your tasks and plan ahead',
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    debugPrint('⏰ Daily reminder scheduled for: $scheduledDate');
  }

  // Send a test notification
  static Future<bool> sendTestNotification() async {
    try {
      if (!_initialized) await initialize();

      const androidDetails = AndroidNotificationDetails(
        'daily_reminders',
        'Daily Task Reminders',
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999,
        '🧪 Test Notification',
        'This is how your daily reminder will look!',
        details,
      );

      debugPrint('✅ Test notification sent');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }

  // Get simple status for debugging
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      return {
        'initialized': _initialized,
        'permission_granted': await Permission.notification.isGranted,
        'daily_reminder_enabled': await isDailyReminderEnabled(),
        'exact_alarm_permission': await Permission.scheduleExactAlarm.isGranted,
        'battery_optimization_disabled': await Permission.ignoreBatteryOptimizations.isGranted,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}