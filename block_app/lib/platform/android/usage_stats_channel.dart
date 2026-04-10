import 'dart:io';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.lockin.app/usage_stats');

// ─────────────────────────────────────────────────────────
// UsageStatsChannel
//
// Android UsageStatsManager / AccessibilityService への
// Dartインターフェース。iOS では全メソッドがno-opになる。
// ─────────────────────────────────────────────────────────
class UsageStatsChannel {
  UsageStatsChannel._();
  static final instance = UsageStatsChannel._();

  bool get _isAndroid => Platform.isAndroid;

  // ─── 1. UsageStats権限の確認 ──────────────────────────
  Future<bool> hasUsageStatsPermission() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ─── 2. UsageStats設定画面を開く ──────────────────────
  Future<void> openUsageAccessSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException catch (e) {
      _log('openUsageAccessSettings failed: ${e.message}');
    }
  }

  // ─── 3. アクセシビリティ権限の確認 ───────────────────
  Future<bool> hasAccessibilityPermission() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('hasAccessibilityPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ─── 4. アクセシビリティ設定画面を開く ───────────────
  Future<void> openAccessibilitySettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      _log('openAccessibilitySettings failed: ${e.message}');
    }
  }

  // ─── 5. 今日の使用時間を取得（分単位）────────────────
  Future<int> getTodayUsageMinutes() async {
    if (!_isAndroid) return 0;
    try {
      final result = await _channel.invokeMethod<int>('getTodayUsageMinutes');
      return result ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  // ─── 6. アプリ別使用時間マップ ───────────────────────
  Future<Map<String, int>> getAppUsageMinutes({int days = 1}) async {
    if (!_isAndroid) return {};
    try {
      final result = await _channel.invokeMethod<Map>('getAppUsageMinutes', {
        'days': days,
      });
      if (result == null) return {};
      return Map<String, int>.from(result);
    } on PlatformException {
      return {};
    }
  }

  // ─── 7. ブロック開始（AccessibilityService経由）──────
  Future<bool> startBlocking({
    required List<String> packageNames,
    required int durationMinutes,
  }) async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('startBlocking', {
        'packageNames': packageNames,
        'durationMinutes': durationMinutes,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log('startBlocking failed: ${e.message}');
      return false;
    }
  }

  // ─── 8. ブロック停止 ──────────────────────────────────
  Future<bool> stopBlocking() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('stopBlocking');
      return result ?? false;
    } on PlatformException catch (e) {
      _log('stopBlocking failed: ${e.message}');
      return false;
    }
  }

  // ─── 9. インストール済みアプリ一覧 ───────────────────
  Future<List<Map<String, String>>> getInstalledApps() async {
    if (!_isAndroid) return [];
    try {
      final result = await _channel.invokeMethod<List>('getInstalledApps');
      if (result == null) return [];
      return result.map((e) => Map<String, String>.from(e as Map)).toList();
    } on PlatformException {
      return [];
    }
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[UsageStatsChannel] $msg');
  }
}
