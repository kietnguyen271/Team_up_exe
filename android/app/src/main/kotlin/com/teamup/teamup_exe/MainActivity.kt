package com.teamup.teamup_exe

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                "teamup_notifications",
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = getString(R.string.notification_channel_description)
            manager.createNotificationChannel(channel)
        }
    }
}
