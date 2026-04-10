import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_session.dart';
import '../../core/constants/app_constants.dart';

class BlockRepository {
  static const _keySessionsPrefix = 'block_sessions_';
  static const _keyActiveSession = 'active_block_session';

  // ─── セッション保存 ────────────────────────────────────
  Future<void> saveSession(BlockSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _dateKey(session.startedAt);
    final existing = await getSessionsForDate(session.startedAt);
    final idx = existing.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      existing[idx] = session;
    } else {
      existing.add(session);
    }
    await prefs.setString(
      '$_keySessionsPrefix$dateKey',
      BlockSession.encodeList(existing),
    );
  }

  // ─── アクティブセッション ──────────────────────────────
  Future<void> setActiveSession(BlockSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session == null) {
      await prefs.remove(_keyActiveSession);
    } else {
      await prefs.setString(_keyActiveSession, BlockSession.encodeList([session]));
    }
  }

  Future<BlockSession?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActiveSession);
    if (raw == null) return null;
    final list = BlockSession.decodeList(raw);
    return list.isEmpty ? null : list.first;
  }

  // ─── 日別セッション取得 ───────────────────────────────
  Future<List<BlockSession>> getSessionsForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keySessionsPrefix${_dateKey(date)}');
    if (raw == null) return [];
    return BlockSession.decodeList(raw);
  }

  // ─── 過去N日のセッション取得 ──────────────────────────
  Future<List<BlockSession>> getSessionsForDays(int days) async {
    final result = <BlockSession>[];
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      result.addAll(await getSessionsForDate(date));
    }
    return result;
  }

  // ─── 今日のNOW BLOCK使用回数 ──────────────────────────
  Future<int> getTodayNowBlockCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final lastDate = prefs.getString(AppConstants.keyNowBlockDate) ?? '';
    if (lastDate != today) {
      await prefs.setString(AppConstants.keyNowBlockDate, today);
      await prefs.setInt(AppConstants.keyNowBlockUsedToday, 0);
      return 0;
    }
    return prefs.getInt(AppConstants.keyNowBlockUsedToday) ?? 0;
  }

  Future<void> incrementNowBlockCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    await prefs.setString(AppConstants.keyNowBlockDate, today);
    final current = prefs.getInt(AppConstants.keyNowBlockUsedToday) ?? 0;
    await prefs.setInt(AppConstants.keyNowBlockUsedToday, current + 1);
  }

  // ─── ストリーク管理 ───────────────────────────────────
  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyStreak) ?? 0;
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final lastDate = prefs.getString(AppConstants.keyLastStreakDate) ?? '';
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    if (lastDate == today) return; // 今日はもう更新済み

    int streak = prefs.getInt(AppConstants.keyStreak) ?? 0;
    if (lastDate == yesterday) {
      streak++;
    } else {
      streak = 1;
    }
    await prefs.setInt(AppConstants.keyStreak, streak);
    await prefs.setString(AppConstants.keyLastStreakDate, today);
  }

  // ─── 新規セッションID生成 ─────────────────────────────
  static String generateId() {
    final rand = Random().nextInt(999999);
    return '${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  String _dateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}
