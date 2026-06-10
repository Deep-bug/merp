import 'package:flutter/foundation.dart';

import '../../features/home/data/permission_repository.dart';
import 'auth_repository.dart';

enum AuthStatus { booting, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required PermissionRepository permissionRepository,
  }) : _authRepository = authRepository,
       _permissionRepository = permissionRepository;

  final AuthRepository _authRepository;
  final PermissionRepository _permissionRepository;

  AuthStatus status = AuthStatus.booting;
  AuthSession? session;
  String? lastError;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  Future<void> restoreSession() async {
    session = await _authRepository.restore();
    if (session == null) {
      status = AuthStatus.unauthenticated;
    } else {
      status = AuthStatus.authenticated;
      await _permissionRepository.loadForSession(session!);
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
      notifyListeners();
      return true;
    } catch (error) {
      lastError = error.toString();
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _permissionRepository.clear();
    session = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
