import '../config/app_config.dart';

class MapSdkService {
  const MapSdkService({required AppConfig config}) : _config = config;

  final AppConfig _config;

  Future<void> initialize() async {
    // 当前阶段不接入具体地图 SDK，避免 Android/Web 调试被原生插件阻塞。
    // 后续确定地图厂商后，在这里集中初始化 SDK、隐私合规声明和坐标系。
    _config.mapProvider;
  }
}
