import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

class OnboardingShockScreen extends StatefulWidget {
  final int dailyMinutes;
  const OnboardingShockScreen({super.key, required this.dailyMinutes});

  @override
  State<OnboardingShockScreen> createState() => _OnboardingShockScreenState();
}

class _OnboardingShockScreenState extends State<OnboardingShockScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _countController;
  late AnimationController _barController;
  late Animation<double> _fade;
  late Animation<int> _hourCount;
  late Animation<double> _barWidth;

  int get _yearlyHours => (widget.dailyMinutes * 365) ~/ 60;
  double get _lifePercent => (_yearlyHours / (24 * 365)) * 100;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _hourCount = IntTween(begin: 0, end: _yearlyHours).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOut),
    );

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barWidth = CurvedAnimation(parent: _barController, curve: Curves.easeOut);

    _fadeController.forward().then((_) {
      _countController.forward();
      _barController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _countController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 48;
    final barFraction = (_lifePercent / 100).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                _ProgressDots(current: 2, total: 4),

                const SizedBox(height: 48),

                Text(
                  'あなたは年間',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 12),

                // カウントアップ数字
                AnimatedBuilder(
                  animation: _hourCount,
                  builder: (context, _) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_hourCount.value}',
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 80,
                            color: AppColors.red,
                            letterSpacing: -3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '時間',
                            style: AppTextStyles.headingLarge,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                Text(
                  'スマホを見て過ごしています。',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                // 人生バー
                Text(
                  '人生に占める割合',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfacePlus,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: AnimatedBuilder(
                    animation: _barWidth,
                    builder: (context, _) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 10,
                          width: screenWidth * barFraction * _barWidth.value,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_lifePercent.toStringAsFixed(1)}%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 20),

                _StatRow(
                  label: '1ヶ月換算',
                  value: '${(_yearlyHours / 12).toStringAsFixed(0)} 時間',
                ),
                const SizedBox(height: 14),
                _StatRow(
                  label: '読める本（1冊5時間）',
                  value: '${(_yearlyHours / 5).toStringAsFixed(0)} 冊分',
                ),
                const SizedBox(height: 14),
                _StatRow(
                  label: '映画（2時間）',
                  value: '${(_yearlyHours / 2).toStringAsFixed(0)} 本分',
                ),

                const Spacer(),

                Text(
                  'Lockinで、この時間を\n取り戻しましょう。',
                  style: AppTextStyles.headingMedium,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.onboardingPermission),
                  child: const Text('次へ'),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.bodyLarge
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.red : AppColors.surfacePlus,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
