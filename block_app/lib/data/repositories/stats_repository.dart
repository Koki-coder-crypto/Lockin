import 'package:shared_preferences/shared_preferences.dart';
import 'block_repository.dart';

class DailyStats {
  final DateTime date;
  final int blockedMinutes;
  final int sessionCount;
  final int completedCount;

  const DailyStats({
    required this.date,
    required this.blockedMinutes,
    required this.sessionCount,
    required this.completedCount,
  });
}

class WeeklyStats {
  final List<DailyStats> days;
  final int totalBlockedMinutes;
  final int totalSessions;
  final int streak;

  const WeeklyStats({
    required this.days,
    required this.totalBlockedMinutes,
    required this.totalSessions,
    required this.streak,
  });
}

class StatsRepository {
  final BlockRepository _blockRepo;

  StatsRepository(this._blockRepo);

  Future<DailyStats> getStatsForDate(DateTime date) async {
    final sessions = await _blockRepo.getSessionsForDate(date);
    int blockedMinutes = 0;
    int completedCount = 0;
    for (final s in sessions) {
      if (s.endedAt != null) {
        blockedMinutes += s.elapsedSeconds ~/ 60;
        if (s.completed) completedCount++;
      }
    }
    return DailyStats(
      date: date,
      blockedMinutes: blockedMinutes,
      sessionCount: sessions.length,
      completedCount: completedCount,
    );
  }

  Future<WeeklyStats> getWeeklyStats() async {
    final days = <DailyStats>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      days.add(await getStatsForDate(date));
    }
    final total = days.fold(0, (sum, d) => sum + d.blockedMinutes);
    final sessions = days.fold(0, (sum, d) => sum + d.sessionCount);
    final streak = await _blockRepo.getStreak();
    return WeeklyStats(
      days: days,
      totalBlockedMinutes: total,
      totalSessions: sessions,
      streak: streak,
    );
  }

  // 今日の使用時間（Platform Channelから取得できない場合はモック）
  Future<int> getTodayUsageMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('today_usage_minutes') ?? 142;
  }

  Future<void> setTodayUsageMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('today_usage_minutes', minutes);
  }
}
