# Lockin アプリ - プロジェクト仕様書

## アプリ概要
- **アプリ名**: Lockin
- **タグライン**: 「ロックして、本当の時間を取り戻す。」
- **ジャンル**: スマホ依存対策・スクリーンタイム管理
- **ターゲット**: スマホ依存を自覚している15〜35歳の日本人
- **プラットフォーム**: iOS / Android（Flutter クロスプラットフォーム）

---

## 技術スタック

```
言語:           Dart（Flutter 3.x）
状態管理:       Riverpod 2.x
ルーティング:   go_router
ローカルDB:     Isar
課金:           purchases_flutter（RevenueCat）
認証:           firebase_auth（Apple / Google サインイン）
アニメーション: flutter_animate
グラフ:         fl_chart
iOS native:     FamilyControls / ManagedSettings / DeviceActivity（Swift, Platform Channel）
Android native: AccessibilityService / UsageStatsManager（Kotlin, Platform Channel）
CI/CD:          Codemagic
```

---

## カラースキーム

```
Background:       #111318   深いネイビーグレー
Surface:          #1C2027   カード・ボトムシート
Surface+:         #252B34   入力・セル
Border:           #2E3440   区切り線
Text/Primary:     #F0F2F5   メインテキスト
Text/Secondary:   #7B8494   サブテキスト

Red（ブロック中）: #FF3333
Green（達成）:     #1DB954
Blue（情報）:      #4A9EFF
Amber（警告）:     #FFB300
```

## タイポグラフィ

```
数字（大）: SF Pro Display Bold / Roboto Bold
日本語見出し: Noto Sans JP Bold (700)
日本語本文:   Noto Sans JP Regular (400)
名言テキスト: Noto Serif JP Italic  ← 名言だけセリフ体
```

## UIルール

```
角丸:           16px（カード）/ 12px（ボタン）/ 8px（タグ）
影:             なし（フラットデザイン）
アニメーション: 200ms ease-out（状態遷移）
ハプティクス:   ブロック開始 → Heavy Impact
                達成時 → Success Notification
                Strict解除試み → Warning
```

---

## 画面構成（BottomTab: ホーム / ブロック / 記録 / 設定）

### オンボーディング（3画面 + ペイウォール）
1. `onboarding_usage` - 1日の使用時間を選ぶ（パーソナライズ）
2. `onboarding_shock` - 衝撃データ提示（「○○さん、年間1,825時間」）
3. `onboarding_permission` - 権限取得（通知・使用状況・アクセシビリティ）
4. `paywall` - 7日間無料トライアル（アニメーション付き・ユーザー名入り）

### メイン画面
5. `home` - 今日の使用時間リング・「今すぐBLOCK」ボタン・ストリーク
6. `block_setup` - 3モード選択・アプリ選択・ホワイトリスト・Strictトグル
7. `blocking_active` - 全画面ブロック中（タイマー＋名言＋偉人名）
8. `block_complete` - 達成画面（時間・名言・次のアクション）
9. `stats` - 週次グラフ・アプリ別使用量・ピックアップ回数・ストリーク
10. `settings` - テンプレート・睡眠モード・アプリグループ・BLOCK+管理

### ペイウォール（インアップ）
11. `paywall_feature` - 機能タッチ時のコンテキスト型
12. `paywall_limit` - 上限到達型
13. `paywall_weekly` - 週次レポート型

---

## 機能一覧

### 無料（BLOCK）
- **NOW BLOCK**: 今すぐ◯分ブロック（5回/日）
- **LIMIT BLOCK**: アプリ別1日上限（3アプリまで）
- **フリクションモード**: ブロック前に名言＋「本当に必要？」10秒表示
- **テンプレート**: 勉強・睡眠・仕事のプリセット
- **ホワイトリスト**: 常時許可アプリ設定（電話・マップ・カメラはデフォルト許可）
- **ストリーク**: 連続達成日数カウント
- **名言表示**: ブロック中・達成後・ホーム画面（ローカルJSON 100件以上）
- **統計**: 7日間のアプリ別使用時間

