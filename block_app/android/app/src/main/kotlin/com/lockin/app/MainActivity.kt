package com.lockin.app

import android.app.AppOpsManager
import android.content.Intent
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val usageStatsChannel = "com.lockin.app/usage_stats"
    private lateinit var usageStatsHandler: UsageStatsHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        usageStatsHandler = UsageStatsHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageStatsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageStatsPermission" -> {
                        result.success(usageStatsHandler.hasUsageStatsPermission())
                    }
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "hasAccessibilityPermission" -> {
                        result.success(usageStatsHandler.hasAccessibilityPermission())
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "getTodayUsageMinutes" -> {
                        result.success(usageStatsHandler.getTodayUsageMinutes())
                    }
                    "getAppUsageMinutes" -> {
                        val days = call.argument<Int>("days") ?: 1
                        result.success(usageStatsHandler.getAppUsageMinutes(days))
                    }
                    "startBlocking" -> {
                        val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                        val durationMinutes = call.argument<Int>("durationMinutes") ?: 0
                        val success = usageStatsHandler.startBlocking(packageNames, durationMinutes)
                        result.success(success)
                    }
                    "stopBlocking" -> {
                        val success = usageStatsHandler.stopBlocking()
                        result.success(success)
                    }
                    "getInstalledApps" -> {
                        result.success(usageStatsHandler.getInstalledApps())
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
