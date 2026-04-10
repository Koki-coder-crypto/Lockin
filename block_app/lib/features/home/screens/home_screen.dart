import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/block_session.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, dynamic>? _dailyQuote;
  static const int _usedMinutes = 142;
  static const int _goalMinutes = 180;

  @override
  void initState() {
    super.initState();
    _pickDailyQuote();
  }

  Future<void> _pickDailyQuote() async {
    final quotes = await ref.read(quotesProvider.future);
    if (mounted) {
      final dayIndex = DateTime.now().day % quotes.length;
      setState(() => _dailyQuote = quotes[dayIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockState = ref.watch(blockProvider);
    final isPremium = ref.watch(premiumProvider);
    final nowBlockCountAsync = ref.watch(nowBlockCountProvider);
    final streakAsync = ref.watch(streakProvider);
    final usagePercent = (_usedMinutes / _goalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nowBlockCountProvider);
            ref.invalidate(streakProvider);
          },
          color: AppColors.red,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ─── ヘッダー ───────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lockin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red,
                              letterSpacing: 3,
                            ),
                          ),
                          Row(children: [
                            if (isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.redDim,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lockin+',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            streakAsync.when(
                              data: (streak) => streak > 0
                                  ? _StreakBadge(streak: streak)
                                  : const SizedBox.shrink(),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ]),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ─── 使用時間リング（大） ────────────────
                      Center(
                        child: _UsageRing(
                          usagePercent: usagePercent,
                          usedMinutes: _usedMinutes,
                          goalMinutes: _goalMinutes,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(
                            begin: const Offset(0.88, 0.88),
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 28),

                      // ─── アクティブバナー or LOCKボタン ─────
                      if (blockState.status == BlockStatus.active &&
                          blockState.session != null)
                        _ActiveBlockBanner(
                          session: blockState.session!,
                          onTap: () => context.push(
                            AppRoutes.blockingActive,
                            extra: BlockingActiveArgs(
                              appNames: blockState.session!.appNames,
                              durationMinutes:
                                  blockState.session!.durationMinutes,
                              strictMode: blockState.session!.strictMode,
                            ),
                          ),
                        ).animate().fadeIn()
                      else
                        _LockNowButton(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            context.go(AppRoutes.blockSetup);
                          },
                        ),

                      const SizedBox(height: 12),

                      // 残り回数（無料ユーザー）
                      if (!isPremium)
                        nowBlockCountAsync.when(
                          data: (count) {
                            final remaining =
                                AppConstants.freeNowBlockPerDay - count;
                            return Center(
                              child: Text(
                                remaining > 0
                                    ? '本日残り $remaining 回 / 無制限はLockin+'
                                    : '本日の無料回数を使い切りました',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: remaining > 0
                                      ? AppColors.textSecondary
                                      : AppColors.amber,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                      const SizedBox(height: 28),

                      // ─── デイリー名言 ────────────────────────
                      if (_dailyQuote != null)
                        _QuoteCard(quote: _dailyQuote!)
                            .animate()
                            .fadeIn(delay: 300.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 使用時間リング ──────────────────────────────────────
class _UsageRing extends StatelessWidget {
  final double usagePercent;
  final int usedMinutes, goalMinutes;

  const _UsageRing({
    required this.usagePercent,
    required this.usedMinutes,
    required this.goalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final usedH = usedMinutes ~/ 60;
    final usedM = usedMinutes % 60;
    final remaining = (goalMinutes - usedMinutes).clamp(0, goalMinutes);
    final remH = remaining ~/ 60;
    final remM = remaining % 60;
    final color = usagePercent > 0.9
        ? AppColors.red
        : usagePercent > 0.7
            ? AppColors.amber
            : AppColors.green;

    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(230, 230),
            painter: _RingPainter(progress: usagePercent, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${usedH}h ${usedM}m',
                style: AppTextStyles.displayMedium.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 2),
              Text('今日の使用時間', style: AppTextStyles.bodySmall),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '残り ${remH}h ${remM}m',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfacePlus
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── ロックボタン ────────────────────────────────────────
class _LockNowButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LockNowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              '今すぐ LOCK',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── アクティブバナー ────────────────────────────────────
class _ActiveBlockBanner extends StatelessWidget {
  final BlockSession session;
  final VoidCallback onTap;
  const _ActiveBlockBanner({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.redDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat())
                .fadeOut(duration: 1.seconds, curve: Curves.easeInOut)
                .then()
                .fadeIn(duration: 1.seconds),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOCKING',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.red,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    session.appNames.isEmpty
                        ? 'すべてのアプリ'
                        : session.appNames.join('・'),
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── ストリークバッジ ────────────────────────────────────
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amberDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.local_fire_department,
            color: AppColors.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          '$streak日',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.amber,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

// ─── デイリー名言カード ──────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
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
          Text(
            '"${quote['text']}"',
            style: AppTextStyles.quote,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${quote['author']}',
              style: AppTextStyles.quoteAuthor,
            ),
          ),
        ],
      ),
    );
  }
}
