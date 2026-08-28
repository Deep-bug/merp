import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/config/app_config.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/network/api_client.dart';
import 'package:merp/features/app_update/app_update_controller.dart';
import 'package:merp/features/app_update/app_update_info.dart';
import 'package:merp/features/app_update/app_update_platform.dart';
import 'package:merp/features/app_update/app_update_repository.dart';
import 'package:merp/features/app_update/mock_app_update_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/memory_token_store.dart';

Future<PackageInfo> _packageInfo({String buildNumber = '9999'}) async {
  return PackageInfo(
    appName: 'MERP',
    packageName: 'com.delta.merp',
    version: '0.9.9',
    buildNumber: buildNumber,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repository follows the final backend parameter contract', () async {
    RequestOptions? captured;
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter((options) {
        captured = options;
        return jsonResponse({
          'code': 0,
          'data': {
            'updateType': 'force',
            'latestVersionName': '1.0.0',
            'latestVersionCode': 10000,
            'releaseNotes': 'xxxxx',
            'downloadUrl': 'https://example.com/merp.apk',
          },
        });
      });
    final apiClient = ApiClient(
      config: const AppConfig(),
      tokenStore: MemoryTokenStore(),
      logger: AppLogger(),
      dio: dio,
    );
    final repository = AppUpdateRepository(
      apiClient: apiClient,
      config: const AppConfig(),
      logger: AppLogger(),
    );

    final info = await repository.checkVersion(
      platform: 'ios',
      versionCode: 9999,
      locale: 'zh_TW',
    );

    expect(captured?.path, '/api/v1/app/version/check');
    expect(captured?.data, {
      'platform': 'ios',
      'versionCode': 9999,
      'locale': 'zh_TW',
    });
    expect(captured?.headers['Authorization'], isNull);
    expect(info.updateType, AppUpdateType.force);
    expect(info.latestVersionCode, 10000);
  });

  test('iOS force response blocks the app and opens enterprise URL', () async {
    final platform = _FakeUpdatePlatform();
    final controller = AppUpdateController(
      repository: _FakeUpdateRepository(
        info: _forceInfo(
          Uri.parse(
            'itms-services://?action=download-manifest&url=https%3A%2F%2Fexample.com%2Fmanifest.plist',
          ),
        ),
      ),
      platformService: platform,
      logger: AppLogger(),
      localeProvider: () => 'zh_CN',
      platform: TargetPlatform.iOS,
      packageInfoProvider: _packageInfo,
    );

    await controller.checkManually();

    expect(controller.status, AppUpdateStatus.forceUpdate);
    expect(controller.blocksApplication, isTrue);
    await controller.startUpdate();
    expect(platform.openedIosUrl?.scheme, 'itms-services');
    expect(controller.status, AppUpdateStatus.installerOpened);
  });

  test('Android force response downloads and opens system installer', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'merp-update-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final platform = _FakeUpdatePlatform();
    final repository = _FakeUpdateRepository(
      info: _forceInfo(Uri.parse('https://example.com/merp.apk')),
    );
    final controller = AppUpdateController(
      repository: repository,
      platformService: platform,
      logger: AppLogger(),
      localeProvider: () => 'zh_CN',
      platform: TargetPlatform.android,
      packageInfoProvider: _packageInfo,
      temporaryDirectoryProvider: () => temporaryDirectory,
    );

    await controller.checkManually();
    await platform.installerOpened.future;
    await Future<void>.delayed(Duration.zero);

    expect(repository.downloadCount, 1);
    expect(controller.downloadProgress, 1);
    expect(controller.status, AppUpdateStatus.installerOpened);
    expect(platform.androidApkPath, contains('merp-10000.apk'));
  });

  test(
    'mock update simulates progress without file or native installer',
    () async {
      final platform = _FakeUpdatePlatform();
      final controller = AppUpdateController(
        repository: MockAppUpdateRepository(
          logger: AppLogger(),
          progressStepDelay: Duration.zero,
        ),
        platformService: platform,
        logger: AppLogger(),
        localeProvider: () => 'zh_CN',
        platform: TargetPlatform.iOS,
        packageInfoProvider: _packageInfo,
        isSimulationMode: true,
      );
      final completed = Completer<void>();
      controller.addListener(() {
        if (controller.status == AppUpdateStatus.simulatedDownloadComplete &&
            !completed.isCompleted) {
          completed.complete();
        }
      });

      await controller.checkManually();
      await completed.future.timeout(const Duration(seconds: 1));

      expect(controller.updateInfo?.updateType, AppUpdateType.force);
      expect(controller.downloadProgress, 1);
      expect(controller.receivedBytes, 32 * 1024 * 1024);
      expect(platform.openedIosUrl, isNull);
      expect(platform.androidApkPath, isNull);
    },
  );
}

AppUpdateInfo _forceInfo(Uri downloadUrl) {
  return AppUpdateInfo(
    updateType: AppUpdateType.force,
    latestVersionName: '1.0.0',
    latestVersionCode: 10000,
    releaseNotes: 'xxxxx',
    downloadUrl: downloadUrl,
  );
}

class _FakeUpdateRepository implements AppUpdateRepositoryContract {
  _FakeUpdateRepository({required this.info});

  final AppUpdateInfo info;
  int downloadCount = 0;

  @override
  Future<AppUpdateInfo> checkVersion({
    required String platform,
    required int versionCode,
    required String locale,
  }) async {
    return info;
  }

  @override
  Future<void> downloadPackage({
    required Uri url,
    required String savePath,
    required void Function(int received, int total) onProgress,
  }) async {
    downloadCount += 1;
    await File(savePath).writeAsBytes(List<int>.filled(8, 1));
    onProgress(4, 8);
    onProgress(8, 8);
  }
}

class _FakeUpdatePlatform implements AppUpdatePlatform {
  final Completer<void> installerOpened = Completer<void>();
  String? androidApkPath;
  Uri? openedIosUrl;

  @override
  Future<AndroidInstallResult> installAndroidPackage(String filePath) async {
    androidApkPath = filePath;
    if (!installerOpened.isCompleted) {
      installerOpened.complete();
    }
    return AndroidInstallResult.installerOpened;
  }

  @override
  Future<void> openIosEnterpriseInstall(Uri url) async {
    openedIosUrl = url;
  }
}
