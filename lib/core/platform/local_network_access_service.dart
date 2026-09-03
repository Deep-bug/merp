// -----------------------------------------------------------------------------
// 文件：local_network_access_service.dart
// 作用：封装 iOS 本地网络访问检查及系统设置跳转
// 维护说明：iOS 没有通用权限查询 API，原生端通过 NWConnection 判断拒绝原因
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum LocalNetworkAccessStatus { notRequired, allowed, denied, unavailable }

class LocalNetworkAccessResult {
  const LocalNetworkAccessResult(this.status, {this.detail});

  final LocalNetworkAccessStatus status;
  final String? detail;
}

abstract interface class LocalNetworkAccessChecking {
  Future<LocalNetworkAccessResult> check(String apiBaseUrl);

  Future<bool> openAppSettings();
}

/// iOS 内网启动检查；Android和公网地址不会调用原生层。
class LocalNetworkAccessService implements LocalNetworkAccessChecking {
  LocalNetworkAccessService({MethodChannel? channel, TargetPlatform? platform})
    : _channel = channel ?? const MethodChannel(_channelName),
      _platform = platform ?? defaultTargetPlatform;

  static const _channelName = 'com.delta.merpdelta/local_network';

  final MethodChannel _channel;
  final TargetPlatform _platform;

  @override
  Future<LocalNetworkAccessResult> check(String apiBaseUrl) async {
    final uri = Uri.tryParse(apiBaseUrl.trim());
    if (_platform != TargetPlatform.iOS ||
        uri == null ||
        !_requiresLocalNetwork(uri)) {
      return const LocalNetworkAccessResult(
        LocalNetworkAccessStatus.notRequired,
      );
    }

    try {
      final raw = await _channel
          .invokeMapMethod<String, Object?>('checkAccess', {
            'host': uri.host,
            'port': uri.hasPort
                ? uri.port
                : uri.scheme.toLowerCase() == 'https'
                ? 443
                : 80,
          });
      final status = switch (raw?['status']) {
        'allowed' => LocalNetworkAccessStatus.allowed,
        'denied' => LocalNetworkAccessStatus.denied,
        _ => LocalNetworkAccessStatus.unavailable,
      };
      return LocalNetworkAccessResult(
        status,
        detail: raw?['message']?.toString(),
      );
    } on PlatformException catch (error) {
      return LocalNetworkAccessResult(
        LocalNetworkAccessStatus.unavailable,
        detail: error.message ?? error.code,
      );
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (_platform != TargetPlatform.iOS) return false;
    return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
  }

  static bool _requiresLocalNetwork(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host.endsWith('.local')) return true;

    final ipv4 = host.split('.').map(int.tryParse).toList(growable: false);
    if (ipv4.length == 4 && ipv4.every((part) => part != null)) {
      final first = ipv4[0]!;
      final second = ipv4[1]!;
      return first == 10 ||
          (first == 172 && second >= 16 && second <= 31) ||
          (first == 192 && second == 168) ||
          (first == 169 && second == 254);
    }

    // IPv6 唯一本地地址和链路本地地址。
    return host.startsWith('fc') ||
        host.startsWith('fd') ||
        host.startsWith('fe80:');
  }
}
