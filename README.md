# MinimaList

A beautiful, minimalist task management app built with Flutter that helps you stay organized with an elegant and intuitive interface.

## Features

### 📝 Task Management
- **Create & Edit Tasks**: Add tasks with titles, descriptions, due dates, and priority levels
- **Multiple Tags**: Organize tasks with a flexible tagging system
- **Priority Levels**: Set High, Medium, or Low priority for better task organization
- **Task Completion**: Mark tasks as complete with satisfying visual feedback

### 🎨 Beautiful Interface
- **Modern Design**: Clean, minimalist interface following Material Design 3
- **Dark/Light Theme**: Automatic system theme detection with manual override options
- **Smooth Animations**: Delightful animations throughout the app
- **Progressive Progress Indicator**: Floating progress widget that lights up as you complete tasks

### 🔍 Smart Search & Filtering
- **Real-time Search**: Search through task titles, descriptions, and tags
- **Tag Suggestions**: Floating tag suggestions appear while searching
- **Priority Filtering**: Filter tasks by priority level
- **Tag Filtering**: Filter tasks by specific tags
- **Active Filter Display**: Clear visual indication of active filters

### 📱 User Experience
- **Swipe Gestures**:
  - Swipe right to toggle task completion
  - Swipe left to delete tasks (with confirmation)
- **Quick Actions**: Tap to edit tasks, long-press for additional options
- **Floating Add Button**: Centrally positioned add button for quick task creation
- **Drawer Navigation**: Easy access to settings and filters

### 🔔 Notifications
- **Daily Reminders**: Simple daily notification system
- **Customizable Settings**: Configure notification preferences
- **Battery Optimization**: Handles device-specific battery optimization (Huawei, Xiaomi, etc.)

### 🎯 Progress Tracking
- **Visual Progress**: Beautiful floating progress widget showing completion percentage
- **Progressive Lighting**: Progress indicator becomes brighter as you complete more tasks
- **Detailed View**: Tap progress widget for detailed completion statistics
- **Completion Celebration**: Special animations and styling when all tasks are completed

## Technology Stack

- **Framework**: Flutter
- **Language**: Dart
- **Database**: SQLite with migration support
- **State Management**: Provider pattern
- **Architecture**: Clean architecture with separation of concerns

## Project Structure

```
lib/
├── models/          # Data models (Task, Tag)
├── providers/       # State management (TaskProvider, ThemeProvider)
├── screens/         # UI screens (HomeScreen, AddTaskScreen, etc.)
├── services/        # Business logic (DatabaseService, NotificationService)
└── widgets/         # Reusable UI components
```

## Key Components

### Models
- **Task**: Core task model with title, description, due date, priority, and tags
- **Tag**: Flexible tagging system with colors and metadata

### Providers
- **TaskProvider**: Manages task CRUD operations, filtering, and search
- **ThemeProvider**: Handles theme switching and persistence

### Services
- **DatabaseService**: SQLite database operations with migration support
- **NotificationService**: Cross-platform notification handling

### Widgets
- **TaskItem**: Individual task display with swipe gestures
- **FloatingProgressWidget**: Beautiful progress indicator with animations
- **AppDrawer**: Navigation drawer with settings and filters

## Database Schema

The app uses SQLite with automatic migrations:

### Tasks Table
- `id` (TEXT PRIMARY KEY)
- `title` (TEXT NOT NULL)
- `description` (TEXT)
- `is_completed` (INTEGER)
- `created_at` (TEXT)
- `due_date` (TEXT)
- `priority` (TEXT)

### Tags Table
- `id` (TEXT PRIMARY KEY)
- `name` (TEXT NOT NULL)
- `color` (TEXT)
- `created_at` (TEXT)

### Task-Tags Junction Table
- `task_id` (TEXT)
- `tag_id` (TEXT)

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Features in Detail

### Progressive Progress System
The floating progress widget implements a unique "progressive lighting" system:
- **0% Complete**: Dim appearance to encourage action
- **1-99% Complete**: Gradually increases in brightness and color saturation
- **100% Complete**: Full vibrant colors with celebration effects

