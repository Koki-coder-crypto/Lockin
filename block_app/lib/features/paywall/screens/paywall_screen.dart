import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final bool fromOnboarding;
  const PaywallScreen({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _userName = '';
  bool _isLoading = false;
  int _selectedPlanIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString(AppConstants.keyUserName) ?? '');
  }

  Future<void> _purchase(Package? package) async {
    if (package == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsPremium, true);
      if (mounted) _navigateNext();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(premiumProvider.notifier).purchase(package);
      if (mounted) {
        if (success) {
          _navigateNext();
        } else {
          _showSnack('購入がキャンセルされました');
        }
      }
    } catch (_) {
      if (mounted) _showSnack('購入に失敗しました。再度お試しください。');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(premiumProvider.notifier).restorePurchases();
      if (mounted) {
        success ? _navigateNext() : _showSnack('復元できる購入がありません');
      }
    } catch (_) {
      if (mounted) _showSnack('復元に失敗しました');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateNext() => context.go(AppRoutes.home);

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ─── ヘッダー ───────────────────────────
                  Text(
                    _userName.isNotEmpty
                        ? '$_userName さん\nスマホ依存を\n今日終わらせましょう。'
                        : 'スマホ依存を\n今日終わらせましょう。',
                    style: AppTextStyles.displayMedium.copyWith(height: 1.3),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '7日間無料トライアル',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const _TrialTimeline(),
                  const SizedBox(height: 32),
                  const _FeatureList(),
                  const SizedBox(height: 32),

                  // ─── プラン選択 ─────────────────────────
                  offeringsAsync.when(
                    data: (offerings) {
                      final packages =
                          offerings?.current?.availablePackages ?? [];
                      return _PlanSelector(
                        packages: packages,
                        selectedIndex: _selectedPlanIndex,
                        onSelect: (i) =>
                            setState(() => _selectedPlanIndex = i),
                      );
                    },
                    loading: () => const _PlanSelectorPlaceholder(),
                    error: (_, __) => const _PlanSelectorPlaceholder(),
                  ),

                  const SizedBox(height: 24),

                  // ─── CTA ────────────────────────────────
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final packages = offeringsAsync
                                    .value?.current?.availablePackages ??
                                [];
                            final pkg = packages.isNotEmpty &&
                                    _selectedPlanIndex < packages.length
                                ? packages[_selectedPlanIndex]
                                : null;
                            _purchase(pkg);
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('7日間無料で始める'),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _navigateNext,
                      child: Text(
                        '後で試す（無料プランで続ける）',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),

                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _restore,
                      child: Text('購入を復元する',
                          style: AppTextStyles.labelMedium),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '• 無料トライアル終了後、自動で課金が始まります\n'
                    '• キャンセルはいつでもApp Storeから可能です\n'
                    '• プライバシーポリシー・利用規約はApp Store掲載を参照',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                    child: CircularProgressIndicator(color: AppColors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── トライアルタイムライン ───────────────────────────────
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _TimelineRow(
            day: '今日',
            label: 'トライアル開始',
            description: '完全無料でLockin+が全機能使えます',
            color: AppColors.green,
            isFirst: true,
          ),
          _TimelineRow(
            day: '5日目',
            label: 'リマインダー',
            description: 'トライアル終了2日前に通知でお知らせ',
            color: AppColors.amber,
          ),
          _TimelineRow(
            day: '7日目',
            label: 'トライアル終了',
            description: 'キャンセルしなければ自動で課金開始',
            color: AppColors.red,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String day, label, description;
  final Color color;
  final bool isFirst, isLast;

  const _TimelineRow({
    required this.day,
    required this.label,
    required this.description,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Container(width: 1, height: 40, color: AppColors.border),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(day,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(width: 8),
                  Text(label,
                      style:
                          AppTextStyles.headingMedium.copyWith(fontSize: 14)),
                ]),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 機能リスト ──────────────────────────────────────────
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_outlined, 'NOW LOCK 無制限', '1日何度でもロック開始'),
      (Icons.schedule_outlined, 'SCHEDULE LOCK', '曜日・時間の自動ロック'),
      (Icons.nights_stay_outlined, '睡眠モード', '就寝時間を自動ブロック'),
      (Icons.security_outlined, 'Strict モード', '60秒クールダウンで解除困難化'),
      (Icons.bar_chart_outlined, '詳細統計', '週次レポート・時間帯ヒートマップ'),
      (Icons.all_inclusive_outlined, '無制限利用', 'アプリ数・期間制限なし'),
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.redDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$1, color: AppColors.red, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2,
                        style: AppTextStyles.headingMedium
                            .copyWith(fontSize: 14)),
                    Text(item.$3, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.check_circle,
                  color: AppColors.green, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── プラン選択（RevenueCatあり）────────────────────────
class _PlanSelector extends StatelessWidget {
  final List<Package> packages;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _PlanSelector({
    required this.packages,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) return const _PlanSelectorPlaceholder();
    return Column(
      children: List.generate(packages.length, (i) {
        final pkg = packages[i];
        final isSelected = selectedIndex == i;
        final isYearly = pkg.packageType == PackageType.annual;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.redDim
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? AppColors.red : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                              isYearly ? '年間プラン' : '月額プラン',
                              style: AppTextStyles.headingMedium),
                          if (isYearly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'おすすめ',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(pkg.storeProduct.priceString,
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.red
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PlanSelectorPlaceholder extends StatelessWidget {
  const _PlanSelectorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StaticPlanCard(
          title: '月額プラン',
          price: '¥480/月',
          isSelected: false,
        ),
        const SizedBox(height: 12),
        _StaticPlanCard(
          title: '年間プラン',
          price: '¥3,800/年（約58%お得）',
          isSelected: true,
          badge: 'おすすめ',
        ),
      ],
    );
  }
}

class _StaticPlanCard extends StatelessWidget {
  final String title, price;
  final bool isSelected;
  final String? badge;

  const _StaticPlanCard({
    required this.title,
    required this.price,
    required this.isSelected,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.redDim : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.red : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title, style: AppTextStyles.headingMedium),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(price, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected ? AppColors.red : AppColors.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }
}
