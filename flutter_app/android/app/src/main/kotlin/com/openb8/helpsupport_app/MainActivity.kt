package com.openb8.helpsupport_app

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVELOPER_TOOLS_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimeZone" -> result.success(TimeZone.getDefault().id)
                "getNotificationDiagnostics" -> result.success(notificationDiagnostics())
                "getLocalLlmDiagnostics" -> result.success(localLlmDiagnostics())
                else -> result.notImplemented()
            }
        }
    }

    private fun notificationDiagnostics(): Map<String, Any?> {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val canScheduleExactAlarms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
        val notificationsEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.areNotificationsEnabled()
        } else {
            true
        }
        return mapOf(
            "platform" to "android",
            "timeZoneIdentifier" to TimeZone.getDefault().id,
            "notificationsEnabled" to notificationsEnabled,
            "canScheduleExactAlarms" to canScheduleExactAlarms,
            "sdkInt" to Build.VERSION.SDK_INT,
        )
    }

    private fun localLlmDiagnostics(): Map<String, Any?> {
        val vulkanVersion = vulkanHardwareVersion()
        val vulkanMajor = vulkanVersion ushr 22
        val vulkanMinor = (vulkanVersion ushr 12) and 0x3ff
        val vulkanPatch = vulkanVersion and 0xfff
        val supportsVulkan11 = vulkanMajor > 1 || (vulkanMajor == 1 && vulkanMinor >= 1)
        val minSdkSatisfied = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P

        return mapOf(
            "platform" to "android",
            "sdkInt" to Build.VERSION.SDK_INT,
            "vulkanHardwareVersion" to vulkanVersion,
            "vulkanVersionName" to "$vulkanMajor.$vulkanMinor.$vulkanPatch",
            "supportsVulkan11" to supportsVulkan11,
            "supportsGpuOffload" to (minSdkSatisfied && supportsVulkan11),
        )
    }

    private fun vulkanHardwareVersion(): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return 0
        }
        return packageManager.systemAvailableFeatures
            .firstOrNull { it.name == PackageManager.FEATURE_VULKAN_HARDWARE_VERSION }
            ?.version ?: 0
    }

    private companion object {
        const val DEVELOPER_TOOLS_CHANNEL_NAME = "helpsupport/developer_tools"
    }
}
