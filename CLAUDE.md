# Lockin アプリ - プロジェクト仕様書

## アプリ概要
- **アプリ名**: Lockin
- **タグライン**: 「ロックして、本当の時間を取り戻す。」
- **ジャンル**: スマホ依存対策・スクリーンタイム管理
- **ターゲット**: スマホ依存を自覚している15〜35歳の日本人
- **プラットフォーム**: iOS 専用（SwiftUI ネイティブ）

---

## 技術スタック

```
言語:           Swift 5.9
UI:             SwiftUI（iOS 17+ 前提）
状態管理:       @StateObject / @EnvironmentObject / @AppStorage
永続化:         AppStorage (UserDefaults) · 将来 SwiftData 検討
課金:           StoreKit 2（RevenueCat は任意）
ブロック:       FamilyControls / ManagedSettings / DeviceActivity
グラフ:         Swift Charts
アニメーション: SwiftUI Spring / PhaseAnimator / TimelineView / symbolEffect
ハプティクス:   .sensoryFeedback
プロジェクト:   XcodeGen（project.yml → .xcodeproj をCIで生成）
CI/CD:          Codemagic（mac_mini_m2 インスタンス・macOS 不要）
```

### プロジェクト生成の流れ
ローカル Windows では `.xcodeproj` を持たず、`project.yml` のみを管理する。
Codemagic の macOS ランナーが `brew install xcodegen` → `xcodegen generate` で
`.xcodeproj` を生成し、`xcodebuild` でアーカイブ → TestFlight に配信する。

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

### Phase 1（MVP・完了）
- [x] XcodeGen + Codemagic 構成（Windows 完結ビルド）
- [x] デザイントークン（Colors / Typography / Motion）
- [x] AppState + @AppStorage 永続化
- [x] 名言 JSON（100件以上・カテゴリ別）
- [x] オンボーディング 4画面（Usage → Shock → Goal → Permission）
- [x] ペイウォール（年/月/買い切り・シマーCTA）
- [x] ホーム（グラデリング・LOCK ボタン・ストリーク・デイリー名言）
- [x] ブロック設定（NOW / LIMIT / SCHEDULE・アプリ選択・Strict）
- [x] ブロック中全画面（TimelineView 秒刻み・名言 60s 回転・長押し解除）
- [x] 達成画面（成功ハプティクス・名言）
- [x] 統計（Swift Charts 週次バー・ストリーク・ピックアップ）
- [x] 設定（セクション・Lockin+ アップセル）

### Phase 2（課金・リリース）
- [ ] StoreKit 2 または RevenueCat 接続
- [ ] 実際の FamilyControls Selection UI（FamilyActivityPicker）
- [ ] ManagedSettings でのシールド適用
- [ ] DeviceActivityMonitor Extension 追加
- [ ] App Store 申請・FamilyControls エンタイトルメント承認

### Phase 3（拡張）
- [ ] 睡眠モード自動ブロック
- [ ] アプリグループ（再利用可能セット）
- [ ] ウィジェット（WidgetKit・ロック画面）
- [ ] 週次レポート PDF 書き出し
- [ ] Live Activities（Dynamic Island）

---

## プロジェクト構成

```
スクリーンタイム管理アプリ/
├── project.yml                          # XcodeGen 定義（唯一の真実）
├── codemagic.yaml                       # iOS TestFlight ワークフロー
├── Lockin/
│   ├── App/
│   │   ├── LockinApp.swift              # @main
│   │   ├── AppState.swift               # ObservableObject + @AppStorage
│   │   └── RootView.swift               # Onboarding/MainTab 切替
│   ├── Theme/
│   │   ├── LockinColors.swift
│   │   ├── LockinTypography.swift
│   │   └── LockinMotion.swift
│   ├── Components/
│   │   ├── ProgressDots.swift
│   │   ├── PrimaryButton.swift
│   │   ├── UsageRing.swift
│   │   └── QuoteCard.swift
│   ├── Features/
│   │   ├── Onboarding/                  # 4 screens
│   │   ├── Home/
│   │   ├── Paywall/
│   │   ├── Block/                       # Setup / Active / Complete
│   │   ├── Stats/
│   │   └── Settings/
│   ├── Data/
│   │   ├── Quote.swift
│   │   └── BlockSession.swift
│   └── Resources/
│       ├── Info.plist                   # XcodeGen が生成
│       ├── Lockin.entitlements          # XcodeGen が生成
│       ├── quotes.json
│       └── Assets.xcassets/
└── _archive_flutter/                    # 旧 Flutter 実装（参照用）
```

---

## 参考競合アプリ
- **Blockin** (life.blockin) - シンプルUI・3ブロックタイプの参考
- **Opal** - ペイウォール設計・タイムライン演出の参考
- **Jomo** - テンプレート・ホワイトリスト・AppHealth連携の参考
- **ScreenZen** - フリクションモード・呼吸エクササイズの参考
- **Forest** - ストリーク・ゲーミフィケーションの参考
