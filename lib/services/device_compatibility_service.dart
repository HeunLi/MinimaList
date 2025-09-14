import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DeviceCompatibilityService {
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static String? _manufacturer;
  static String? _model;
  static String? _androidVersion;
  static int? _androidSdkInt;
  static bool _isInitialized = false;

  // Initialize device info
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (Platform.isAndroid) {
      try {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _manufacturer = androidInfo.manufacturer.toLowerCase();
        _model = androidInfo.model;
        _androidVersion = androidInfo.version.release;
        _androidSdkInt = androidInfo.version.sdkInt;
        _isInitialized = true;
        debugPrint('Device: $_manufacturer $_model (Android $_androidVersion, SDK $_androidSdkInt)');
      } catch (e) {
        debugPrint('Error getting device info: $e');
      }
    }
  }

  // Check if device is problematic for notifications
  static bool get isProblematicDevice {
    if (!_isInitialized) return false;

    return _manufacturer != null && (
      _manufacturer!.contains('huawei') ||
      _manufacturer!.contains('honor') ||
      _manufacturer!.contains('xiaomi') ||
      _manufacturer!.contains('oppo') ||
      _manufacturer!.contains('vivo') ||
      _manufacturer!.contains('oneplus')
    );
  }

  // Get specific device type
  static String get deviceType {
    if (_manufacturer == null) return 'unknown';

    if (_manufacturer!.contains('huawei') || _manufacturer!.contains('honor')) {
      return 'huawei';
    } else if (_manufacturer!.contains('xiaomi')) {
      return 'xiaomi';
    } else if (_manufacturer!.contains('oppo')) {
      return 'oppo';
    } else if (_manufacturer!.contains('vivo')) {
      return 'vivo';
    } else if (_manufacturer!.contains('oneplus')) {
      return 'oneplus';
    }

    return 'standard';
  }

  // Check if device requires exact alarm permissions (Android 12+ / SDK 31+)
  static bool get requiresExactAlarmPermission {
    return _androidSdkInt != null && _androidSdkInt! >= 31;
  }

  // Get Android version info
  static String get androidVersionInfo {
    if (_androidVersion != null && _androidSdkInt != null) {
      return 'Android $_androidVersion (SDK $_androidSdkInt)';
    }
    return 'Unknown Android version';
  }

  // Get device-specific instructions
  static List<String> getDeviceSpecificInstructions() {
    switch (deviceType) {
      case 'huawei':
        return [
          'Go to Settings > Apps > Apps',
          'Find "MinimaList" app',
          'Tap "Battery" > App launch',
          'Enable "Manage manually"',
          'Enable all three options: Auto-launch, Secondary launch, Run in background',
          'Go to Settings > Battery > More battery settings',
          'Turn off "Optimize battery usage" for MinimaList',
          'Add MinimaList to "Protected apps" if available',
          'IMPORTANT: On EMUI 12+ devices, grant "Schedule exact alarms" permission when prompted',
        ];
      case 'xiaomi':
        return [
          'Go to Settings > Apps > Manage apps',
          'Find "MinimaList" app',
          'Tap "Battery saver" > No restrictions',
          'Enable "Autostart"',
          'Go to Settings > Notifications > MinimaList',
          'Enable all notification settings',
        ];
      case 'oppo':
        return [
          'Go to Settings > Battery > Battery optimisation',
          'Find MinimaList and set to "Don\'t optimise"',
          'Go to Settings > Privacy permissions > Startup manager',
          'Enable MinimaList to start automatically',
        ];
      case 'vivo':
        return [
          'Go to Settings > Battery > Background app refresh',
          'Enable MinimaList',
          'Go to Settings > More settings > Permission management > Autostart',
          'Enable MinimaList',
        ];
      case 'oneplus':
        return [
          'Go to Settings > Battery > Battery optimisation',
          'Find MinimaList and select "Don\'t optimise"',
          'Go to Settings > Apps & notifications > Special app access > Device admin apps',
          'Enable background activity for MinimaList',
        ];
      default:
        return [
          'Go to Settings > Apps > MinimaList',
          'Disable battery optimization',
          'Enable all notification permissions',
          'Allow background app refresh',
        ];
    }
  }

  // Check if user has seen device-specific setup
  static Future<bool> hasSeenDeviceSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_device_setup_${deviceType}') ?? false;
  }

  // Mark device setup as seen
  static Future<void> markDeviceSetupAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_device_setup_${deviceType}', true);
  }

  // Get device-specific warning message
  static String get deviceWarningMessage {
    switch (deviceType) {
      case 'huawei':
        return 'Huawei devices have strict power management. Please follow the setup steps to ensure notifications work properly.';
      case 'xiaomi':
        return 'MIUI has aggressive battery optimization. Please configure autostart and notification settings.';
      case 'oppo':
      case 'vivo':
      case 'oneplus':
        return 'Your device has strict battery optimization. Please disable it for MinimaList to receive notifications.';
      default:
        return 'For reliable notifications, please disable battery optimization for this app.';
    }
  }

  // Request all necessary permissions for device type
  static Future<Map<String, bool>> requestDeviceSpecificPermissions() async {
    Map<String, bool> permissions = {};

    // Standard permissions
    permissions['notification'] = await Permission.notification.request().isGranted;
    permissions['scheduleExactAlarm'] = await Permission.scheduleExactAlarm.request().isGranted;
    permissions['ignoreBatteryOptimizations'] = await Permission.ignoreBatteryOptimizations.request().isGranted;

    // Device-specific permissions
    if (Platform.isAndroid) {
      // Try to request system alert window for critical notifications
      try {
        permissions['systemAlertWindow'] = await Permission.systemAlertWindow.request().isGranted;
      } catch (e) {
        permissions['systemAlertWindow'] = false;
      }

      // Try to request phone permission for higher priority (some devices need this)
      try {
        permissions['phone'] = await Permission.phone.request().isGranted;
      } catch (e) {
        permissions['phone'] = false;
      }
    }

    return permissions;
  }

  // Show device-specific setup dialog
  static Future<bool?> showDeviceSetupDialog(BuildContext context) async {
    if (!isProblematicDevice) return true;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Device Setup Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceWarningMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Follow these steps:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...getDeviceSpecificInstructions().map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: Theme.of(context).textTheme.bodySmall),
                    Expanded(
                      child: Text(
                        instruction,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Without these settings, you may not receive task reminders!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              markDeviceSetupAsSeen();
              Navigator.of(context).pop(false);
            },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () async {
              await openAppSettings();
              markDeviceSetupAsSeen();
              Navigator.of(context).pop(true);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Get manufacturer-specific app settings intent
  static Future<void> openDeviceSpecificSettings() async {
    await openAppSettings();
  }
}