### Smart Filtering
- **Text Search**: Searches across task titles, descriptions, and tag names
- **Tag Filtering**: Visual tag selection with real-time preview
- **Priority Filtering**: Quick access to high/medium/low priority tasks
- **Combined Filters**: Stack multiple filters for precise task organization

### Gesture Controls
- **Swipe Right**: Toggle task completion (mark done/undone)
- **Swipe Left**: Delete task (with confirmation dialog)
- **Tap**: Edit task details
- **Long Press**: Additional context actions

## Scheduled Notifications System

MinimaList implements a sophisticated notification system designed to work reliably across all Android devices, including problematic manufacturers like Huawei, Xiaomi, OnePlus, OPPO, and Vivo.

### Architecture Overview

The notification system consists of three main components:

#### 1. NotificationService (`notification_service_clean.dart`)
The core notification engine that handles:
- **Permission Management**: Cross-platform permission requests
- **Notification Scheduling**: Timezone-aware daily reminders
- **Device Compatibility**: Adaptive scheduling modes based on device capabilities
- **Persistence**: SharedPreferences integration for settings

#### 2. DeviceCompatibilityService (`device_compatibility_service.dart`)
Device-specific compatibility layer that provides:
- **Device Detection**: Identifies manufacturer and Android version
- **Permission Strategy**: Tailored permission requests per device type
- **Setup Instructions**: Device-specific configuration steps
- **Battery Optimization**: Automatic exemption requests

#### 3. NotificationSettingsScreen (`notification_settings_screen.dart`)
User interface for notification management:
- **Unified Controls**: Single toggle for daily reminders
- **Visual Feedback**: Real-time status updates
- **Device Guidance**: Automatic setup dialogs for problematic devices

### Implementation Details

#### Permission Handling
```dart
// Enhanced permission request for problematic devices
Future<bool> _requestAndroidPermissionsEnhanced() async {
  // Device-specific permission strategy
  final permissions = <Permission>[
    Permission.notification,                    // Basic notifications
    Permission.ignoreBatteryOptimizations,      // Battery exemption
  ];

  // Android 12+ exact alarm permissions
  if (DeviceCompatibilityService.requiresExactAlarmPermission) {
    permissions.add(Permission.scheduleExactAlarm);
  }

  // Request all permissions with detailed logging
  Map<Permission, PermissionStatus> statuses = await permissions.request();
}
```

#### Scheduling Strategy
```dart
// Adaptive scheduling based on device capabilities
AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

// Exact scheduling for compatible devices
if (Platform.isAndroid &&
    DeviceCompatibilityService.requiresExactAlarmPermission &&
    await Permission.scheduleExactAlarm.isGranted) {
  scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
}

await flutterLocalNotificationsPlugin.zonedSchedule(
  id, title, body, scheduledTime,
  notificationDetails,
  androidScheduleMode: scheduleMode,
  matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
);
```

#### Device-Specific Optimizations

**Huawei/Honor Devices:**
- Requests exact alarm permissions on EMUI 12+
- Provides step-by-step battery optimization instructions
- Handles HMS (Huawei Mobile Services) compatibility

**Xiaomi MIUI:**
- Autostart permission guidance
- MIUI-specific battery saver configuration
- Notification channel optimization

**OnePlus/OPPO/Vivo:**
- ColorOS and FunTouch OS compatibility
- Background app management instructions
- Device admin access guidance

### Notification Types

#### 1. Daily Evening Reminder (8:00 PM)
```dart
Future<void> _scheduleDailyReminder() async {
  await scheduleNotification(
    _dailyReminderNotificationId,
    '📋 Task Check Time!',
    'Time to review your tasks and plan ahead',
    today,
    const TimeOfDay(hour: 20, minute: 0),
    'daily_reminder',
    'daily',
    null,
    DateTimeComponents.time,
  );
}
```

