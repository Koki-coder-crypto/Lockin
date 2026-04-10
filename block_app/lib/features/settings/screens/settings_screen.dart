import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_router.dart';
import '../../paywall/screens/paywall_feature_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _frictionMode = true;
  bool _sleepMode = false;
  TimeOfDay _sleepStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);
  int _dailyGoal = 120;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _frictionMode = prefs.getBool('friction_mode') ?? true;
      _sleepMode = prefs.getBool('sleep_mode') ?? false;
      _dailyGoal = prefs.getInt(AppConstants.keyDailyUsageGoal) ?? 120;
      final sleepStartH = prefs.getInt('sleep_start_h') ?? 23;
      final sleepStartM = prefs.getInt('sleep_start_m') ?? 0;
      final sleepEndH = prefs.getInt('sleep_end_h') ?? 7;
      final sleepEndM = prefs.getInt('sleep_end_m') ?? 0;
      _sleepStart = TimeOfDay(hour: sleepStartH, minute: sleepStartM);
      _sleepEnd = TimeOfDay(hour: sleepEndH, minute: sleepEndM);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('friction_mode', _frictionMode);
    await prefs.setBool('sleep_mode', _sleepMode);
    await prefs.setInt(AppConstants.keyDailyUsageGoal, _dailyGoal);
    await prefs.setInt('sleep_start_h', _sleepStart.hour);
    await prefs.setInt('sleep_start_m', _sleepStart.minute);
    await prefs.setInt('sleep_end_h', _sleepEnd.hour);
    await prefs.setInt('sleep_end_m', _sleepEnd.minute);
  }

  Future<bool> _checkPremium(String featureKey) async {
    final isPremium = ref.read(premiumProvider);
    if (isPremium) return true;
    final result = await showPaywallFeature(context, featureKey);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('設定', style: AppTextStyles.headingLarge),
                    const SizedBox(height: 24),

                    // ── Lockin+バナー ──
                    if (!isPremium) _PremiumBanner(
                      onTap: () => context.push(AppRoutes.paywall),
                    ),
                    if (!isPremium) const SizedBox(height: 24),

                    // ── ブロック設定 ──
                    _SectionHeader(title: 'ブロック設定'),
                    const SizedBox(height: 12),

                    _SettingToggle(
                      icon: Icons.warning_amber_outlined,
                      iconColor: AppColors.amber,
                      title: 'フリクションモード',
                      subtitle: 'ブロック前に10秒の確認画面を表示',
                      value: _frictionMode,
                      onChanged: (v) {
                        setState(() => _frictionMode = v);
                        _save();
                      },
                    ),
                    const Divider(height: 1),
                    _SettingToggle(
                      icon: Icons.nights_stay_outlined,
                      iconColor: AppColors.blue,
                      title: '睡眠モード',
                      subtitle: '就寝時間を自動でブロック',
                      value: _sleepMode,
                      isPremium: !isPremium,
                      onChanged: (v) async {
                        if (!v) {
                          setState(() => _sleepMode = false);
                          _save();
                          return;
                        }
                        final ok = await _checkPremium('sleep_mode');
                        if (ok) {
                          setState(() => _sleepMode = true);
                          _save();
                        }
                      },
                    ),

                    if (_sleepMode) ...[
                      const Divider(height: 1),
                      _SleepTimeRow(
                        label: '就寝時間',
                        time: _sleepStart,
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context, initialTime: _sleepStart);
                          if (t != null) {
                            setState(() => _sleepStart = t);
                            _save();
                          }
                        },
                      ),
                      const Divider(height: 1),
                      _SleepTimeRow(
                        label: '起床時間',
                        time: _sleepEnd,
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context, initialTime: _sleepEnd);
                          if (t != null) {
                            setState(() => _sleepEnd = t);
                            _save();
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── 目標時間 ──
                    _SectionHeader(title: '目標使用時間'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1日の目標',
                                  style: AppTextStyles.headingMedium.copyWith(fontSize: 15)),
                              Text(
                                _goalLabel(_dailyGoal),
                                style: AppTextStyles.headingMedium.copyWith(
                                    color: AppColors.red),
                              ),
                            ],
                          ),
                          Slider(
                            value: _dailyGoal.toDouble(),
                            min: 30, max: 360,
                            divisions: 11,
                            activeColor: AppColors.red,
                            inactiveColor: AppColors.surfacePlus,
                            onChanged: (v) {
                              setState(() => _dailyGoal = v.toInt());
                              _save();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── テンプレート ──
                    _SectionHeader(title: 'ブロックテンプレート'),
                    const SizedBox(height: 12),
                    ..._templates.map((t) => _TemplateCard(
                          template: t,
                          onTap: () {},
                        )),

                    const SizedBox(height: 24),

                    // ── アプリ情報 ──
                    _SectionHeader(title: 'アプリ情報'),
                    const SizedBox(height: 12),
                    _SettingTile(
                      icon: Icons.star_outline,
                      iconColor: AppColors.amber,
                      title: 'アプリを評価する',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _SettingTile(
                      icon: Icons.restore_outlined,
                      iconColor: AppColors.blue,
                      title: '購入を復元する',
                      onTap: () async {
                        final success = await ref
                            .read(premiumProvider.notifier)
                            .restorePurchases();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? '購入を復元しました' : '復元できる購入がありません'),
                            backgroundColor: AppColors.surface,
                          ));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _SettingTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.textSecondary,
                      title: 'プライバシーポリシー',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _SettingTile(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.textSecondary,
                      title: '利用規約',
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: Text('Lockin v1.0.0',
                          style: AppTextStyles.bodySmall),
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

  String _goalLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m分';
    if (m == 0) return '$h時間';
    return '$h時間$m分';
  }
}

const _templates = [
  _Template(icon: Icons.school_outlined, name: '勉強モード',
      description: 'SNS・ゲーム・動画をブロック', color: AppColors.blue),
  _Template(icon: Icons.bedtime_outlined, name: '睡眠モード',
      description: '全アプリ・通知をブロック', color: AppColors.blue),
  _Template(icon: Icons.work_outlined, name: '仕事モード',
      description: 'SNS・エンタメをブロック', color: AppColors.amber),
];

class _Template {
  final IconData icon;
  final String name, description;
  final Color color;
  const _Template({required this.icon, required this.name,
      required this.description, required this.color});
}

// ─── ウィジェット群 ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.labelMedium.copyWith(
      color: AppColors.textSecondary, letterSpacing: 1.0));
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.red.withOpacity(0.25), AppColors.surface],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lockin+ にアップグレード',
                      style: AppTextStyles.headingMedium),
                  const SizedBox(height: 4),
                  Text('7日間無料トライアル',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.green)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red, borderRadius: BorderRadius.circular(8)),
              child: Text('試す', style: AppTextStyles.labelMedium
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final bool isPremium;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: AppTextStyles.headingMedium.copyWith(fontSize: 15)),
                  if (isPremium) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.redDim, borderRadius: BorderRadius.circular(4)),
                      child: Text('Lockin+', style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.red, fontSize: 9)),
                    ),
                  ],
                ]),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SleepTimeRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _SleepTimeRow(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Text(label, style: AppTextStyles.headingMedium.copyWith(fontSize: 15)),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Text(
              time.format(context),
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  const _SettingTile(
      {required this.icon, required this.iconColor, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
                style: AppTextStyles.headingMedium.copyWith(fontSize: 15))),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _Template template;
  final VoidCallback onTap;
  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: template.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(template.icon, color: template.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        style: AppTextStyles.headingMedium.copyWith(fontSize: 14)),
                    Text(template.description, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
