// -----------------------------------------------------------------------------
// 文件：app_update_platform.dart
// 作用：通过原生通道打开 Android 安装器或 iOS 企业分发链接
// -----------------------------------------------------------------------------

import 'package:flutter/services.dart';

enum AndroidInstallResult { installerOpened, permissionOpened }

abstract interface class AppUpdatePlatform {
  Future<AndroidInstallResult> installAndroidPackage(String filePath);
  Future<void> openIosEnterpriseInstall(Uri url);
}

class MethodChannelAppUpdatePlatform implements AppUpdatePlatform {
  MethodChannelAppUpdatePlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.delta.merpdelta/app_update';
  final MethodChannel _channel;

  @override
  Future<AndroidInstallResult> installAndroidPackage(String filePath) async {
    final value = await _channel.invokeMethod<String>('installApk', {
      'filePath': filePath,
    });
    return switch (value) {
      'installerOpened' => AndroidInstallResult.installerOpened,
      'permissionOpened' => AndroidInstallResult.permissionOpened,
      _ => throw PlatformException(
        code: 'INVALID_INSTALL_RESULT',
        message: 'Android 安装器返回了未知状态：$value',
      ),
    };
  }

  @override
  Future<void> openIosEnterpriseInstall(Uri url) async {
    final opened = await _channel.invokeMethod<bool>('openEnterpriseInstall', {
      'url': url.toString(),
    });
    if (opened != true) {
      throw PlatformException(
        code: 'ENTERPRISE_INSTALL_OPEN_FAILED',
        message: '无法打开 iOS 企业分发安装链接',
      );
    }
  }
}
