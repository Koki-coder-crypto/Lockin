import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/app_providers.dart';

class BlockCompleteScreen extends ConsumerStatefulWidget {
  final BlockCompleteArgs args;
  const BlockCompleteScreen({super.key, required this.args});

  @override
  ConsumerState<BlockCompleteScreen> createState() =>
      _BlockCompleteScreenState();
}

class _BlockCompleteScreenState extends ConsumerState<BlockCompleteScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _quote;
  late AnimationController _checkController;
  late AnimationController _ringController;
  late Animation<double> _ringExpand;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _ringExpand = CurvedAnimation(
        parent: _ringController, curve: Curves.elasticOut);

    _loadQuote();

    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      HapticFeedback.lightImpact();
    });
  }

  Future<void> _loadQuote() async {
    final quotes = await ref.read(quotesProvider.future);
    if (!mounted) return;
    final successQuotes =
        quotes.where((q) => q['category'] == 'success').toList();
    final source = successQuotes.isNotEmpty ? successQuotes : quotes;
    setState(() {
      _quote = source[Random().nextInt(source.length)];
    });
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h時間$m分$s秒';
    if (m > 0) return '$m分$s秒';
    return '$s秒';
  }

  @override
  void dispose() {
    _checkController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ─── チェックサークル ─────────────────────
              ScaleTransition(
                scale: _ringExpand,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.green.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.green, size: 60),
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 28),

              // ─── タイトル ─────────────────────────────
              Text(
                '達成！',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.green,
                  fontSize: 42,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                _formatElapsed(widget.args.elapsedSeconds),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // ─── ストリーク ───────────────────────────
              streakAsync.when(
                data: (streak) => streak > 0
                    ? _StreakCard(streak: streak)
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.15)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ─── 名言 ─────────────────────────────────
              if (_quote != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"${_quote!['text']}"',
                        style: AppTextStyles.quote,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '— ${_quote!['author']}',
                          style: AppTextStyles.quoteAuthor,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 36),

              // ─── ボタン ───────────────────────────────
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'ホームに戻る',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () =>
                    context.go(AppRoutes.blockSetup),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('もう一度ロック'),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.amberDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.amber, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak日連続達成！',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.amber,
                  fontSize: 16,
                ),
              ),
              Text(
                'この調子で続けましょう',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
