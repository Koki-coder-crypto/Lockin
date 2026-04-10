import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 機能名→説明のマッピング
const _featureDescriptions = {
  'schedule_block': ('SCHEDULE LOCK', 'スケジュール', '曜日・時間で自動ロック。毎日決まった時間を守れます。'),
  'sleep_mode': ('睡眠モード', '睡眠', '就寝時間を自動でブロック。深夜のスマホ依存をなくします。'),
  'app_group': ('アプリグループ', 'アプリグループ', '再利用できるアプリセットで素早くブロック設定。'),
  'strict_mode': ('Strict モード', 'Strict', '60秒クールダウンで解除を困難に。意志力を補います。'),
  'notification_block': ('通知ブロック', '通知ブロック', 'アプリと通知をセット遮断。通知から始まる誘惑を断ちます。'),
  'detailed_stats': ('詳細統計', '詳細統計', '週次レポートや時間帯ヒートマップで習慣を見える化。'),
  'unlimited': ('無制限ブロック', '無制限', '1日の回数・アプリ数に制限なし。自分のペースで管理。'),
};

class PaywallFeatureScreen extends ConsumerStatefulWidget {
  final String featureKey;
  const PaywallFeatureScreen({super.key, required this.featureKey});

  @override
  ConsumerState<PaywallFeatureScreen> createState() => _PaywallFeatureScreenState();
}

class _PaywallFeatureScreenState extends ConsumerState<PaywallFeatureScreen> {
  bool _isLoading = false;

  (String, String, String) get _featureInfo =>
      _featureDescriptions[widget.featureKey] ??
      ('Lockin+', 'プレミアム', 'この機能はLockin+プランでご利用いただけます。');

  Future<void> _purchase(Package? package) async {
    if (package == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsPremium, true);
      if (mounted) Navigator.pop(context, true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref.read(premiumProvider.notifier).purchase(package);
      if (mounted) Navigator.pop(context, success);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('購入に失敗しました'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (featureName, badgeLabel, featureDesc) = _featureInfo;
    final offeringsAsync = ref.watch(offeringsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Lockin+ バッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.redDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lockin+',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '$featureName を使うには',
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            featureDesc,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 3つのハイライト
          Row(
            children: [
              _HighlightItem(icon: Icons.shield_outlined, label: '全機能解放'),
              _HighlightItem(icon: Icons.free_cancellation_outlined, label: '7日無料'),
              _HighlightItem(icon: Icons.cancel_outlined, label: 'いつでも解約'),
            ],
          ),

          const SizedBox(height: 24),

          // 価格表示
          offeringsAsync.when(
            data: (offerings) {
              final pkg = offerings?.current?.annual;
              return Text(
                pkg != null
                    ? '${pkg.storeProduct.priceString}/年（7日間無料）'
                    : '¥3,800/年（7日間無料トライアル）',
                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary),
              );
            },
            loading: () => Text('¥3,800/年（7日間無料トライアル）',
                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary)),
            error: (_, __) => Text('¥3,800/年（7日間無料トライアル）',
                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary)),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    final pkg = offeringsAsync.value?.current?.annual;
                    _purchase(pkg);
                  },
            child: _isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('7日間無料で始める'),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('今はしない', style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HighlightItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.red, size: 24),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── ヘルパー関数（どこからでも呼べる）───────────────────
Future<bool> showPaywallFeature(BuildContext context, String featureKey) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallFeatureScreen(featureKey: featureKey),
  );
  return result ?? false;
}
