package com.openb8.helpsupport_app

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
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

    private companion object {
        const val DEVELOPER_TOOLS_CHANNEL_NAME = "helpsupport/developer_tools"
    }
}
