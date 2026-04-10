package com.lockin.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import java.util.Calendar

class UsageStatsHandler(private val context: Context) {

    // ─── UsageStats権限チェック ──────────────────────────
    fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    // ─── アクセシビリティ権限チェック ────────────────────
    fun hasAccessibilityPermission(): Boolean {
        val serviceName = "${context.packageName}/.AccessibilityBlocker"
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabled)
        while (colonSplitter.hasNext()) {
            if (colonSplitter.next().equals(serviceName, ignoreCase = true)) return true
        }
        return false
    }

    // ─── 今日の総使用時間（分）──────────────────────────
    fun getTodayUsageMinutes(): Int {
        if (!hasUsageStatsPermission()) return 0

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val totalMs = stats?.filter { it.packageName != context.packageName }
            ?.sumOf { it.totalTimeInForeground } ?: 0L

        return (totalMs / 1000 / 60).toInt()
    }

    // ─── アプリ別使用時間（分）──────────────────────────
    fun getAppUsageMinutes(days: Int): Map<String, Int> {
        if (!hasUsageStatsPermission()) return emptyMap()

        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - days.toLong() * 24 * 60 * 60 * 1000

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return emptyMap()

        return stats
            .filter { it.packageName != context.packageName && it.totalTimeInForeground > 0 }
            .associate { it.packageName to (it.totalTimeInForeground / 1000 / 60).toInt() }
    }

    // ─── ブロック開始（AccessibilityService経由）────────
    fun startBlocking(packageNames: List<String>, durationMinutes: Int): Boolean {
        val intent = Intent(context, BlockingService::class.java).apply {
            action = BlockingService.ACTION_START
            putStringArrayListExtra(BlockingService.EXTRA_PACKAGES, ArrayList(packageNames))
            putExtra(BlockingService.EXTRA_DURATION, durationMinutes)
        }
        return try {
            context.startService(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ─── ブロック停止 ──────────────────────────────────
    fun stopBlocking(): Boolean {
        val intent = Intent(context, BlockingService::class.java).apply {
            action = BlockingService.ACTION_STOP
        }
        return try {
            context.startService(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ─── インストール済みアプリ一覧 ───────────────────
    fun getInstalledApps(): List<Map<String, String>> {
        val pm = context.packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        return apps
            .filter { (it.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) == 0 }
            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "label" to pm.getApplicationLabel(info).toString()
                )
            }
    }
}
