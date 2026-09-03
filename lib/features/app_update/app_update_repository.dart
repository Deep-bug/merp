// -----------------------------------------------------------------------------
// 文件：app_update_repository.dart
// 作用：调用版本接口并下载 Android 升级包
// -----------------------------------------------------------------------------

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import 'app_update_info.dart';

abstract interface class AppUpdateRepositoryContract {
  Future<AppUpdateInfo> checkVersion({
    required String platform,
    required int versionCode,
    required String locale,
  });

  Future<void> downloadPackage({
    required Uri url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  });
}

class AppUpdateRepository implements AppUpdateRepositoryContract {
  AppUpdateRepository({
    required ApiClient apiClient,
    required AppConfig config,
    required AppLogger logger,
  }) : _apiClient = apiClient,
       _config = config,
       _logger = logger;

  final ApiClient _apiClient;
  final AppConfig _config;
  final AppLogger _logger;

  @override
  Future<AppUpdateInfo> checkVersion({
    required String platform,
    required int versionCode,
    required String locale,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _config.versionCheckPath,
      data: {
        'platform': platform,
        'versionCode': versionCode,
        'locale': locale,
      },
      // 强制升级发生在登录前，版本接口必须允许匿名访问。
      skipAuth: true,
    );
    final info = AppUpdateInfo.fromJson(response);
    _logger.info(
      'app.update',
      '版本检测完成',
      fields: {
        'platform': platform,
        'currentVersionCode': versionCode,
        'updateType': info.updateType.name,
        'minimumVersionCode': info.minimumVersionCode,
        'latestVersionCode': info.latestVersionCode,
        'latestVersionName': info.latestVersionName,
      },
    );
    return info;
  }

  @override
  Future<void> downloadPackage({
    required Uri url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) {
    return _apiClient.downloadFile(
      url: url,
      savePath: savePath,
      onProgress: onProgress,
    );
  }
}
