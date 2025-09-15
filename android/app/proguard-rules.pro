# Add project specific ProGuard rules here.

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-keep interface com.baseflow.permissionhandler.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Keep notification service classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Prevent obfuscation of notification classes
-keep class * extends android.app.NotificationManager
-keep class * extends androidx.core.app.NotificationManagerCompat

# Keep SharedPreferences
-keep class * extends android.content.SharedPreferences
-keep class * implements android.content.SharedPreferences