### BLOCK+（プレミアム）
- 上記すべて無制限
- **SCHEDULE BLOCK**: 曜日×時間の自動ブロック
- **睡眠モード**: 就寝時間自動ブロック
- **アプリグループ**: 再利用可能なアプリセット
- **通知ブロック**: アプリブロックと通知をセット遮断
- **Strictモード**: 60秒クールダウン（解除困難化）
- **詳細統計**: ピックアップ回数・時間帯ヒートマップ・無制限期間
- **週次レポート**: PDF書き出し
- **ウィジェット**: ホーム画面・ロック画面

---

## 名言機能

- 表示タイミング: ブロック中（60秒ごとにフェード切り替え）・達成後・ホーム画面（デイリー）
- データ: ローカルJSON（100件以上）、カテゴリ別（集中・意志・時間・成功）
- フォント: Noto Serif JP Italic（名言）/ Text/Secondary（偉人名）

---

## 課金設計

```
無料:      5回/日 NOW BLOCK・3アプリLIMIT・7日統計
BLOCK+:   ¥480/月 or ¥3,800/年（7日無料トライアル）
買い切り:  ¥2,480（日本市場向け）
```

### ペイウォール表示タイミング
1. オンボーディング完了直後（最重要・82%がDay1で決定）
2. 機能タッチ時（コンテキスト型）
3. 5回上限到達時
4. 毎週月曜プッシュ通知→週次レポート画面

---

## 実装フェーズ

### Phase 1（MVP・5週間）
- [ ] Flutterプロジェクト初期化
- [ ] テーマ・カラー・フォント設定（app_theme.dart）
- [ ] go_router ルーティング設定
- [ ] 名言JSONデータ作成（quotes.json）
- [ ] オンボーディング3画面
- [ ] ペイウォール画面（RevenueCat接続）
- [ ] ホーム画面
- [ ] ブロック設定画面（NOW / LIMIT / SCHEDULE）
- [ ] ブロック中全画面（タイマー＋名言）
- [ ] 達成画面
- [ ] iOS Platform Channel（FamilyControls / ManagedSettings）
- [ ] Android Platform Channel（AccessibilityService / UsageStatsManager）

### Phase 2（課金・リリース・3週間）
- [ ] RevenueCat完全統合
- [ ] インアップペイウォール3種
- [ ] Strictモード・フリクションモード
- [ ] 統計画面（fl_chart）
- [ ] ストリーク実装
- [ ] App Store / Google Play 申請

### Phase 3（拡張・4週間）
- [ ] 睡眠モード
- [ ] アプリグループ
- [ ] 通知ブロック
- [ ] ウィジェット（iOS / Android）
- [ ] 週次レポートPDF

---

## プロジェクト構成

```
block_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme/app_theme.dart        # カラー・フォント・コンポーネントスタイル
│   │   ├── router/app_router.dart      # go_router設定
│   │   ├── constants/app_constants.dart
│   │   └── providers/                  # Riverpod グローバルプロバイダ
│   ├── features/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── block/
│   │   ├── stats/
│   │   ├── settings/
│   │   └── paywall/
│   ├── data/
│   │   ├── local/                      # Isar DB
│   │   ├── models/
│   │   └── repositories/
│   └── platform/
│       ├── ios/screen_time_channel.dart
│       └── android/usage_stats_channel.dart
├── assets/
│   ├── data/quotes.json                # 名言データ
│   └── fonts/
├── ios/
│   ├── Runner/
│   └── BlockExtension/                 # DeviceActivityMonitor
└── android/
    └── app/src/main/kotlin/
        ├── MainActivity.kt
        ├── BlockingService.kt
        └── AccessibilityBlocker.kt
```

---

## 参考競合アプリ
- **Blockin** (life.blockin) - シンプルUI・3ブロックタイプの参考
- **Opal** - ペイウォール設計・タイムライン演出の参考
- **Jomo** - テンプレート・ホワイトリスト・AppHealth連携の参考
- **ScreenZen** - フリクションモード・呼吸エクササイズの参考
- **Forest** - ストリーク・ゲーミフィケーションの参考