#### 2. Morning Reminder (11:00 AM)
```dart
Future<void> _scheduleMorningReminder() async {
  await scheduleNotification(
    _morningReminderNotificationId,
    '☀️ Morning Task Check!',
    'Good morning! Time to review your daily tasks',
    today,
    const TimeOfDay(hour: 11, minute: 0),
    'morning_reminder',
    'daily',
    null,
    DateTimeComponents.time,
  );
}
```

### Reliability Features

#### Timezone Handling
```dart
// Automatic timezone detection and adjustment
tz.initializeTimeZones();
tz.setLocalLocation(tz.local);

tz.TZDateTime nextInstanceOfTime() {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

  // Handle next day scheduling
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}
```

#### Error Recovery
- **Graceful Degradation**: Falls back to inexact scheduling if exact permissions unavailable
- **Automatic Retry**: Reschedules failed notifications
- **Status Monitoring**: Real-time notification status tracking
- **Debug Logging**: Comprehensive logging for troubleshooting

#### Battery Optimization Bypass
```dart
// Request battery optimization exemption
static Future<Map<String, bool>> requestDeviceSpecificPermissions() async {
  Map<String, bool> permissions = {};

  permissions['ignoreBatteryOptimizations'] =
    await Permission.ignoreBatteryOptimizations.request().isGranted;

  // Device-specific additional permissions
  if (isProblematicDevice) {
    permissions['systemAlertWindow'] =
      await Permission.systemAlertWindow.request().isGranted;
  }

  return permissions;
}
```

### Cross-Platform Compatibility

#### iOS Integration
```dart
static const DarwinNotificationDetails _darwinNotificationDetails =
    DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);

Future<void> requestIOSPermissions() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}
```

#### Android Channel Configuration
```dart
static const AndroidNotificationDetails _androidNotificationDetails =
    AndroidNotificationDetails(
  "daily_reminders",
  "Daily Task Reminders",
  channelDescription: "Daily reminders to check your tasks",
  playSound: true,
  priority: Priority.high,
  importance: Importance.high,
  enableVibration: true,
  enableLights: true,
  icon: '@mipmap/ic_launcher',
);
```

### User Experience

#### Unified Settings Interface
- **Single Toggle**: Enable/disable both morning and evening reminders
- **Visual Status**: Real-time indication of notification state
- **Smart Guidance**: Automatic device-specific setup assistance

#### Proactive Device Setup
```dart
Future<void> _checkDeviceSetup() async {
  if (DeviceCompatibilityService.isProblematicDevice) {
    final hasSeenSetup = await DeviceCompatibilityService.hasSeenDeviceSetup();
    if (!hasSeenSetup && mounted) {
      DeviceCompatibilityService.showDeviceSetupDialog(context);
    }
  }
}
```

#### Test Functionality
```dart
Future<bool> sendTestNotification() async {
  await showNotification(
    999,
    '🧪 Test Notification',
    'This is how your daily reminder will look!',
    'test_payload',
  );
}
```

### Technical Specifications

#### Dependencies
- `flutter_local_notifications`: Core notification functionality
- `timezone`: Accurate timezone handling
- `permission_handler`: Cross-platform permissions
- `device_info_plus`: Device detection and compatibility
- `shared_preferences`: Settings persistence

#### Notification IDs
- Morning Reminder: `1002`
- Evening Reminder: `1001`
- Test Notification: `999`

#### Storage Keys
- Daily Reminder State: `daily_reminder_enabled_clean`
- Morning Reminder State: `morning_reminder_enabled_clean`
- Device Setup Status: `has_seen_device_setup_{deviceType}`

This comprehensive notification system ensures reliable task reminders across all devices while providing a seamless user experience and handling the complexities of modern Android power management systems.

## Contributing

This is a personal project, but suggestions and feedback are welcome! The codebase follows clean architecture principles and includes:

- Comprehensive error handling
- Database migrations for version updates
- Cross-platform notification support
- Responsive design for various screen sizes
- Accessibility considerations

## License

This project is for educational and personal use.

---

Built with ❤️ using Flutter
