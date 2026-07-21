// -----------------------------------------------------------------------------
// 文件：device_info_service.dart
// 作用：向 Bridge 返回非敏感设备信息和当前 App 版本
// -----------------------------------------------------------------------------

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  DeviceInfoService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  Future<Map<String, Object?>> getInfo() async {
    final package = await PackageInfo.fromPlatform();
    final app = <String, Object?>{
      'name': package.appName,
      'packageName': package.packageName,
      'version': package.version,
      'buildNumber': package.buildNumber,
    };

    if (kIsWeb) {
      return {'platform': 'web', 'isPhysicalDevice': false, 'app': app};
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidInfo(app),
      TargetPlatform.iOS => _iosInfo(app),
      _ => {
        'platform': defaultTargetPlatform.name,
        'isPhysicalDevice': true,
        'app': app,
      },
    };
  }

  Future<Map<String, Object?>> _androidInfo(Map<String, Object?> app) async {
    final info = await _deviceInfo.androidInfo;
    return {
      'platform': 'android',
      'manufacturer': info.manufacturer,
      'brand': info.brand,
      'model': info.model,
      'deviceName': info.name,
      'systemName': 'Android',
      'systemVersion': info.version.release,
      'sdkInt': info.version.sdkInt,
      'isPhysicalDevice': info.isPhysicalDevice,
      'physicalRamMb': info.physicalRamSize,
      'availableRamMb': info.availableRamSize,
      'totalDiskBytes': info.totalDiskSize,
      'freeDiskBytes': info.freeDiskSize,
      'app': app,
    };
  }

  Future<Map<String, Object?>> _iosInfo(Map<String, Object?> app) async {
    final info = await _deviceInfo.iosInfo;
    return {
      'platform': 'ios',
      'model': info.modelName,
      'deviceName': info.name,
      'systemName': info.systemName,
      'systemVersion': info.systemVersion,
      'machine': info.utsname.machine,
      'isPhysicalDevice': info.isPhysicalDevice,
      'physicalRamMb': info.physicalRamSize,
      'availableRamMb': info.availableRamSize,
      'totalDiskBytes': info.totalDiskSize,
      'freeDiskBytes': info.freeDiskSize,
      'app': app,
    };
  }
}
