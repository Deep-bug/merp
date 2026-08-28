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
    configureAppUpdateChannel(with: engineBridge.pluginRegistry)
  }

  /// iOS 企业分发由系统处理下载和安装；Flutter 只负责打开 itms-services 链接。
  private func configureAppUpdateChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "MerpAppUpdater") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.delta.merpdelta/app_update",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openEnterpriseInstall" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let value = arguments["url"] as? String,
        let url = URL(string: value),
        url.scheme == "itms-services" || url.scheme == "https"
      else {
        result(
          FlutterError(
            code: "ENTERPRISE_INSTALL_URL_INVALID",
            message: "企业安装链接格式不正确",
            details: nil
          )
        )
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }
    }
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
