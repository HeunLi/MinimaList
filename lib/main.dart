import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.initialize();

  // Create notification channels for Android (especially important for Huawei)
  if (Platform.isAndroid) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Create high-priority channel for task reminders
    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task due dates and reminders',
      importance: Importance.max, // Maximum importance for Huawei
      enableVibration: true,
      enableLights: true,
      playSound: true,
      showBadge: true,
    );

    // Create channel for immediate notifications
    const AndroidNotificationChannel immediateChannel =
        AndroidNotificationChannel(
      'task_reminders_immediate',
      'Immediate Task Reminders',
      description: 'Immediate notifications for tasks',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Create channel for instant notifications
    const AndroidNotificationChannel instantChannel =
        AndroidNotificationChannel(
      'instant_notifications',
      'Instant Notifications',
      description: 'Immediate notifications for user actions',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Create channel for daily summary
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_summary',
      'Daily Summary',
      description: 'Daily task summary notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    // Create critical channel for Huawei devices
    const AndroidNotificationChannel criticalChannel =
        AndroidNotificationChannel(
      'task_reminders_critical',
      'Critical Task Reminders',
      description: 'High-priority notifications that bypass Do Not Disturb',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      showBadge: true,
      ledColor: Colors.red,
    );

    // Register all channels
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(taskChannel);
      await androidImplementation.createNotificationChannel(immediateChannel);
      await androidImplementation.createNotificationChannel(instantChannel);
      await androidImplementation.createNotificationChannel(dailyChannel);
      await androidImplementation.createNotificationChannel(criticalChannel);

      debugPrint('✅ All notification channels created successfully');
    }
  }

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskProvider(),
      child: MaterialApp(
        title: 'MinimaList',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
