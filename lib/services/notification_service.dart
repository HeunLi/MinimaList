import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _createNotificationChannels();
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse details) {
    // TODO: Navigate to specific task or home screen
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const highPriorityChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task due dates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    const dailyChannel = AndroidNotificationChannel(
      'daily_summary',
      'Daily Summary',
      description: 'Daily task summary notifications',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(highPriorityChannel);
    await androidPlugin.createNotificationChannel(dailyChannel);
  }

  // Request notification permissions
  static Future<bool> requestPermission() async {
    try {
      // Request notification permission
      final status = await Permission.notification.request();

      if (status.isGranted && Platform.isAndroid) {
        // Try to request exact alarm permission for scheduled notifications
        await Permission.scheduleExactAlarm.request();
        // Try to request battery optimization exemption
        await Permission.ignoreBatteryOptimizations.request();
      }

      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Schedule notifications for a task
  static Future<void> scheduleTaskNotifications(Task task) async {
    if (!_initialized) await initialize();

    if (task.dueDate == null) return;

    // Check if notifications are enabled
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) return;

    // Cancel existing notifications for this task
    await cancelTaskNotifications(task.id);

    final now = DateTime.now();
    final dueDate = task.dueDate!;

    // Don't schedule notifications for past due dates
    if (dueDate.isBefore(now)) return;

    // Schedule notification 1 day before (if applicable)
    final oneDayBefore = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      9, // 9 AM
    );

    if (oneDayBefore.isAfter(now)) {
      await _scheduleNotification(
        id: _getDayBeforeNotificationId(task.id),
        title: 'Task Due Tomorrow',
        body: task.title,
        scheduledDate: oneDayBefore,
      );
    }

    // Schedule notification on due date morning
    final dueDateMorning = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, // 9 AM
    );

    if (dueDateMorning.isAfter(now)) {
      await _scheduleNotification(
        id: _getDueDateNotificationId(task.id),
        title: 'Task Due Today',
        body: task.title,
        scheduledDate: dueDateMorning,
      );
    }

    // Schedule overdue notification
    final overdueDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day + 1,
      10, // 10 AM
    );

    await _scheduleNotification(
      id: _getOverdueNotificationId(task.id),
      title: 'Task Overdue',
      body: '${task.title} was due yesterday',
      scheduledDate: overdueDate,
    );
  }

  // Core scheduling method
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task due dates',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        playSound: true,
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

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Try exact scheduling first, fall back to inexact if needed
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.inexactAllowWhileIdle;

      if (Platform.isAndroid) {
        final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
        if (exactAlarmGranted) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        }
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Silently fail - notification might not be scheduled
    }
  }

  // Show immediate notification
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // Schedule daily summary
  static Future<void> scheduleDailySummary() async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Daily Summary',
      channelDescription: 'Daily task summary',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8);

    // If 8 AM has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      999999, // Unique ID for daily summary
      'Good Morning!',
      'Check your tasks for today',
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel daily summary
  static Future<void> cancelDailySummary() async {
    if (!_initialized) await initialize();
    await _notifications.cancel(999999);
  }

  // Cancel notifications for a task
  static Future<void> cancelTaskNotifications(String taskId) async {
    if (!_initialized) await initialize();

    await _notifications.cancel(_getDayBeforeNotificationId(taskId));
    await _notifications.cancel(_getDueDateNotificationId(taskId));
    await _notifications.cancel(_getOverdueNotificationId(taskId));
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  // Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    if (!_initialized) await initialize();

    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('Pending notifications: ${pending.length}');
    return pending;
  }

  // Helper methods to generate unique notification IDs
  static int _getDayBeforeNotificationId(String taskId) {
    return (taskId.hashCode.abs() % 100000);
  }

  static int _getDueDateNotificationId(String taskId) {
    return ((taskId.hashCode.abs() % 100000) + 100000);
  }

  static int _getOverdueNotificationId(String taskId) {
    return ((taskId.hashCode.abs() % 100000) + 200000);
  }
}
