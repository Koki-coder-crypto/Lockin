import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../platform/ios/screen_time_channel.dart';
import '../../paywall/screens/paywall_feature_screen.dart';

class BlockSetupScreen extends ConsumerStatefulWidget {
  const BlockSetupScreen({super.key});

  @override
  ConsumerState<BlockSetupScreen> createState() => _BlockSetupScreenState();
}

class _BlockSetupScreenState extends ConsumerState<BlockSetupScreen> {
  int _modeIndex = 0;
  int _durationMinutes = 25;
  bool _strictMode = false;
  bool _frictionEnabled = true;
  List<String> _selectedApps = [];
  bool _appPickerLoading = false;

  static const _durations = [5, 10, 15, 25, 30, 45, 60, 90, 120];

  Future<void> _showAppPicker() async {
    setState(() => _appPickerLoading = true);
    try {
      final result = await ScreenTimeChannel.instance.showAppPicker();
      if (result != null && mounted) {
        final count = result['selectedCount'] as int? ?? 0;
        setState(() {
          _selectedApps = List.generate(count, (i) => 'App ${i + 1}');
        });
      }
    } finally {
      if (mounted) setState(() => _appPickerLoading = false);
    }
  }

  Future<void> _startBlock() async {
    final isPremium = ref.read(premiumProvider);

    if (_modeIndex == 2 && !isPremium) {
      final ok = await showPaywallFeature(context, 'schedule_block');
      if (!ok || !mounted) return;
    }

    if (_strictMode && !isPremium) {
      final ok = await showPaywallFeature(context, 'strict_mode');
      if (!ok || !mounted) {
        setState(() => _strictMode = false);
        return;
      }
    }

    HapticFeedback.heavyImpact();
    await ScreenTimeChannel.instance.blockApps(
        durationMinutes: _durationMinutes);

    if (!mounted) return;
    context.push(
      AppRoutes.blockingActive,
      extra: BlockingActiveArgs(
        appNames: _selectedApps,
        durationMinutes: _durationMinutes,
        strictMode: _strictMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── ヘッダー ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ロック設定',
                    style: AppTextStyles.headingLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'モードを選んで集中を始めましょう',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── スクロール可能エリア ─────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── モードカード ────────────────────
                    _ModeCard(
                      icon: Icons.bolt_outlined,
                      iconColor: AppColors.red,
                      badge: null,
                      title: 'NOW LOCK',
                      subtitle: '今すぐ指定した時間だけロック',
                      selected: _modeIndex == 0,
                      onTap: () => setState(() => _modeIndex = 0),
                      child: _modeIndex == 0
                          ? _NowModeDetail(
                              durations: _durations,
                              selected: _durationMinutes,
                              selectedApps: _selectedApps,
                              appPickerLoading: _appPickerLoading,
                              onDurationSelect: (d) =>
                                  setState(() => _durationMinutes = d),
                              onAppPicker: _showAppPicker,
                            )
                          : null,
                    ),

                    const SizedBox(height: 12),

                    _ModeCard(
                      icon: Icons.data_usage_outlined,
                      iconColor: AppColors.blue,
                      badge: null,
                      title: 'LIMIT LOCK',
                      subtitle: '1日のアプリ使用上限を設定',
                      selected: _modeIndex == 1,
                      onTap: () => setState(() => _modeIndex = 1),
                      child: _modeIndex == 1
                          ? _LimitModeDetail(
                              selectedApps: _selectedApps,
                              appPickerLoading: _appPickerLoading,
                              onAppPicker: _showAppPicker,
                            )
                          : null,
                    ),

                    const SizedBox(height: 12),

                    _ModeCard(
                      icon: Icons.schedule_outlined,
                      iconColor:
                          isPremium ? AppColors.green : AppColors.textSecondary,
                      badge: isPremium ? null : 'Lockin+',
                      title: 'SCHEDULE',
                      subtitle: '曜日・時間で自動ロック',
                      selected: _modeIndex == 2,
                      onTap: () => setState(() => _modeIndex = 2),
                      child: null,
                    ),

                    const SizedBox(height: 24),

                    // ─── オプション ──────────────────────
                    Text(
                      'オプション',
                      style: AppTextStyles.labelMedium.copyWith(
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _OptionToggle(
                            icon: Icons.warning_amber_outlined,
                            iconColor: AppColors.amber,
                            title: 'フリクションモード',
                            subtitle: '10秒の確認で衝動を抑制',
                            value: _frictionEnabled,
                            onChanged: (v) =>
                                setState(() => _frictionEnabled = v),
                          ),
                          const Divider(height: 1, indent: 56),
                          _OptionToggle(
                            icon: Icons.security_outlined,
                            iconColor: AppColors.red,
                            title: 'Strict モード',
                            subtitle: isPremium
                                ? '60秒クールダウンで解除を困難に'
                                : '60秒クールダウン（Lockin+）',
                            value: _strictMode,
                            isPremiumLocked: !isPremium,
                            onChanged: (v) =>
                                setState(() => _strictMode = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ─── ロック開始ボタン ─────────────────
                    ElevatedButton(
                      onPressed: _startBlock,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'ロック開始',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
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

// ─── モードカード ────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? badge;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.red.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.headingMedium.copyWith(
                                color: selected
                                    ? AppColors.red
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.redDim,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  badge!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: selected ? AppColors.red : AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (child != null) ...[
              const Divider(height: 1, indent: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── NOW モード詳細 ──────────────────────────────────────
class _NowModeDetail extends StatelessWidget {
  final List<int> durations;
  final int selected;
  final List<String> selectedApps;
  final bool appPickerLoading;
  final ValueChanged<int> onDurationSelect;
  final VoidCallback onAppPicker;

  const _NowModeDetail({
    required this.durations,
    required this.selected,
    required this.selectedApps,
    required this.appPickerLoading,
    required this.onDurationSelect,
    required this.onAppPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ブロック時間',
            style: AppTextStyles.labelMedium.copyWith(
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durations.map((d) {
              final isSelected = selected == d;
              return GestureDetector(
                onTap: () => onDurationSelect(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.red
                        : AppColors.surfacePlus,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.red : AppColors.border,
                    ),
                  ),
                  child: Text(
                    d >= 60 ? '${d ~/ 60}時間' : '$d分',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onAppPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfacePlus,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apps_outlined,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedApps.isEmpty
                          ? 'アプリを選択（未選択=全アプリ）'
                          : selectedApps.join('・'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selectedApps.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (appPickerLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.red, strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LIMIT モード詳細 ────────────────────────────────────
class _LimitModeDetail extends StatelessWidget {
  final List<String> selectedApps;
  final bool appPickerLoading;
  final VoidCallback onAppPicker;

  const _LimitModeDetail({
    required this.selectedApps,
    required this.appPickerLoading,
    required this.onAppPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: GestureDetector(
        onTap: onAppPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfacePlus,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.apps_outlined,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedApps.isEmpty
                      ? '上限を設定するアプリを選択'
                      : selectedApps.join('・'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selectedApps.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (appPickerLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.red, strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── オプショントグル ────────────────────────────────────
class _OptionToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value, isPremiumLocked;
  final ValueChanged<bool> onChanged;

  const _OptionToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isPremiumLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.headingMedium.copyWith(fontSize: 15)),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (isPremiumLocked)
            const Icon(Icons.lock_outline,
                color: AppColors.textSecondary, size: 18)
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
