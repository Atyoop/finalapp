package com.example.final88

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED || 
            intent?.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d("NotificationBootReceiver", "🔄 Device boot detected - rescheduling notifications")
            // The app will handle rescheduling when it starts
            // This is handled by the NotificationService in Flutter
        }
    }
}
