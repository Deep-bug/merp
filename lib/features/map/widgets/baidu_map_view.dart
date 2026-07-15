// -----------------------------------------------------------------------------
// 文件：baidu_map_view.dart
// 作用：封装百度基础地图原生视图，隔离第三方 Flutter 插件类型
// 编写时间：2026-07-15
// 维护说明：搜索和定位能力不得堆入此组件，应分别通过应用设备服务接入
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart';

import '../../../core/device/location_models.dart';

/// 对业务层暴露的最小地图控制器，避免页面直接依赖百度插件类型。
class BaiduMapViewController {
  BaiduMapViewController(this._controller);

  final BMFMapController _controller;

  Future<void> showLocation(AppLocation location) async {
    final coordinate = BMFCoordinate(location.latitude, location.longitude);
    final userLocation = BMFUserLocation(
      location: BMFLocation(
        coordinate: coordinate,
        altitude: location.altitude ?? 0,
        horizontalAccuracy: location.accuracyMeters,
        verticalAccuracy: -1,
        speed: -1,
        course: -1,
      ),
    );

    await _controller.showUserLocation(true);
    await _controller.updateLocationData(userLocation);
    await _controller.setCenterCoordinate(
      coordinate,
      true,
      animateDurationMs: 500,
    );
    await _controller.setZoomTo(18, animateDurationMs: 500);
  }
}

/// 百度基础地图视图。
///
/// 默认中心点为北京城区；业务层完成按需授权和精确定位后，通过受控控制器更新
/// 用户位置，基础地图组件本身永远不申请系统权限。
class BaiduMapView extends StatelessWidget {
  const BaiduMapView({
    super.key,
    required this.onMapCreated,
    required this.onMapLoaded,
  });

  final ValueChanged<BaiduMapViewController> onMapCreated;
  final VoidCallback onMapLoaded;

  @override
  Widget build(BuildContext context) {
    return BMFMapWidget(
      mapOptions: BMFMapOptions(
        mapType: BMFMapType.Standard,
        center: BMFCoordinate(39.915, 116.404),
        zoomLevel: 12,
        minZoomLevel: 4,
        maxZoomLevel: 21,
        compassEnabled: true,
        showMapScaleBar: true,
        gesturesEnabled: true,
        mapPadding: BMFEdgeInsets(top: 16, left: 16, right: 16, bottom: 16),
      ),
      onBMFMapCreated: (controller) {
        onMapCreated(BaiduMapViewController(controller));
        controller.setMapDidLoadCallback(callback: onMapLoaded);
      },
    );
  }
}
