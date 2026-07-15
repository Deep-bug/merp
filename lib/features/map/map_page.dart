// -----------------------------------------------------------------------------
// 文件：map_page.dart
// 作用：承载百度 iOS 基础地图、隐私确认、配置校验与加载失败恢复流程
// 编写时间：2026-07-15
// 维护说明：当前仅显示地图；检索与真实定位应通过独立服务按需接入
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../core/device/map_sdk_service.dart';
import '../../core/device/location_service.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_error_view.dart';
import 'widgets/baidu_map_view.dart';

enum _MapPageStatus {
  loading,
  needsConsent,
  ready,
  unsupported,
  missingConfig,
  failed,
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _mapLoadTimeout = Duration(seconds: 15);
  static const _privacyPolicyUrl =
      'https://lbsyun.baidu.com/index.php?title=openprivacy';

  _MapPageStatus _status = _MapPageStatus.loading;
  MapSdkService? _mapSdkService;
  Timer? _loadTimer;
  bool _didResolveDependencies = false;
  bool _mapLoaded = false;
  bool _locating = false;
  AppLocation? _currentLocation;
  BaiduMapViewController? _mapController;
  String? _incidentId;
  Key _mapViewKey = UniqueKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didResolveDependencies) {
      return;
    }
    _didResolveDependencies = true;
    _mapSdkService = AppScope.of(context).mapSdkService;
    unawaited(_prepareMap());
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepareMap() async {
    final service = _mapSdkService!;
    if (!service.isIosSupported) {
      _setStatus(_MapPageStatus.unsupported);
      return;
    }
    if (!service.isConfigured) {
      _setStatus(_MapPageStatus.missingConfig);
      return;
    }

    try {
      if (await service.hasPrivacyConsent()) {
        await service.activateIfConsented();
        _setStatus(_MapPageStatus.ready);
      } else {
        _setStatus(_MapPageStatus.needsConsent);
      }
    } catch (error, stackTrace) {
      _recordFailure('百度地图初始化失败', error, stackTrace);
    }
  }

  Future<void> _agreeAndOpenMap() async {
    _setStatus(_MapPageStatus.loading);
    try {
      await _mapSdkService!.acceptPrivacyAndActivate();
      _setStatus(_MapPageStatus.ready);
    } catch (error, stackTrace) {
      _recordFailure('百度地图授权初始化失败', error, stackTrace);
    }
  }

  void _onMapCreated(BaiduMapViewController controller) {
    _mapController = controller;
    final logger = AppScope.of(context).logger;
    logger.info('map', '百度地图原生视图已创建');
    _loadTimer?.cancel();
    _loadTimer = Timer(_mapLoadTimeout, () {
      if (!mounted || _mapLoaded) {
        return;
      }
      final incidentId = logger.error(
        'map',
        '百度地图底图加载超时',
        fields: {'timeoutSeconds': _mapLoadTimeout.inSeconds},
      );
      setState(() {
        _incidentId = incidentId;
        _status = _MapPageStatus.failed;
      });
    });
  }

  Future<void> _locateUser() async {
    if (_locating || !_mapLoaded || _mapController == null) {
      return;
    }
    setState(() => _locating = true);
    final locationService = AppScope.of(context).locationService;
    try {
      // 地图按钮要求 50 米以内的结果；达不到时明确提示，避免把粗略位置
      // 当成签到、外勤等企业业务中的精确位置使用。
      final location = await locationService.locateOnce(
        maximumAccuracyMeters: 50,
      );
      await _mapController!.showLocation(location);
      if (!mounted) {
        return;
      }
      setState(() => _currentLocation = location);
    } on AppLocationException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: error.canOpenSettings
              ? SnackBarAction(
                  label: context.l10n.openSystemSettings,
                  onPressed: locationService.openAppSettings,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _onMapLoaded() {
    if (!mounted) {
      return;
    }
    _loadTimer?.cancel();
    AppScope.of(context).logger.info('map', '百度地图底图加载完成');
    setState(() => _mapLoaded = true);
  }

  void _retryMap() {
    _loadTimer?.cancel();
    setState(() {
      _incidentId = null;
      _mapLoaded = false;
      _mapViewKey = UniqueKey();
      _status = _MapPageStatus.ready;
    });
  }

  void _recordFailure(String message, Object error, StackTrace stackTrace) {
    if (!mounted) {
      return;
    }
    final incidentId = AppScope.of(
      context,
    ).logger.error('map', message, error: error, stackTrace: stackTrace);
    setState(() {
      _incidentId = incidentId;
      _status = _MapPageStatus.failed;
    });
  }

  void _setStatus(_MapPageStatus status) {
    if (!mounted) {
      return;
    }
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.mapLocation)),
      floatingActionButton: _status == _MapPageStatus.ready
          ? FloatingActionButton(
              onPressed: _mapLoaded && !_locating ? _locateUser : null,
              tooltip: context.l10n.locateMe,
              child: _locating
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.my_location_outlined),
            )
          : null,
      body: switch (_status) {
        _MapPageStatus.loading => _buildLoading(context),
        _MapPageStatus.needsConsent => _buildPrivacyConsent(context),
        _MapPageStatus.ready => _buildMap(context),
        _MapPageStatus.unsupported => _buildUnsupported(context),
        _MapPageStatus.missingConfig => _buildMissingConfig(context),
        _MapPageStatus.failed => _buildFailure(context),
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Semantics(
        label: context.l10n.mapLoading,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildPrivacyConsent(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.mapPrivacyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.mapPrivacyMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.mapPrivacyPolicy,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                const SelectableText(
                  _privacyPolicyUrl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoute.home),
                        child: Text(context.l10n.mapDecline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _agreeAndOpenMap,
                        child: Text(context.l10n.mapAgreeAndContinue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BaiduMapView(
          key: _mapViewKey,
          onMapCreated: _onMapCreated,
          onMapLoaded: _onMapLoaded,
        ),
        if (!_mapLoaded)
          ColoredBox(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.86),
            child: _buildLoading(context),
          ),
        if (_mapLoaded && _currentLocation != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 84),
              child: Material(
                elevation: 3,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.l10n.locationResult(
                            _currentLocation!.accuracyMeters.toStringAsFixed(1),
                            _currentLocation!.address ??
                                context.l10n.addressUnavailable,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnsupported(BuildContext context) {
    return AppErrorView(
      icon: Icons.phone_iphone_outlined,
      title: context.l10n.mapLocation,
      message: context.l10n.mapIosOnly,
      tone: AppErrorTone.info,
      primaryLabel: context.l10n.returnWorkbench,
      onPrimary: () => context.go(AppRoute.home),
    );
  }

  Widget _buildMissingConfig(BuildContext context) {
    return AppErrorView(
      icon: Icons.key_off_outlined,
      title: context.l10n.mapConfigMissing,
      message: context.l10n.mapKeyMissing,
      detail:
          'config/baidu_map.local.json\nBAIDU_MAP_IOS_AK\n'
          '--dart-define-from-file=config/baidu_map.local.json',
      tone: AppErrorTone.warning,
      primaryLabel: context.l10n.returnWorkbench,
      onPrimary: () => context.go(AppRoute.home),
    );
  }

  Widget _buildFailure(BuildContext context) {
    return AppErrorView(
      icon: Icons.map_outlined,
      title: context.l10n.mapLoadFailed,
      message: context.l10n.mapLoadTimeout,
      referenceId: _incidentId,
      primaryLabel: context.l10n.retry,
      onPrimary: _retryMap,
      secondaryLabel: context.l10n.returnWorkbench,
      onSecondary: () => context.go(AppRoute.home),
    );
  }
}
