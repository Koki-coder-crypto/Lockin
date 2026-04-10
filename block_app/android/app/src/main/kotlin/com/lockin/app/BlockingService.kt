package com.lockin.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.os.IBinder
import android.os.Build
import androidx.core.app.NotificationCompat
import java.util.Timer
import java.util.TimerTask

class BlockingService : Service() {

    companion object {
        const val ACTION_START = "com.block.app.START_BLOCKING"
        const val ACTION_STOP = "com.block.app.STOP_BLOCKING"
        const val EXTRA_PACKAGES = "blocked_packages"
        const val EXTRA_DURATION = "duration_minutes"
        const val CHANNEL_ID = "block_service_channel"
        const val NOTIFICATION_ID = 1001
        const val PREFS_NAME = "block_prefs"
        const val KEY_BLOCKED_PACKAGES = "blocked_packages_json"
        const val KEY_IS_BLOCKING = "is_blocking"
    }

    private var durationTimer: Timer? = null
    private lateinit var prefs: SharedPreferences

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val packages = intent.getStringArrayListExtra(EXTRA_PACKAGES) ?: arrayListOf()
                val duration = intent.getIntExtra(EXTRA_DURATION, 0)
                startBlocking(packages, duration)
            }
            ACTION_STOP -> stopBlocking()
        }
        return START_STICKY
    }

    private fun startBlocking(packages: List<String>, durationMinutes: Int) {
        // 状態を保存（AccessibilityBlockerが読み取る）
        prefs.edit()
            .putStringSet(KEY_BLOCKED_PACKAGES, packages.toSet())
            .putBoolean(KEY_IS_BLOCKING, true)
            .apply()

        startForeground(NOTIFICATION_ID, buildNotification("ブロック中"))

        // 時間制限がある場合、タイマーで自動停止
        if (durationMinutes > 0) {
            durationTimer?.cancel()
            durationTimer = Timer()
            durationTimer?.schedule(object : TimerTask() {
                override fun run() {
                    stopBlocking()
                }
            }, durationMinutes.toLong() * 60 * 1000)
        }
    }

    private fun stopBlocking() {
        durationTimer?.cancel()
        prefs.edit()
            .remove(KEY_BLOCKED_PACKAGES)
            .putBoolean(KEY_IS_BLOCKING, false)
            .apply()
        stopForeground(true)
        stopSelf()
    }

    private fun buildNotification(text: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BLOCK")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "BLOCK サービス",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "ブロック実行中の通知"
        }
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        durationTimer?.cancel()
        super.onDestroy()
    }
}
