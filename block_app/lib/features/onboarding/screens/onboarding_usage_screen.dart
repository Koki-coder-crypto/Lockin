import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

class OnboardingUsageScreen extends StatefulWidget {
  const OnboardingUsageScreen({super.key});

  @override
  State<OnboardingUsageScreen> createState() => _OnboardingUsageScreenState();
}

class _OnboardingUsageScreenState extends State<OnboardingUsageScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _controller;
  late Animation<double> _fade;

  static const _options = [
    _UsageOption('1〜2時間', 90, '平均的な範囲です'),
    _UsageOption('3〜4時間', 210, '少し多めです'),
    _UsageOption('5〜6時間', 330, 'かなり多い部類です'),
    _UsageOption('7時間以上', 450, '依存気味かもしれません'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        context.push(
          AppRoutes.onboardingShock,
          extra: _options[index].minutes,
        );
      }
    });
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
                _ProgressDots(current: 1, total: 4),

                const SizedBox(height: 48),

                Text(
                  '1日に\nどのくらい使いますか？',
                  style: AppTextStyles.displayMedium.copyWith(height: 1.25),
                ),

                const SizedBox(height: 8),

                Text(
                  '正直に答えるほど、効果的な設定になります。',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: 36),

                ...List.generate(_options.length, (i) {
                  final selected = _selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionCard(
                      option: _options[i],
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

class _UsageOption {
  final String label;
  final int minutes;
  final String hint;
  const _UsageOption(this.label, this.minutes, this.hint);
}

class _OptionCard extends StatelessWidget {
  final _UsageOption option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(option.hint, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.red : AppColors.border,
              size: 22,
            ),
          ],
        ),
      ),
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
