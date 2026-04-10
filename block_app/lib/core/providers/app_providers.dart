import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../data/models/block_session.dart';
import '../../data/repositories/block_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../constants/app_constants.dart';

// ─── リポジトリ ──────────────────────────────────────────
final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return BlockRepository();
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(blockRepositoryProvider));
});

// ─── プレミアム状態 ───────────────────────────────────────
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(AppConstants.keyIsPremium) ?? false;
    state = cached;
    await _checkFromRevenueCat();
  }

  Future<void> _checkFromRevenueCat() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium = customerInfo.entitlements
          .active
          .containsKey(AppConstants.entitlementPremium);
      state = isPremium;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsPremium, isPremium);
    } catch (_) {
      // RevenueCat未設定時は cached 値を使う
    }
  }

  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final isPremium = result.entitlements
          .active
          .containsKey(AppConstants.entitlementPremium);
      state = isPremium;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsPremium, isPremium);
      return isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final result = await Purchases.restorePurchases();
      final isPremium = result.entitlements
          .active
          .containsKey(AppConstants.entitlementPremium);
      state = isPremium;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyIsPremium, isPremium);
      return isPremium;
    } catch (_) {
      return false;
    }
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

// ─── 名言データ ──────────────────────────────────────────
final quotesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final json = await rootBundle.loadString('assets/data/quotes.json');
  final data = jsonDecode(json) as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(data['quotes'] as List);
});

// ─── ブロックセッション状態 ───────────────────────────────
enum BlockStatus { idle, friction, active, strictCooldown }

class BlockState {
  final BlockStatus status;
  final BlockSession? session;
  final int frictionCountdown; // seconds remaining in friction
  final int strictCooldown;    // seconds remaining in strict cooldown

  const BlockState({
    this.status = BlockStatus.idle,
    this.session,
    this.frictionCountdown = 0,
    this.strictCooldown = 0,
  });

  BlockState copyWith({
    BlockStatus? status,
    BlockSession? session,
    int? frictionCountdown,
    int? strictCooldown,
  }) {
    return BlockState(
      status: status ?? this.status,
      session: session ?? this.session,
      frictionCountdown: frictionCountdown ?? this.frictionCountdown,
      strictCooldown: strictCooldown ?? this.strictCooldown,
    );
  }
}

class BlockNotifier extends StateNotifier<BlockState> {
  final BlockRepository _repo;
  Timer? _frictionTimer;
  Timer? _strictTimer;

  BlockNotifier(this._repo) : super(const BlockState()) {
    _restoreActiveSession();
  }

  Future<void> _restoreActiveSession() async {
    final active = await _repo.getActiveSession();
    if (active != null) {
      state = BlockState(status: BlockStatus.active, session: active);
    }
  }

  // フリクションモード開始（10秒カウントダウン）
  Future<void> startFriction({
    required List<String> appNames,
    required int durationMinutes,
    required bool strictMode,
    required bool frictionEnabled,
  }) async {
    if (!frictionEnabled) {
      await startBlock(
        appNames: appNames,
        durationMinutes: durationMinutes,
        strictMode: strictMode,
      );
      return;
    }

    state = state.copyWith(
      status: BlockStatus.friction,
      frictionCountdown: AppConstants.frictionModeDelaySeconds,
    );

    _frictionTimer?.cancel();
    int countdown = AppConstants.frictionModeDelaySeconds;
    _frictionTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      countdown--;
      state = state.copyWith(frictionCountdown: countdown);
      if (countdown <= 0) {
        t.cancel();
        await startBlock(
          appNames: appNames,
          durationMinutes: durationMinutes,
          strictMode: strictMode,
        );
      }
    });

  }

  void cancelFriction() {
    _frictionTimer?.cancel();
    state = const BlockState();
  }

  // ブロック開始
  Future<void> startBlock({
    required List<String> appNames,
    required int durationMinutes,
    required bool strictMode,
  }) async {
    final session = BlockSession(
      id: BlockRepository.generateId(),
      mode: BlockMode.now,
      appNames: appNames,
      startedAt: DateTime.now(),
      durationMinutes: durationMinutes,
      strictMode: strictMode,
    );

    await _repo.setActiveSession(session);
    await _repo.incrementNowBlockCount();
    state = BlockState(status: BlockStatus.active, session: session);
  }

  // ブロック解除試み（Strictモード: 60秒クールダウン）
  Future<bool> requestStop() async {
    final session = state.session;
    if (session == null) return false;

    if (session.strictMode && state.status != BlockStatus.strictCooldown) {
      state = state.copyWith(
        status: BlockStatus.strictCooldown,
        strictCooldown: AppConstants.strictModeCooldownSeconds,
      );
      int countdown = AppConstants.strictModeCooldownSeconds;
      _strictTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        countdown--;
        state = state.copyWith(strictCooldown: countdown);
        if (countdown <= 0) {
          t.cancel();
          // クールダウン終了後もまだ active（ユーザーが再度停止ボタンを押す必要あり）
          state = state.copyWith(status: BlockStatus.active, strictCooldown: 0);
        }
      });
      return false; // まだ停止できない
    }

    await endBlock(completed: false);
    return true;
  }

  // ブロック完了
  Future<void> endBlock({required bool completed}) async {
    final session = state.session;
    if (session == null) return;

    _frictionTimer?.cancel();
    _strictTimer?.cancel();

    final ended = session.copyWith(
      endedAt: DateTime.now(),
      completed: completed,
    );
    await _repo.saveSession(ended);
    await _repo.setActiveSession(null);
    if (completed) {
      await _repo.updateStreak();
    }
    state = const BlockState();
  }

  @override
  void dispose() {
    _frictionTimer?.cancel();
    _strictTimer?.cancel();
    super.dispose();
  }
}

final blockProvider = StateNotifierProvider<BlockNotifier, BlockState>((ref) {
  return BlockNotifier(ref.watch(blockRepositoryProvider));
});

// ─── 今日の統計 ──────────────────────────────────────────
final todayStatsProvider = FutureProvider((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getStatsForDate(DateTime.now());
});

final weeklyStatsProvider = FutureProvider((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getWeeklyStats();
});

final nowBlockCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(blockRepositoryProvider);
  return repo.getTodayNowBlockCount();
});

final streakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(blockRepositoryProvider);
  return repo.getStreak();
});

// ─── RevenueCat パッケージ ───────────────────────────────
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (_) {
    return null;
  }
});
