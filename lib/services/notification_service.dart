import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      _initialized = false;
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse details) {
    debugPrint('Notification tapped: ${details.payload}');
    // TODO: Navigate to specific task or home screen
  }

  // Request notification permission
  static Future<bool> requestPermission() async {
    try {
      if (await Permission.notification.isGranted) {
        return true;
      }

      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Schedule notifications for a task
  static Future<void> scheduleTaskNotifications(Task task) async {
    try {
      if (!_initialized) await initialize();
      if (task.dueDate == null) {
        debugPrint('No due date for task: ${task.title}');
        return;
      }

      // Check if notifications are enabled
      if (!(await areNotificationsEnabled())) {
        debugPrint(
            'Notifications not enabled, skipping scheduling for task: ${task.title}');
        return;
      }

      // Cancel existing notifications for this task
      await cancelTaskNotifications(task.id);

      final now = DateTime.now();
      final dueDate = task.dueDate!;

      debugPrint(
          'Scheduling notifications for task: ${task.title}, due: $dueDate');

      // Don't schedule notifications for past due dates
      if (dueDate.isBefore(now)) {
        debugPrint('Due date is in the past, not scheduling: ${task.title}');
        return;
      }

      int notificationsScheduled = 0;

      // Schedule notification 1 day before (if due date is more than 1 day away)
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
          payload: 'task_reminder_${task.id}',
        );
        notificationsScheduled++;
        debugPrint('Scheduled day-before notification for: ${task.title}');
      }

      // Schedule notification on due date (morning - 9 AM)
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
          payload: 'task_due_${task.id}',
        );
        notificationsScheduled++;
        debugPrint('Scheduled due-date notification for: ${task.title}');
      }

      // Schedule overdue notification (day after due date - 10 AM)
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
        payload: 'task_overdue_${task.id}',
      );
      notificationsScheduled++;
      debugPrint('Scheduled overdue notification for: ${task.title}');

      debugPrint(
          'Total notifications scheduled for ${task.title}: $notificationsScheduled');
    } catch (e) {
      debugPrint('Error scheduling notifications for task ${task.title}: $e');
    }
  }

  // Cancel all notifications for a task
  static Future<void> cancelTaskNotifications(String taskId) async {
    try {
      if (!_initialized) await initialize();

      await _notifications.cancel(_getDayBeforeNotificationId(taskId));
      await _notifications.cancel(_getDueDateNotificationId(taskId));
      await _notifications.cancel(_getOverdueNotificationId(taskId));

      debugPrint('Cancelled notifications for task: $taskId');
    } catch (e) {
      debugPrint('Error cancelling notifications for task $taskId: $e');
    }
  }

  // Schedule a notification using inexact scheduling (Android 12+ friendly)
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Notifications for task due dates and reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'task_reminder',
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert to timezone-aware datetime
      final tz.TZDateTime scheduledTZ =
          tz.TZDateTime.from(scheduledDate, tz.local);

      // Use inexact scheduling to avoid "exact alarms not permitted" error
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode
            .inexactAllowWhileIdle, // This fixes the Android 12+ issue
      );

      debugPrint(
          'Successfully scheduled notification: $title for ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('Error scheduling single notification: $e');
    }
  }

  // Show immediate notification (for testing or instant feedback)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'instant_notifications',
        'Instant Notifications',
        channelDescription: 'Immediate notifications for user actions',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('Showed instant notification: $title');
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  // Schedule daily summary notification
  static Future<void> scheduleDailySummary() async {
    try {
      if (!_initialized) await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'daily_summary',
        'Daily Summary',
        channelDescription: 'Daily task summary notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule for 8 AM daily
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day, 8);
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        999999, // Unique ID for daily summary
        'Good Morning!',
        'Check your tasks for today',
        scheduledTZ,
        notificationDetails,
        payload: 'daily_summary',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode
            .inexactAllowWhileIdle, // Fixed: Use inexact scheduling
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Scheduled daily summary notification');
    } catch (e) {
      debugPrint('Error scheduling daily summary: $e');
    }
  }

  // Cancel daily summary
  static Future<void> cancelDailySummary() async {
    try {
      if (!_initialized) await initialize();
      await _notifications.cancel(999999);
      debugPrint('Cancelled daily summary notification');
    } catch (e) {
      debugPrint('Error cancelling daily summary: $e');
    }
  }

  // Get all pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      if (!_initialized) await initialize();
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('Found ${pending.length} pending notifications');
      return pending;
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      if (!_initialized) await initialize();
      await _notifications.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // Helper methods to generate unique notification IDs
  static int _getDayBeforeNotificationId(String taskId) {
    return (taskId.hashCode.abs() % 100000); // Ensure positive int
  }

  static int _getDueDateNotificationId(String taskId) {
    return ((taskId.hashCode.abs() % 100000) + 100000);
  }

  static int _getOverdueNotificationId(String taskId) {
    return ((taskId.hashCode.abs() % 100000) + 200000);
  }
}
