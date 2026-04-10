import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingGoalScreen extends StatefulWidget {
  const OnboardingGoalScreen({super.key});

  @override
  State<OnboardingGoalScreen> createState() => _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends State<OnboardingGoalScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _controller;
  late Animation<double> _fade;

  static const _goals = [
    _Goal(
      icon: Icons.psychology_outlined,
      label: '集中力を高めたい',
      desc: '勉強・仕事中のSNSをブロックして生産性UP',
      color: AppColors.blue,
    ),
    _Goal(
      icon: Icons.bedtime_outlined,
      label: '睡眠を改善したい',
      desc: '就寝前のスマホ習慣を断ち、質の良い睡眠へ',
      color: AppColors.blue,
    ),
    _Goal(
      icon: Icons.phone_android_outlined,
      label: 'スマホ依存から抜け出したい',
      desc: '使用時間全体を減らし、本当の時間を取り戻す',
      color: AppColors.red,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSelect(int index) async {
    setState(() => _selectedIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyGoal, index);
    await Future.delayed(const Duration(milliseconds: 280));
    if (mounted) context.push(AppRoutes.onboardingUsage);
  }

  @override
  Widget build(BuildContext context) {
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

                // プログレスドット
                _ProgressDots(current: 0, total: 4),

                const SizedBox(height: 48),

                // ロゴ
                Text(
                  'Lockin',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'あなたの目標を\n教えてください',
                  style: AppTextStyles.displayMedium.copyWith(height: 1.25),
                ),

                const SizedBox(height: 8),

                Text(
                  '後から変更できます',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: 36),

                ...List.generate(_goals.length, (i) {
                  final goal = _goals[i];
                  final selected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(
                      goal: goal,
                      selected: selected,
                      onTap: () => _onSelect(i),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── プログレスドット ────────────────────────────────────
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

// ─── ゴールカード ────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final _Goal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.red.withOpacity(0.15)
                    : AppColors.surfacePlus,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                goal.icon,
                color: selected ? AppColors.red : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.label,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    goal.desc,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.chevron_right,
              color: selected ? AppColors.red : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Goal {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;

  const _Goal({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });
}
