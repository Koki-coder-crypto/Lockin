import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingPermissionScreen extends StatefulWidget {
  const OnboardingPermissionScreen({super.key});

  @override
  State<OnboardingPermissionScreen> createState() =>
      _OnboardingPermissionScreenState();
}

class _OnboardingPermissionScreenState
    extends State<OnboardingPermissionScreen> {
  bool _notifGranted = false;

  static const _permissions = [
    _PermItem(
      icon: Icons.notifications_outlined,
      iconColor: AppColors.blue,
      title: '通知',
      description: '使用上限に近づいたときにお知らせします',
    ),
    _PermItem(
      icon: Icons.hourglass_bottom_outlined,
      iconColor: AppColors.red,
      title: 'スクリーンタイム',
      description: 'アプリのブロックに使用します（FamilyControls）',
    ),
    _PermItem(
      icon: Icons.lock_outline,
      iconColor: AppColors.green,
      title: 'データ保護',
      description: 'すべてのデータは端末内にのみ保存されます',
    ),
  ];

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    setState(() => _notifGranted = status.isGranted);
  }

  Future<void> _proceed() async {
    await _requestPermissions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) {
      context.push(AppRoutes.paywall, extra: true);
    }
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    if (mounted) {
      context.push(AppRoutes.paywall, extra: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              _ProgressDots(current: 3, total: 4),

              const SizedBox(height: 48),

              Text(
                'Lockinを動かすために\n許可が必要です',
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 28,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'データはすべて端末内に保存。外部送信はしません。',
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: 40),

              // 権限リスト
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(_permissions.length, (i) {
                    return Column(
                      children: [
                        _PermRow(item: _permissions[i]),
                        if (i < _permissions.length - 1)
                          const Divider(height: 1, indent: 72),
                      ],
                    );
                  }),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _proceed,
                child: const Text('許可して始める'),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: const Text('後で設定する'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _PermItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

class _PermRow extends StatelessWidget {
  final _PermItem item;
  const _PermRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(item.description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
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
