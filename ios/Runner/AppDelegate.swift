import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    configureWebDataChannel(with: engineBridge.pluginRegistry)
  }

  /// 清理 WKWebView 的网站数据，不会触碰 Keychain、UserDefaults 或 Flutter 的
  /// 安全存储，因此 MERP App 登录、收藏及安全设置都不会被删除。
  private func configureWebDataChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "MerpWebDataCleaner") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.delta.merpdelta/webview_data",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "clearAllWebData" else {
        result(FlutterMethodNotImplemented)
        return
      }

      // allWebsiteDataTypes 包含 HTTP 缓存、Cookie、LocalStorage、IndexedDB、
      // Service Worker 等 H5 数据；不会影响原生 App 的数据域。
      WKWebsiteDataStore.default().removeData(
        ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
        modifiedSince: Date(timeIntervalSince1970: 0)
      ) {
        result(true)
      }
    }
  }
}
