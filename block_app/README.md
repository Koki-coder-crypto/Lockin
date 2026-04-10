# Lockin - スマホ依存対策アプリ

> ロックして、本当の時間を取り戻す。

## Codemagic ビルド前の必須手順

### 1. RevenueCat キーを設定する
`lib/core/constants/app_constants.dart` の以下を実際のキーに変更:
```dart
static const String rcApiKeyIos = 'appl_xxxxxxxxxxxxxxxx';
static const String rcApiKeyAndroid = 'goog_xxxxxxxxxxxxxxxx';
```

または Codemagic の Environment Variables に以下を設定:
- `REVENUECAT_IOS_KEY`
- `REVENUECAT_ANDROID_KEY`

### 2. Firebase（Phase2 - 必要になったら有効化）
`pubspec.yaml` の firebase_core / firebase_auth のコメントアウトを外し、
- iOS: `ios/Runner/GoogleService-Info.plist` を追加
- Android: `android/app/google-services.json` を追加

### 3. iOS: FamilyControls Entitlement
Apple に Family Controls entitlement の申請が必要:
https://developer.apple.com/contact/request/family-controls-distribution

Xcode → Signing & Capabilities → + → Family Controls

### 4. iOS: App Icon
`flutter_launcher_icons` でアイコン生成:
```bash
dart run flutter_launcher_icons
```

### 5. Codemagic 環境変数（codemagic.yaml 参照）
| 変数名 | 説明 |
|--------|------|
| `APP_STORE_CONNECT_PRIVATE_KEY` | App Store Connect API key |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | Google Play サービスアカウント |
| `FIREBASE_IOS_GOOGLE_SERVICES` | GoogleService-Info.plist (base64) |
| `FIREBASE_ANDROID_GOOGLE_SERVICES` | google-services.json (base64) |

### 6. Android: minSdkVersion
`android/app/build.gradle` の minSdk を 26 以上に設定（UsageStats API）

## ローカル開発
```bash
flutter pub get
flutter run
```

## アーキテクチャ
- **状態管理**: Riverpod 2.x (StateNotifierProvider)
- **ルーティング**: go_router 14.x
- **課金**: purchases_flutter (RevenueCat)
- **データ**: SharedPreferences + JSON
- **フォント**: Google Fonts (Noto Sans/Serif JP)
- **iOS ブロック**: FamilyControls + ManagedSettings + DeviceActivity
- **Android ブロック**: UsageStatsManager + AccessibilityService
