// -----------------------------------------------------------------------------
// 文件：app_update_controller.dart
// 作用：管理启动版本检测、强制升级、Android 下载进度和平台安装流程
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/logging/app_logger.dart';
import 'app_update_info.dart';
import 'app_update_platform.dart';
import 'app_update_repository.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  optionalUpdate,
  forceUpdate,
  downloading,
  permissionRequired,
  installerOpened,
  simulatedDownloadComplete,
  failed,
}

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required AppUpdateRepositoryContract repository,
    required AppUpdatePlatform platformService,
    required AppLogger logger,
    required String Function() localeProvider,
    this.isSimulationMode = false,
    TargetPlatform? platform,
    Future<PackageInfo> Function()? packageInfoProvider,
    Directory Function()? temporaryDirectoryProvider,
  }) : _repository = repository,
       _platformService = platformService,
       _logger = logger,
       _localeProvider = localeProvider,
       _platform = platform ?? defaultTargetPlatform,
       _packageInfoProvider = packageInfoProvider ?? PackageInfo.fromPlatform,
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? (() => Directory.systemTemp);

  final AppUpdateRepositoryContract _repository;
  final AppUpdatePlatform _platformService;
  final AppLogger _logger;
  final String Function() _localeProvider;
  final bool isSimulationMode;
  final TargetPlatform _platform;
  final Future<PackageInfo> Function() _packageInfoProvider;
  final Directory Function() _temporaryDirectoryProvider;

  AppUpdateStatus status = AppUpdateStatus.idle;
  AppUpdateInfo? updateInfo;
  String currentVersionName = '';
  int currentVersionCode = 0;
  int receivedBytes = 0;
  int totalBytes = 0;
  String? errorMessage;
  bool _startupCheckInProgress = false;
  bool _forceUpdateActive = false;
  bool _downloadStarted = false;
  String? _downloadedApkPath;
  int _lastProgressPercent = -1;
  int _lastReportedBytes = 0;

  bool get isChecking => status == AppUpdateStatus.checking;
  bool get isDownloading => status == AppUpdateStatus.downloading;
  bool get isForceUpdateActive => _forceUpdateActive;
  bool get blocksApplication => _startupCheckInProgress || _forceUpdateActive;
  bool get isAndroid => _platform == TargetPlatform.android;
  bool get isIos => _platform == TargetPlatform.iOS;
  double? get downloadProgress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;

  Future<void> checkAtStartup() async {
    _startupCheckInProgress = true;
    status = AppUpdateStatus.checking;
    notifyListeners();
    try {
      await _checkVersion(autoStartForceUpdate: true);
    } catch (error, stackTrace) {
      _handleCheckFailure(error, stackTrace);
    } finally {
      _startupCheckInProgress = false;
      notifyListeners();
    }
  }

  Future<void> checkManually() async {
    if (isChecking || isDownloading) {
      return;
    }
    status = AppUpdateStatus.checking;
    errorMessage = null;
    notifyListeners();
    try {
      await _checkVersion(autoStartForceUpdate: true);
    } catch (error, stackTrace) {
      _handleCheckFailure(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _checkVersion({required bool autoStartForceUpdate}) async {
    if (!isAndroid && !isIos) {
      throw UnsupportedError('版本检测仅支持 Android 和 iOS');
    }
    final package = await _packageInfoProvider();
    final parsedVersionCode = int.tryParse(package.buildNumber.trim());
    if (parsedVersionCode == null || parsedVersionCode <= 0) {
      throw const FormatException('当前应用构建号不是有效正整数');
    }
    currentVersionName = package.version.trim();
    currentVersionCode = parsedVersionCode;

    final info = await _repository.checkVersion(
      platform: isAndroid ? 'android' : 'ios',
      versionCode: currentVersionCode,
      locale: _localeProvider(),
    );
    updateInfo = info;
    _validateDownloadUrl(info.downloadUrl);

    // App 根据三个数字构建号独立计算升级策略，避免后端 updateType
    // 误配时出现应强制却被放行，或可选升级却被强制的情况。
    final effectiveUpdateType = currentVersionCode < info.minimumVersionCode
        ? AppUpdateType.force
        : currentVersionCode < info.latestVersionCode
        ? AppUpdateType.optional
        : AppUpdateType.none;
    if (info.updateType != effectiveUpdateType) {
      _logger.warning(
        'app.update',
        '版本接口 updateType 与版本号计算结果不一致，已使用客户端计算结果',
        fields: {
          'currentVersionCode': currentVersionCode,
          'minimumVersionCode': info.minimumVersionCode,
          'latestVersionCode': info.latestVersionCode,
          'serverUpdateType': info.updateType.name,
          'effectiveUpdateType': effectiveUpdateType.name,
        },
      );
    }

    if (effectiveUpdateType == AppUpdateType.none) {
      _forceUpdateActive = false;
      status = AppUpdateStatus.upToDate;
      notifyListeners();
      return;
    }

    final isForceUpdate = effectiveUpdateType == AppUpdateType.force;
    _forceUpdateActive = isForceUpdate;
    status = isForceUpdate
        ? AppUpdateStatus.forceUpdate
        : AppUpdateStatus.optionalUpdate;
    notifyListeners();

    if (isForceUpdate &&
        autoStartForceUpdate &&
        (isAndroid || isSimulationMode)) {
      unawaited(startUpdate());
    }
  }

  void _validateDownloadUrl(Uri url) {
    final allowed = isAndroid
        ? const {'http', 'https'}
        : const {'itms-services', 'https'};
    if (!allowed.contains(url.scheme.toLowerCase())) {
      throw FormatException('当前平台不支持升级链接协议：${url.scheme}');
    }
  }

  Future<void> startUpdate() async {
    final info = updateInfo;
    if (info == null) {
      return;
    }
    if (isSimulationMode) {
      await _simulateDownload(info);
      return;
    }
    if (isIos) {
      try {
        await _platformService.openIosEnterpriseInstall(info.downloadUrl);
        status = AppUpdateStatus.installerOpened;
        errorMessage = null;
        notifyListeners();
      } catch (error, stackTrace) {
        _handleInstallFailure(error, stackTrace);
      }
      return;
    }
    if (_downloadedApkPath != null) {
      await _openAndroidInstaller(_downloadedApkPath!);
      return;
    }
    if (_downloadStarted) {
      return;
    }
    await _downloadAndroidPackage(info);
  }

  Future<void> _simulateDownload(AppUpdateInfo info) async {
    if (_downloadStarted) {
      return;
    }
    _downloadStarted = true;
    status = AppUpdateStatus.downloading;
    errorMessage = null;
    receivedBytes = 0;
    totalBytes = 0;
    _lastProgressPercent = -1;
    _lastReportedBytes = 0;
    notifyListeners();
    try {
      await _repository.downloadPackage(
        url: info.downloadUrl,
        // Mock 仓库不会使用路径，也不会在设备上创建伪 APK。
        savePath: '',
        onProgress: _updateDownloadProgress,
      );
      _downloadStarted = false;
      status = AppUpdateStatus.simulatedDownloadComplete;
      errorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      _downloadStarted = false;
      _handleInstallFailure(error, stackTrace);
    }
  }

  Future<void> _downloadAndroidPackage(AppUpdateInfo info) async {
    _downloadStarted = true;
    status = AppUpdateStatus.downloading;
    errorMessage = null;
    receivedBytes = 0;
    totalBytes = 0;
    _lastProgressPercent = -1;
    _lastReportedBytes = 0;
    notifyListeners();

    final updateDirectory = Directory(
      '${_temporaryDirectoryProvider().path}/merp_updates',
    );
    final apkPath =
        '${updateDirectory.path}/merp-${info.latestVersionCode}.apk';
    try {
      await updateDirectory.create(recursive: true);
      final apkFile = File(apkPath);
      if (await apkFile.exists()) {
        await apkFile.delete();
      }
      await _repository.downloadPackage(
        url: info.downloadUrl,
        savePath: apkPath,
        onProgress: _updateDownloadProgress,
      );
      if (!await apkFile.exists() || await apkFile.length() == 0) {
        throw StateError('升级包下载完成但文件为空');
      }
      _downloadedApkPath = apkPath;
      _downloadStarted = false;
      await _openAndroidInstaller(apkPath);
    } catch (error, stackTrace) {
      _downloadStarted = false;
      _handleInstallFailure(error, stackTrace);
    }
  }

  void _updateDownloadProgress(int received, int total) {
    receivedBytes = received;
    totalBytes = total;
    final percent = total > 0 ? ((received / total) * 100).floor() : -1;
    // 百分比不变时不重建整页；未知总大小则按 512 KB 粒度刷新已下载量。
    final bytesSinceLastReport = received - _lastReportedBytes;
    if (percent == _lastProgressPercent &&
        (total > 0 || bytesSinceLastReport < 512 * 1024)) {
      return;
    }
    _lastProgressPercent = percent;
    _lastReportedBytes = received;
    notifyListeners();
  }

  Future<void> _openAndroidInstaller(String apkPath) async {
    try {
      final result = await _platformService.installAndroidPackage(apkPath);
      status = result == AndroidInstallResult.permissionOpened
          ? AppUpdateStatus.permissionRequired
          : AppUpdateStatus.installerOpened;
      errorMessage = null;
      notifyListeners();
    } catch (error, stackTrace) {
      _handleInstallFailure(error, stackTrace);
    }
  }

  Future<void> retry() async {
    if (_downloadedApkPath != null) {
      await _openAndroidInstaller(_downloadedApkPath!);
      return;
    }
    await startUpdate();
  }

  void _handleCheckFailure(Object error, StackTrace stackTrace) {
    status = AppUpdateStatus.failed;
    errorMessage = error.toString();
    // 检测本身失败时放行，避免网络故障导致所有用户无法启动。
    _forceUpdateActive = false;
    _logger.error('app.update', '版本检测失败', error: error, stackTrace: stackTrace);
    notifyListeners();
  }

  void _handleInstallFailure(Object error, StackTrace stackTrace) {
    status = AppUpdateStatus.failed;
    errorMessage = error.toString();
    _logger.error(
      'app.update',
      '应用升级失败',
      error: error,
      stackTrace: stackTrace,
      fields: {
        'minimumVersionCode': updateInfo?.minimumVersionCode,
        'latestVersionCode': updateInfo?.latestVersionCode,
        'downloadUrl': updateInfo?.downloadUrl.toString(),
      },
    );
    notifyListeners();
  }
}
