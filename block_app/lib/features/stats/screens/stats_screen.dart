import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/stats_repository.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('記録', style: AppTextStyles.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      '今週の集中セッション',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    weeklyAsync.when(
                      data: (stats) => Column(
                        children: [
                          _SummaryRow(stats: stats),
                          const SizedBox(height: 16),
                          _WeeklyChart(stats: stats),
                          const SizedBox(height: 16),
                          _StreakCard(streak: stats.streak),
                          const SizedBox(height: 16),
                          _AppUsageSection(isPremium: isPremium),
                          const SizedBox(height: 16),
                          if (!isPremium)
                            _PremiumUpsell(
                              onTap: () => context.push(AppRoutes.paywall),
                            ),
                        ],
                      ),
                      loading: () => const Center(
                        heightFactor: 4,
                        child:
                            CircularProgressIndicator(color: AppColors.red),
                      ),
                      error: (e, _) => Center(
                        child: Text('データの読み込みに失敗しました',
                            style: AppTextStyles.bodyMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── サマリー行 ──────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final WeeklyStats stats;
  const _SummaryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final h = stats.totalBlockedMinutes ~/ 60;
    final m = stats.totalBlockedMinutes % 60;
    return Row(
      children: [
        _SummaryCard(
          label: '今週のロック時間',
          value: h > 0 ? '${h}h ${m}m' : '${m}m',
          color: AppColors.green,
          icon: Icons.lock_outline,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          label: '総セッション数',
          value: '${stats.totalSessions}回',
          color: AppColors.blue,
          icon: Icons.repeat_outlined,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headingLarge
                  .copyWith(color: color, fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─── 週次棒グラフ ─────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final WeeklyStats stats;
  const _WeeklyChart({required this.stats});

  static const _dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final maxMinutes = stats.days
        .map((d) => d.blockedMinutes)
        .fold(0, (a, b) => a > b ? a : b);
    final maxY =
        maxMinutes < 30 ? 60.0 : (maxMinutes * 1.3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今週のロック時間', style: AppTextStyles.headingMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final mins = rod.toY.toInt();
                      final h = mins ~/ 60;
                      final m = mins % 60;
                      return BarTooltipItem(
                        h > 0 ? '${h}h${m}m' : '${m}m',
                        AppTextStyles.labelSmall
                            .copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stats.days.length) {
                          return const SizedBox.shrink();
                        }
                        final dayOfWeek = stats.days[i].date.weekday - 1;
                        return Text(
                          _dayLabels[dayOfWeek],
                          style: AppTextStyles.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.border, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(stats.days.length, (i) {
                  final isToday = i == stats.days.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stats.days[i].blockedMinutes.toDouble(),
                        color: isToday
                            ? AppColors.red
                            : const Color(0xFF2E3440),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.surfacePlus.withOpacity(0.4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ストリークカード ─────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.amberDim,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppColors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('連続達成ストリーク', style: AppTextStyles.bodyMedium),
                Text(
                  '$streak 日連続',
                  style: AppTextStyles.headingLarge
                      .copyWith(color: AppColors.amber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── アプリ使用量セクション ──────────────────────────────
class _AppUsageSection extends StatelessWidget {
  final bool isPremium;
  const _AppUsageSection({required this.isPremium});

  static const _mockApps = [
    _AppUsage('Instagram', 68, AppColors.red),
    _AppUsage('YouTube', 52, AppColors.amber),
    _AppUsage('Twitter/X', 34, AppColors.blue),
    _AppUsage('TikTok', 28, AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final maxMinutes = _mockApps
        .map((a) => a.minutes)
        .fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('アプリ別使用時間', style: AppTextStyles.headingMedium),
              Text('今日', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_mockApps.length, (i) {
            final app = _mockApps[i];
            final frac = app.minutes / maxMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(app.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: frac,
                            backgroundColor: AppColors.surfacePlus,
                            color: app.color,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${app.minutes}m',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AppUsage {
  final String name;
  final int minutes;
  final Color color;
  const _AppUsage(this.name, this.minutes, this.color);
}

// ─── プレミアムアップセル ────────────────────────────────
class _PremiumUpsell extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumUpsell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.red.withOpacity(0.18), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lockin+ で詳細統計を解放',
                      style: AppTextStyles.headingMedium),
                  const SizedBox(height: 4),
                  Text('ヒートマップ・週次レポート・無制限期間',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '解放する',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
