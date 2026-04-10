import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

// ─── チャンネル名定数 ─────────────────────────────────────
enum ChannelName {
    static let screenTime = "com.lockin.app/screen_time"
    static let appPicker  = "com.lockin.app/app_picker"
}

// ─── ManagedSettingsStore（アプリシールド管理）────────────
private let store = ManagedSettingsStore()

// ─── FamilyActivity選択状態の保存キー ────────────────────
private let selectionKey = "lockin_app_selection"

// ─────────────────────────────────────────────────────────
// MARK: - ScreenTimeHandler
// Flutter MethodChannel → iOS FamilyControls/ManagedSettings
// ─────────────────────────────────────────────────────────
class ScreenTimeHandler: NSObject {

    private let channel: FlutterMethodChannel
    private weak var viewController: UIViewController?

    // 現在の選択（FamilyActivityPicker で選んだアプリ群）
    private var currentSelection = FamilyActivitySelection()
    private var pickerResult: FlutterResult?

    init(messenger: FlutterBinaryMessenger, viewController: UIViewController) {
        self.channel = FlutterMethodChannel(
            name: ChannelName.screenTime,
            binaryMessenger: messenger
        )
        self.viewController = viewController
        super.init()
        channel.setMethodCallHandler(handle)
    }

    // ─── メソッドディスパッチ ──────────────────────────────
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            requestAuthorization(result: result)

        case "showAppPicker":
            showAppPicker(result: result)

        case "blockApps":
            blockApps(call: call, result: result)

        case "unblockApps":
            unblockApps(result: result)

        case "isAuthorized":
            isAuthorized(result: result)

        case "scheduleBlock":
            scheduleBlock(call: call, result: result)

        case "cancelSchedule":
            cancelSchedule(call: call, result: result)

        case "getBlockedApps":
            getBlockedApps(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 1. 認証リクエスト
    // ─────────────────────────────────────────────────────
    private func requestAuthorization(result: @escaping FlutterResult) {
        Task {
            do {
                // .individual = 個人向けスクリーンタイム管理（保護者不要）
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run { result(true) }
            } catch {
                await MainActor.run {
                    result(FlutterError(
                        code: "AUTH_FAILED",
                        message: "FamilyControls認証に失敗しました: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 2. 認証状態確認
    // ─────────────────────────────────────────────────────
    private func isAuthorized(result: @escaping FlutterResult) {
        let status = AuthorizationCenter.shared.authorizationStatus
        result(status == .approved)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 3. FamilyActivityPicker（ネイティブアプリ選択UI）
    // ─────────────────────────────────────────────────────
    private func showAppPicker(result: @escaping FlutterResult) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            result(FlutterError(
                code: "NOT_AUTHORIZED",
                message: "FamilyControlsの認証が必要です",
                details: nil
            ))
            return
        }

        pickerResult = result

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let vc = self.viewController else { return }

            let pickerVC = UIHostingController(
                rootView: FamilyActivityPickerView(
                    selection: self.$currentSelection,
                    onDone: { [weak self] in
                        guard let self = self else { return }
                        // 選択済みアプリのトークンをDartに返す
                        let count = self.currentSelection.applicationTokens.count
                            + self.currentSelection.categoryTokens.count
                        self.pickerResult?(["selectedCount": count])
                        self.pickerResult = nil
                        vc.dismiss(animated: true)
                    },
                    onCancel: { [weak self] in
                        self?.pickerResult?(nil)
                        self?.pickerResult = nil
                        vc.dismiss(animated: true)
                    }
                )
            )
            pickerVC.modalPresentationStyle = .formSheet
            vc.present(pickerVC, animated: true)
        }
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 4. アプリブロック（シールド適用）
    // ─────────────────────────────────────────────────────
    private func blockApps(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            result(FlutterError(code: "NOT_AUTHORIZED", message: "FamilyControlsの認証が必要です", details: nil))
            return
        }

        // FamilyActivityPickerで選択したトークンをシールドに適用
        store.shield.applications = currentSelection.applicationTokens.isEmpty
            ? nil
            : currentSelection.applicationTokens

        store.shield.applicationCategories = currentSelection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(currentSelection.categoryTokens)

        // シールドのカスタムUI設定
        store.shield.webDomains = currentSelection.webDomainTokens.isEmpty
            ? nil
            : currentSelection.webDomainTokens

        result(true)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 5. ブロック解除
    // ─────────────────────────────────────────────────────
    private func unblockApps(result: @escaping FlutterResult) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        result(true)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 6. スケジュールブロック（DeviceActivity）
    // ─────────────────────────────────────────────────────
    private func scheduleBlock(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let startHour = args["startHour"] as? Int,
              let startMinute = args["startMinute"] as? Int,
              let endHour = args["endHour"] as? Int,
              let endMinute = args["endMinute"] as? Int,
              let scheduleId = args["scheduleId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "引数が不正です", details: nil))
            return
        }

        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName(scheduleId)

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute),
            intervalEnd: DateComponents(hour: endHour, minute: endMinute),
            repeats: true
        )

        // 選択中のアプリ全体をイベントに設定
        let event = DeviceActivityEvent(
            applications: currentSelection.applicationTokens,
            categories: currentSelection.categoryTokens,
            webDomains: currentSelection.webDomainTokens,
            threshold: DateComponents(second: 0) // 即時発動
        )

        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [DeviceActivityEvent.Name("block"): event]
            )
            result(true)
        } catch {
            result(FlutterError(
                code: "SCHEDULE_FAILED",
                message: "スケジュール設定に失敗しました: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 7. スケジュールキャンセル
    // ─────────────────────────────────────────────────────
    private func cancelSchedule(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let scheduleId = args["scheduleId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "scheduleIdが必要です", details: nil))
            return
        }

        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName(scheduleId)])
        result(true)
    }

    // ─────────────────────────────────────────────────────
    // MARK: - 8. 現在ブロック中のアプリ数を取得
    // ─────────────────────────────────────────────────────
    private func getBlockedApps(result: @escaping FlutterResult) {
        let count = (store.shield.applications?.count ?? 0)
            + (currentSelection.categoryTokens.count)
        result(count)
    }
}

// ─────────────────────────────────────────────────────────
// MARK: - FamilyActivityPickerView（SwiftUI）
// ─────────────────────────────────────────────────────────
struct FamilyActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    var onDone: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("ブロックするアプリを選択")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル", action: onCancel)
                            .foregroundColor(.red)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完了", action: onDone)
                            .fontWeight(.semibold)
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}
