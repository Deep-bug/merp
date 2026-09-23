import 'package:flutter/foundation.dart';

import 'auth_models.dart';

/// 锁屏流程所需的最小会话视图，避免安全协调器依赖完整认证实现。
abstract interface class SecuritySessionState implements Listenable {
  bool get isAuthenticated;
  bool get gestureEnrollmentRequired;
  int get sessionGeneration;
  AuthSession? get session;
}
