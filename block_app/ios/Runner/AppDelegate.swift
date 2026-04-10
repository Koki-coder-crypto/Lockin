import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // ScreenTimeHandler を保持（ARC で解放されないように）
  private var screenTimeHandler: ScreenTimeHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // FlutterViewController を取得してChannelを初期化
    guard let flutterVC = engineBridge.viewController as? FlutterViewController else {
      return
    }

    screenTimeHandler = ScreenTimeHandler(
      messenger: flutterVC.binaryMessenger,
      viewController: flutterVC
    )
  }
}
