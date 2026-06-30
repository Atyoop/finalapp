package com.example.final88

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives BOOT_COMPLETED, QUICKBOOT_POWERON (Huawei/OnePlus), and
 * MY_PACKAGE_REPLACED broadcasts.
 *
 * Android wipes all AlarmManager exact alarms on reboot.
 * This receiver relaunches the app in the background (via a pending intent)
 * so that the Flutter startup flow in main.dart can re-fetch notification
 * schedules from the backend API and re-register all exact alarms.
 *
 * NOTE: The receiver has no android:permission attribute in the manifest —
 * that would prevent the Android system from delivering the broadcast.
 */
class NotificationBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        val action = intent?.action ?: return
        val ctx = context ?: return

        val isRelevant = action == Intent.ACTION_BOOT_COMPLETED ||
                action == "android.intent.action.QUICKBOOT_POWERON" ||
                action == Intent.ACTION_MY_PACKAGE_REPLACED

        if (!isRelevant) return

        Log.d(TAG, "📲 Boot/update detected ($action) — launching app to reschedule notifications")

        try {
            // Build a launch intent that brings the app to the foreground.
            // FLAG_ACTIVITY_NEW_TASK is required when starting an Activity from a non-Activity context.
            val launchIntent = ctx.packageManager
                .getLaunchIntentForPackage(ctx.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra(EXTRA_BOOT_RESCHEDULE, true)
                }

            if (launchIntent != null) {
                // Use a PendingIntent so we can launch even on Android 10+ background restrictions.
                val pending = PendingIntent.getActivity(
                    ctx,
                    REQUEST_CODE,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                pending.send()
                Log.d(TAG, "✅ App launch pending intent sent")
            } else {
                Log.e(TAG, "❌ Could not resolve launch intent for package ${ctx.packageName}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error launching app on boot: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "NotificationBootReceiver"
        private const val REQUEST_CODE = 8523
        const val EXTRA_BOOT_RESCHEDULE = "boot_reschedule"
    }
}
