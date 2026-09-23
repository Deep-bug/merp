import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:merp/core/logging/app_logger.dart';
import 'package:merp/core/security/biometric_service.dart';
import 'package:merp/core/security/unlock_method.dart';

void main() {
  late _Authentication platform;
  late BiometricService biometrics;
  setUp(() {
    platform = _Authentication();
    biometrics = BiometricService(
      logger: AppLogger(),
      localAuthentication: platform,
    );
  });
  Future<BiometricResult> authenticate() => biometrics.authenticate(
    method: UnlockMethod.face,
    reason: 'Verify your face',
  );

  test('checks enrolled type before opening system prompt', () async {
    final result = await biometrics.authenticate(
      method: UnlockMethod.fingerprint,
      reason: 'Verify your fingerprint',
    );
    expect(result, BiometricResult.unavailable);
    expect(platform.calls, 0);
  });

  test('successful authentication preserves system prompt options', () async {
    final result = authenticate();
    await platform.started.future;
    platform.result.complete(true);
    expect(await result, BiometricResult.verified);
    expect(platform.reason, 'Verify your face');
    expect(platform.onlyBiometrics, isTrue);
    expect(platform.persist, isTrue);
  });

  test('user rejection and platform errors have distinct results', () async {
    final first = authenticate();
    await platform.started.future;
    platform.result.complete(false);
    expect(await first, BiometricResult.rejected);
    platform.throwOnAuthenticate = true;
    expect(await authenticate(), BiometricResult.authenticationFailed);
    platform.throwOnCheck = true;
    expect(await authenticate(), BiometricResult.checkFailed);
  });

  test('cancel during availability check prevents system prompt', () async {
    platform.checkGate = Completer<bool>();
    final result = authenticate();
    await biometrics.cancel();
    platform.checkGate!.complete(true);
    expect(await result, BiometricResult.cancelled);
    expect(platform.calls, 0);
  });

  test('a new prompt waits until native cancellation completes', () async {
    platform.stopGate = Completer<bool>();
    final result = authenticate();
    await platform.started.future;
    final cancelling = biometrics.cancel();
    platform.result.complete(true);
    expect(await authenticate(), BiometricResult.busy);
    platform.stopGate!.complete(true);
    await cancelling;
    expect(await result, BiometricResult.cancelled);
  });

  test(
    'late success after cancel is discarded and concurrent prompt rejected',
    () async {
      final result = authenticate();
      await platform.started.future;
      expect(await authenticate(), BiometricResult.busy);
      await biometrics.cancel();
      platform.result.complete(true);
      expect(await result, BiometricResult.cancelled);
      expect(platform.stops, 1);
    },
  );
}

class _Authentication extends LocalAuthentication {
  final started = Completer<void>();
  final result = Completer<bool>();
  Completer<bool>? checkGate;
  Completer<bool>? stopGate;
  bool throwOnCheck = false;
  bool throwOnAuthenticate = false;
  int calls = 0;
  int stops = 0;
  String? reason;
  bool? onlyBiometrics;
  bool? persist;

  @override
  Future<bool> isDeviceSupported() async {
    if (throwOnCheck) throw StateError('check unavailable');
    return checkGate?.future ?? true;
  }

  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [
    BiometricType.face,
  ];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    calls++;
    if (throwOnAuthenticate) throw StateError('prompt unavailable');
    reason = localizedReason;
    onlyBiometrics = biometricOnly;
    persist = persistAcrossBackgrounding;
    started.complete();
    return result.future;
  }

  @override
  Future<bool> stopAuthentication() async {
    stops++;
    return stopGate?.future ?? true;
  }
}
