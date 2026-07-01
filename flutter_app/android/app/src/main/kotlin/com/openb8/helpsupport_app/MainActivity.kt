package com.openb8.helpsupport_app

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
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
                "setCallSpeakerEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    setCallSpeakerEnabled(enabled)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setCallSpeakerEnabled(enabled: Boolean) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (enabled) {
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            audioManager.isSpeakerphoneOn = true
        } else {
            audioManager.isSpeakerphoneOn = false
            audioManager.mode = AudioManager.MODE_NORMAL
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
        val isEmulator = isProbablyEmulator()

        return mapOf(
            "platform" to "android",
            "sdkInt" to Build.VERSION.SDK_INT,
            "isEmulator" to isEmulator,
            "vulkanHardwareVersion" to vulkanVersion,
            "vulkanVersionName" to "$vulkanMajor.$vulkanMinor.$vulkanPatch",
            "supportsVulkan11" to supportsVulkan11,
            "supportsGpuOffload" to (minSdkSatisfied && supportsVulkan11 && !isEmulator),
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

    private fun isProbablyEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val device = Build.DEVICE.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val kernelQemu = systemProperty("ro.kernel.qemu") == "1"
        val bootQemu = systemProperty("ro.boot.qemu") == "1"
        val egl = systemProperty("ro.hardware.egl").lowercase()
        val vulkan = systemProperty("ro.hardware.vulkan").lowercase()

        return fingerprint.startsWith("generic") ||
            fingerprint.contains("vbox") ||
            fingerprint.contains("test-keys") ||
            model.contains("emulator") ||
            model.contains("android sdk built for") ||
            model.contains("sdk_gphone") ||
            manufacturer.contains("genymotion") ||
            brand.startsWith("generic") ||
            device.startsWith("generic") ||
            product.contains("sdk") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            hardware.contains("vbox") ||
            kernelQemu ||
            bootQemu ||
            egl.contains("emulation") ||
            vulkan.contains("pastel") ||
            File("/dev/qemu_pipe").exists() ||
            File("/dev/socket/qemud").exists() ||
            File("/dev/bstpgaipc").exists()
    }

    private fun systemProperty(name: String): String {
        return try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val get = systemProperties.getMethod("get", String::class.java)
            get.invoke(null, name) as? String ?: ""
        } catch (_: Throwable) {
            ""
        }
    }

    private companion object {
        const val DEVELOPER_TOOLS_CHANNEL_NAME = "helpsupport/developer_tools"
    }
}
