import 'dart:async';
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
import '../../../platform/ios/screen_time_channel.dart';

class BlockingActiveScreen extends ConsumerStatefulWidget {
  final BlockingActiveArgs args;
  const BlockingActiveScreen({super.key, required this.args});

  @override
  ConsumerState<BlockingActiveScreen> createState() =>
      _BlockingActiveScreenState();
}

class _BlockingActiveScreenState extends ConsumerState<BlockingActiveScreen>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  Timer? _quoteTimer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  Map<String, dynamic>? _currentQuote;

  late AnimationController _quoteController;
  late Animation<double> _quoteFade;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.args.durationMinutes * 60;

    _quoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _quoteFade =
        CurvedAnimation(parent: _quoteController, curve: Curves.easeInOut);
    _quoteController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _startTimers();
    _loadNextQuote();
  }

  void _startTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
      if (_remainingSeconds == 0 && widget.args.durationMinutes > 0) {
        _onComplete();
      }
    });

    _quoteTimer = Timer.periodic(
      Duration(seconds: AppConstants.quoteRotateSeconds),
      (_) => _rotateQuote(),
    );
  }

  Future<void> _loadNextQuote() async {
    final quotes = await ref.read(quotesProvider.future);
    if (!mounted) return;
    final focusQuotes =
        quotes.where((q) => q['category'] == 'focus').toList();
    final source = focusQuotes.isNotEmpty ? focusQuotes : quotes;
    setState(() {
      _currentQuote = source[_elapsedSeconds % source.length];
    });
  }

  Future<void> _rotateQuote() async {
    await _quoteController.reverse();
    await _loadNextQuote();
    if (mounted) _quoteController.forward();
  }

  Future<void> _onComplete() async {
    _countdownTimer?.cancel();
    _quoteTimer?.cancel();
    await ScreenTimeChannel.instance.unblockApps();
    HapticFeedback.mediumImpact();
    final block = ref.read(blockProvider.notifier);
    await block.endBlock(completed: true);
    if (mounted) {
      context.pushReplacement(
        AppRoutes.blockComplete,
        extra: BlockCompleteArgs(
          elapsedSeconds: _elapsedSeconds,
          appNames: widget.args.appNames,
        ),
      );
    }
  }

  Future<void> _requestStop() async {
    final blockNotifier = ref.read(blockProvider.notifier);
    final blockState = ref.read(blockProvider);

    if (blockState.status == BlockStatus.strictCooldown) {
      HapticFeedback.heavyImpact();
      _showStrictWarning(blockState.strictCooldown);
      return;
    }

    final canStop = await blockNotifier.requestStop();
    if (!canStop && mounted) {
      HapticFeedback.heavyImpact();
      _showStrictWarning(AppConstants.strictModeCooldownSeconds);
      return;
    }

    if (canStop) {
      await ScreenTimeChannel.instance.unblockApps();
      if (mounted) context.go(AppRoutes.home);
    }
  }

  void _showStrictWarning(int seconds) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Strict モード: あと ${seconds}秒後に解除できます',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.amber.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progressFraction {
    final total = widget.args.durationMinutes * 60;
    if (total == 0) return 0;
    return _elapsedSeconds / total;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _quoteTimer?.cancel();
    _quoteController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUnlimited = widget.args.durationMinutes == 0;
    final blockState = ref.watch(blockProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ─── メインコンテンツ ─────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOCKING ピル
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.redDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.red
                                    .withOpacity(0.4 + 0.6 * _pulse.value),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LOCKING',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.red,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // プログレスリング + タイマー
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!isUnlimited)
                            CustomPaint(
                              size: const Size(200, 200),
                              painter: _ProgressRingPainter(
                                  progress: _progressFraction),
                            ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isUnlimited
                                    ? _formatTime(_elapsedSeconds)
                                    : _formatTime(_remainingSeconds),
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w200,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isUnlimited ? '経過時間' : '残り時間',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 56),

                    // 名言
                    if (_currentQuote != null)
                      FadeTransition(
                        opacity: _quoteFade,
                        child: Column(
                          children: [
                            Text(
                              '"${_currentQuote!['text']}"',
                              style: AppTextStyles.quote,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '— ${_currentQuote!['author']}',
                              style: AppTextStyles.quoteAuthor,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 48),

                    // Strict クールダウン
                    if (blockState.status == BlockStatus.strictCooldown)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.amberDim,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                color: AppColors.amber, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Strict: あと ${blockState.strictCooldown}秒',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.amber),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ─── 停止ボタン（左上）────────────────────────
            Positioned(
              top: 12,
              left: 12,
              child: TextButton.icon(
                onPressed: _requestStop,
                icon: const Icon(Icons.stop_circle_outlined,
                    color: AppColors.textSecondary, size: 16),
                label: Text('停止', style: AppTextStyles.bodySmall),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── プログレスリングPainter ─────────────────────────────
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 4.0;

    // トラック
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfacePlus
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // プログレス
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress.clamp(0, 1),
        false,
        Paint()
          ..color = AppColors.red
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}
