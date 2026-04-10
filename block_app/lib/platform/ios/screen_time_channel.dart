import 'dart:io';
import 'package:flutter/services.dart';

// ─── チャンネル名（Swift側と一致させる）─────────────────
const _channel = MethodChannel('com.lockin.app/screen_time');

// ─────────────────────────────────────────────────────────
// ScreenTimeChannel
//
// iOS FamilyControls / ManagedSettings へのDartインターフェース。
// Android では全メソッドがno-opになる。
// ─────────────────────────────────────────────────────────
class ScreenTimeChannel {
  ScreenTimeChannel._();
  static final instance = ScreenTimeChannel._();

  bool get _isIos => Platform.isIOS;

  // ─── 1. FamilyControls 認証リクエスト ─────────────────
  /// iOS Screen Time API へのアクセス権を要求する。
  /// 返り値: true = 承認済み, false = 拒否
  Future<bool> requestAuthorization() async {
    if (!_isIos) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } on PlatformException catch (e) {
      _log('requestAuthorization failed: ${e.message}');
      return false;
    }
  }

  // ─── 2. 認証済みか確認 ────────────────────────────────
  Future<bool> isAuthorized() async {
    if (!_isIos) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isAuthorized');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ─── 3. FamilyActivityPicker を表示 ──────────────────
  /// ネイティブのアプリ選択UIを表示する。
  /// 返り値: {'selectedCount': int} または null（キャンセル）
  Future<Map<String, dynamic>?> showAppPicker() async {
    if (!_isIos) return null;
    try {
      final result = await _channel.invokeMethod<Map>('showAppPicker');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      _log('showAppPicker failed: ${e.message}');
      return null;
    }
  }

  // ─── 4. アプリブロック開始 ────────────────────────────
  /// FamilyActivityPickerで選択したアプリにシールドを適用する。
  /// [durationMinutes]: 0 = 無制限, >0 = 指定分後に自動解除
  Future<bool> blockApps({int durationMinutes = 0}) async {
    if (!_isIos) return false;
    try {
      final result = await _channel.invokeMethod<bool>('blockApps', {
        'durationMinutes': durationMinutes,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log('blockApps failed: ${e.message}');
      return false;
    }
  }

  // ─── 5. ブロック解除 ──────────────────────────────────
  Future<bool> unblockApps() async {
    if (!_isIos) return false;
    try {
      final result = await _channel.invokeMethod<bool>('unblockApps');
      return result ?? false;
    } on PlatformException catch (e) {
      _log('unblockApps failed: ${e.message}');
      return false;
    }
  }

  // ─── 6. スケジュールブロック設定 ──────────────────────
  /// 毎日 [startHour]:[startMinute] 〜 [endHour]:[endMinute] に自動ブロック。
  Future<bool> scheduleBlock({
    required String scheduleId,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (!_isIos) return false;
    try {
      final result = await _channel.invokeMethod<bool>('scheduleBlock', {
        'scheduleId': scheduleId,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log('scheduleBlock failed: ${e.message}');
      return false;
    }
  }

  // ─── 7. スケジュールキャンセル ────────────────────────
  Future<bool> cancelSchedule(String scheduleId) async {
    if (!_isIos) return false;
    try {
      final result = await _channel.invokeMethod<bool>('cancelSchedule', {
        'scheduleId': scheduleId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log('cancelSchedule failed: ${e.message}');
      return false;
    }
  }

  // ─── 8. ブロック中アプリ数を取得 ─────────────────────
  Future<int> getBlockedAppCount() async {
    if (!_isIos) return 0;
    try {
      final result = await _channel.invokeMethod<int>('getBlockedApps');
      return result ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[ScreenTimeChannel] $msg');
  }
}
