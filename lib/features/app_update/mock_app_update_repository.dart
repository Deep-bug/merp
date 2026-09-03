// -----------------------------------------------------------------------------
// 文件：mock_app_update_repository.dart
// 作用：在独立 Mock Debug 环境模拟强制升级接口和下载进度
// -----------------------------------------------------------------------------

import 'dart:async';

import '../../core/logging/app_logger.dart';
import 'app_update_info.dart';
import 'app_update_repository.dart';

class MockAppUpdateRepository implements AppUpdateRepositoryContract {
  MockAppUpdateRepository({
    required AppLogger logger,
    this.progressStepDelay = const Duration(milliseconds: 80),
  }) : _logger = logger;

  final AppLogger _logger;
  final Duration progressStepDelay;

  static const _mockPackageBytes = 32 * 1024 * 1024;
  static const _progressSteps = 40;

  @override
  Future<AppUpdateInfo> checkVersion({
    required String platform,
    required int versionCode,
    required String locale,
  }) async {
    // 保证模拟版本始终高于当前构建号，避免开发者提高本地 build number 后失效。
    final latestVersionCode = versionCode < 10000 ? 10000 : versionCode + 1;
    final info = AppUpdateInfo(
      updateType: AppUpdateType.force,
      latestVersionName: '1.0.0 Mock',
      latestVersionCode: latestVersionCode,
      minimumVersionCode: latestVersionCode,
      releaseNotes: '模拟强制升级：验证版本提示、更新说明和下载进度展示。',
      downloadUrl: Uri.parse('https://mock.invalid/merp-mock.apk'),
    );
    _logger.info(
      'app.update.mock',
      '返回模拟版本接口数据',
      fields: {
        'platform': platform,
        'locale': locale,
        'currentVersionCode': versionCode,
        'minimumVersionCode': info.minimumVersionCode,
        'latestVersionCode': latestVersionCode,
        'updateType': info.updateType.name,
      },
    );
    return info;
  }

  @override
  Future<void> downloadPackage({
    required Uri url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) async {
    for (var step = 1; step <= _progressSteps; step += 1) {
      await Future<void>.delayed(progressStepDelay);
      onProgress(
        (_mockPackageBytes * step / _progressSteps).round(),
        _mockPackageBytes,
      );
    }
    _logger.info(
      'app.update.mock',
      '模拟下载进度完成，未创建文件或调用安装器',
      fields: {'downloadUrl': url.toString()},
    );
  }
}
