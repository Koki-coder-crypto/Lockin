package com.lockin.app

import android.accessibilityservice.AccessibilityService
import android.app.ActivityManager
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent

class AccessibilityBlocker : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private val blockScreenShown = mutableSetOf<String>()

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(BlockingService.PREFS_NAME, MODE_PRIVATE)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return

        // ウィンドウ切り替え時のみ処理
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val isBlocking = prefs.getBoolean(BlockingService.KEY_IS_BLOCKING, false)
        if (!isBlocking) {
            blockScreenShown.clear()
            return
        }

        val blockedPackages = prefs.getStringSet(BlockingService.KEY_BLOCKED_PACKAGES, emptySet())
        val packageName = event.packageName?.toString() ?: return

        // BLOCK自身・システムUIはスキップ
        if (packageName == applicationContext.packageName) return
        if (packageName == "com.android.systemui") return

        // ブロック対象かチェック（空 = 全アプリ）
        val shouldBlock = blockedPackages.isNullOrEmpty() || blockedPackages.contains(packageName)

        if (shouldBlock) {
            // ブロック画面（BLOCK自身）に移動してシールド表示
            launchBlockScreen(packageName)
        }
    }

    private fun launchBlockScreen(blockedPackage: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_by_accessibility", true)
            putExtra("blocked_package", blockedPackage)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        // サービス中断時のクリーンアップ
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences(BlockingService.PREFS_NAME, MODE_PRIVATE)
    }
}
