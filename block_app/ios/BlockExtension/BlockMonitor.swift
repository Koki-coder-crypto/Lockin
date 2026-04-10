import DeviceActivity
import ManagedSettings

// ─────────────────────────────────────────────────────────
// MARK: - BlockMonitor
//
// DeviceActivityMonitor Extension
// スケジュール開始・終了・イベント閾値到達時に呼ばれる
//
// ⚠️ このファイルは Xcode で別ターゲット（Extension）として追加する必要があります。
//    手順:
//    1. Xcode → File → New → Target → "Device Activity Monitor Extension"
//    2. Product Name: "BlockExtension"
//    3. このファイルをそのターゲットに追加
//    4. BlockExtension に FamilyControls entitlement を追加
// ─────────────────────────────────────────────────────────
class BlockMonitor: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    // スケジュール開始時（ブロック開始）
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyShield()
    }

    // スケジュール終了時（ブロック解除）
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        removeShield()
    }

    // 使用時間の閾値到達時（LIMIT BLOCKで使用）
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield()
    }

    // ─── シールド適用（ブロック有効化）──────────────────
    private func applyShield() {
        // UserDefaultsから保存済みの選択トークンを読み込む
        // ※ App Groupが必要: com.block.app.shared
        guard let data = UserDefaults(suiteName: "group.com.lockin.app")?
                .data(forKey: "block_selection"),
              let selection = try? JSONDecoder().decode(
                  SavedSelection.self, from: data
              ) else {
            return
        }

        // アプリシールド適用
        if !selection.applicationTokenCount.isEmpty {
            // Note: tokenはCodable非対応のためカウントのみ保存し
            // Extension内でstore全体をシールドする簡易実装
        }

        // カテゴリ全シールド（シンプル実装）
        store.shield.applicationCategories = .all()
        store.shield.webDomainCategories = .all()
    }

    // ─── シールド解除（ブロック無効化）──────────────────
    private func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }
}

// トークン情報の保存モデル（FamilyActivityTokenはCodable非対応のため代替）
struct SavedSelection: Codable {
    var applicationTokenCount: [String]  // アプリ識別用（bundle IDの代替）
    var categoryNames: [String]
}
