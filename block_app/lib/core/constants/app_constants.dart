class AppConstants {
  AppConstants._();

  // SharedPreferences keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyDailyUsageGoal = 'daily_usage_goal_minutes';
  static const String keyUserName = 'user_name';
  static const String keyGoal = 'user_goal'; // onboarding goal index
  static const String keyStreak = 'streak_count';
  static const String keyLastStreakDate = 'last_streak_date';
  static const String keyNowBlockUsedToday = 'now_block_used_today';
  static const String keyNowBlockDate = 'now_block_date';
  static const String keyIsPremium = 'is_premium';

  // 無料プラン制限
  static const int freeNowBlockPerDay = 5;
  static const int freeLimitBlockApps = 3;
  static const int freeStatsDays = 7;

  // RevenueCat（iOSのみ）
  static const String rcApiKeyIos = 'sk_ZdCyZmBrnnwoYskvgRmjjtLLmhjLj';
  static const String entitlementPremium = 'lockin_plus';

  // ブロック設定
  static const int strictModeCooldownSeconds = 60;
  static const int quickBreakSeconds = 180;
  static const int frictionModeDelaySeconds = 10;

  // 名言切り替え間隔
  static const int quoteRotateSeconds = 60;
}
