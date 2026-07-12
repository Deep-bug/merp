// -----------------------------------------------------------------------------
// 文件：auth_controller.dart
// 作用：维护登录状态、会话恢复、权限加载和退出流程
// 编写时间：2026-07-10
// 维护说明：路由只监听 AuthStatus，页面不得自行判断或保存 Token
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../features/home/data/permission_repository.dart';
import '../logging/app_logger.dart';
import 'auth_repository.dart';

enum AuthStatus { booting, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required PermissionRepository permissionRepository,
    required AppLogger logger,
  }) : _authRepository = authRepository,
       _permissionRepository = permissionRepository,
       _logger = logger;

  final AuthRepository _authRepository;
  final PermissionRepository _permissionRepository;
  final AppLogger _logger;

  AuthStatus status = AuthStatus.booting;
  AuthSession? session;
  String? lastError;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  Future<void> restoreSession() async {
    try {
      session = await _authRepository.restore();
      if (session == null) {
        status = AuthStatus.unauthenticated;
        _logger.info('auth', '本地无可恢复会话');
      } else {
        status = AuthStatus.authenticated;
        await _permissionRepository.loadForSession(session!);
        _logger.info('auth', '登录会话恢复成功');
      }
    } catch (error, stackTrace) {
      session = null;
      status = AuthStatus.unauthenticated;
      _logger.error('auth', '恢复登录会话失败', error: error, stackTrace: stackTrace);
    }
    notifyListeners();
  }

  Future<bool> login({
    required String account,
    required String password,
  }) async {
    lastError = null;
    notifyListeners();

    try {
      session = await _authRepository.login(
        account: account,
        password: password,
      );
      status = AuthStatus.authenticated;
      await _permissionRepository.loadForSession(session!);
      _logger.info('auth', '用户登录成功', fields: {'account': account.trim()});
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      lastError = error.toString();
      status = AuthStatus.unauthenticated;
      _logger.warning(
        'auth',
        '用户登录失败',
        error: error,
        stackTrace: stackTrace,
        fields: {'account': account.trim()},
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _permissionRepository.clear();
    session = null;
    status = AuthStatus.unauthenticated;
    _logger.info('auth', '用户已退出登录');
    notifyListeners();
  }
}
