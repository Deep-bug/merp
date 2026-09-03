import Flutter
import Network
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let localNetworkProbeQueue = DispatchQueue(
    label: "com.delta.merpdelta.local-network-probe"
  )
  private var localNetworkProbe: NWConnection?
  private var localNetworkProbeResult: FlutterResult?
  private var localNetworkProbeTimeout: DispatchWorkItem?

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
    configureLocalNetworkChannel(with: engineBridge.pluginRegistry)
  }

  /// iOS 没有通用的“查询/申请本地网络权限”API。这里使用一次真实 TCP
  /// NWConnection 触发系统授权，并通过 currentPath.unsatisfiedReason 区分
  /// 用户拒绝和普通网络不可达。Flutter 登录页会在此检查完成后才显示。
  private func configureLocalNetworkChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "MerpLocalNetworkAccess") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.delta.merpdelta/local_network",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "LOCAL_NETWORK_BRIDGE_UNAVAILABLE",
            message: "本地网络检查服务不可用",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "checkAccess":
        self.startLocalNetworkProbe(arguments: call.arguments, result: result)
      case "openAppSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in
          result(opened)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startLocalNetworkProbe(arguments: Any?, result: @escaping FlutterResult) {
    guard localNetworkProbe == nil else {
      result(
        FlutterError(
          code: "LOCAL_NETWORK_CHECK_IN_PROGRESS",
          message: "本地网络检查正在进行",
          details: nil
        )
      )
      return
    }
    guard
      let values = arguments as? [String: Any],
      let hostValue = values["host"] as? String,
      !hostValue.isEmpty,
      let portValue = values["port"] as? NSNumber,
      let port = NWEndpoint.Port(rawValue: portValue.uint16Value)
    else {
      result(
        FlutterError(
          code: "LOCAL_NETWORK_TARGET_INVALID",
          message: "内网服务地址无效",
          details: nil
        )
      )
      return
    }

    let connection = NWConnection(
      host: NWEndpoint.Host(hostValue),
      port: port,
      using: .tcp
    )
    localNetworkProbe = connection
    localNetworkProbeResult = result

    connection.stateUpdateHandler = { [weak self, weak connection] state in
      guard let self, let connection else { return }
      switch state {
      case .ready:
        self.finishLocalNetworkProbe(
          connection: connection,
          status: "allowed",
          message: nil
        )
      case .waiting(let error):
        if self.isLocalNetworkDenied(connection) {
          self.finishLocalNetworkProbe(
            connection: connection,
            status: "denied",
            message: "Local network access was denied."
          )
        } else {
          // Wi-Fi/VPN 建链过程中可能短暂 waiting，继续等到 ready 或超时。
          NSLog("MERP local network probe waiting: %@", String(describing: error))
        }
      case .failed(let error):
        self.finishLocalNetworkProbe(
          connection: connection,
          status: self.isLocalNetworkDenied(connection) ? "denied" : "unavailable",
          message: String(describing: error)
        )
      case .cancelled:
        break
      default:
        break
      }
    }

    let timeout = DispatchWorkItem { [weak self, weak connection] in
      guard let self, let connection else { return }
      self.finishLocalNetworkProbe(
        connection: connection,
        status: self.isLocalNetworkDenied(connection) ? "denied" : "unavailable",
        message: "Local network connection timed out."
      )
    }
    localNetworkProbeTimeout = timeout
    localNetworkProbeQueue.asyncAfter(deadline: .now() + 30, execute: timeout)
    connection.start(queue: localNetworkProbeQueue)
  }

  private func isLocalNetworkDenied(_ connection: NWConnection) -> Bool {
    if #available(iOS 14.2, *) {
      return connection.currentPath?.unsatisfiedReason == .localNetworkDenied
    }
    return false
  }

  private func finishLocalNetworkProbe(
    connection: NWConnection,
    status: String,
    message: String?
  ) {
    DispatchQueue.main.async { [weak self, weak connection] in
      guard
        let self,
        let connection,
        self.localNetworkProbe === connection,
        let result = self.localNetworkProbeResult
      else {
        return
      }
      self.localNetworkProbeTimeout?.cancel()
      self.localNetworkProbeTimeout = nil
      self.localNetworkProbe = nil
      self.localNetworkProbeResult = nil
      connection.stateUpdateHandler = nil
      connection.cancel()
      var payload: [String: Any] = ["status": status]
      if let message {
        payload["message"] = message
      }
      result(payload)
    }
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
