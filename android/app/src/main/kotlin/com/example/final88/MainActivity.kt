package com.example.final88

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Flutter activity.
 *
 * Registers a MethodChannel ('com.example.final88/notifications') that Flutter
 * calls to request battery optimization exemption. Without this exemption,
 * Doze mode on most Android OEMs (Samsung, Xiaomi, Huawei, Oppo, etc.)
 * suppresses exact AlarmManager alarms — preventing scheduled notifications
 * from firing while the app is in the background.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.final88/notifications"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryOptimization" -> {
                    requestBatteryOptimizationExemption()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Opens the system "Battery Optimization" dialog for this app.
     *
     * - On Android 6+ (Marshmallow / API 23+): uses
     *   ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS to show a system dialog
     *   directly requesting the exemption.
     * - If the app is already exempted, the dialog is skipped silently.
     *
     * This is required so that exact alarms (set via AlarmManager with
     * ALLOW_WHILE_IDLE or EXACT_ALLOW_WHILE_IDLE) fire reliably when the
     * device is idle / in Doze mode.
     */
    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            val packageName = packageName

            if (pm.isIgnoringBatteryOptimizations(packageName)) {
                // Already exempted — nothing to do
                return
            }

            val intent = Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            ).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Some OEMs don't support this intent — ignore gracefully.
            // The user can still manually exempt the app in Settings.
        }
    }
}
