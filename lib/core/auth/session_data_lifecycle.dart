import 'auth_models.dart';

/// 登录域只协调会话数据的生命周期，不依赖首页的具体权限仓库。
/// 将来增加其他会话数据时，可在应用装配层组合多个实现。
abstract interface class SessionDataLifecycle {
  Future<void> loadForSession(AuthSession session);
  Future<void> loadDevelopmentMockMenu();
  Future<void> clear();
}
