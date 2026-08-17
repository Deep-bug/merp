// -----------------------------------------------------------------------------
// 文件：login_page.dart
// 作用：采集账号凭证并触发统一认证流程
// 编写时间：2026-07-10
// 维护说明：页面不接触 Token 和 Dio，仅调用 AuthController
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../core/auth/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_dialog.dart';
import '../../shared/app_notice.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authController});

  /// 测试可显式注入；生产路由默认从 AppScope 获取。
  final AuthController? authController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _accountController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _captchaController = TextEditingController(text: '');
  final _accountFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _captchaFocusNode = FocusNode();
  AuthController? _authController;
  bool _captchaRequested = false;
  bool _privacyAccepted = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authController =
        widget.authController ?? AppScope.of(context).authController;
    if (_captchaRequested) {
      return;
    }
    _captchaRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final auth = _authController!;
      if (auth.captchaChallenge == null && !auth.isCaptchaLoading) {
        auth.refreshCaptcha();
      }
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _accountFocusNode.dispose();
    _passwordFocusNode.dispose();
    _captchaFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLoginTap() async {
    if (_submitting) {
      return;
    }
    final auth = _authController!;
    if (_accountController.text.trim().isEmpty) {
      await _showLoginHint(
        title: context.l10n.loginAccountRequiredTitle,
        message: context.l10n.loginAccountRequiredMessage,
        focusNode: _accountFocusNode,
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      await _showLoginHint(
        title: context.l10n.loginPasswordRequiredTitle,
        message: context.l10n.loginPasswordRequiredMessage,
        focusNode: _passwordFocusNode,
      );
      return;
    }
    if (_captchaController.text.trim().isEmpty) {
      await _showLoginHint(
        title: context.l10n.loginCaptchaRequiredTitle,
        message: context.l10n.loginCaptchaRequiredMessage,
        focusNode: _captchaFocusNode,
      );
      return;
    }
    if (!_privacyAccepted) {
      await _showLoginHint(
        title: context.l10n.legalConsentRequiredTitle,
        message: context.l10n.legalConsentRequiredMessage,
        icon: Icons.gavel_outlined,
      );
      return;
    }
    if (auth.isCaptchaLoading || auth.captchaChallenge == null) {
      if (!auth.isCaptchaLoading) {
        auth.refreshCaptcha();
      }
      await _showLoginHint(
        title: context.l10n.captchaPreparingTitle,
        message: context.l10n.captchaPreparingMessage,
        icon: Icons.refresh_rounded,
      );
      return;
    }
    await _submit();
  }

  Future<void> _showLoginHint({
    required String title,
    required String message,
    FocusNode? focusNode,
    IconData icon = Icons.info_outline_rounded,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDialog(
        tone: AppDialogTone.warning,
        icon: icon,
        title: title,
        message: message,
        primaryLabel: context.l10n.acknowledge,
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );
    if (mounted && focusNode != null) {
      focusNode.requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    final auth = _authController!;
    final ok = await auth.login(
      account: _accountController.text,
      password: _passwordController.text,
      captchaCode: _captchaController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (ok) {
      final session = auth.session!;
      final settings = AppScope.of(context).settingsController;
      await settings.activateGestureScope(
        userId: session.profile.id,
        accountName: session.profile.accountName,
      );
      if (!mounted) {
        return;
      }
      final requiresEnrollment = !settings.gesturePasswordConfigured;
      auth.completeInteractiveLogin(
        requiresGestureEnrollment: requiresEnrollment,
      );
      context.go(
        requiresEnrollment ? AppRoute.gestureEnrollment : AppRoute.home,
      );
      return;
    }
    _captchaController.clear();
    AppNotice.show(
      context,
      message: auth.lastError ?? context.l10n.loginFailed,
      tone: AppNoticeTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = _authController!;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minimumHeight = constraints.maxHeight > 48
                    ? constraints.maxHeight - 48
                    : 0.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minimumHeight),
                    child: Align(
                      alignment: const Alignment(0, -0.18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'MERP',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.workbench,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _accountController,
                                focusNode: _accountFocusNode,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                decoration: InputDecoration(
                                  labelText: context.l10n.account,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.next,
                                obscureText: true,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                decoration: InputDecoration(
                                  labelText: context.l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _captchaController,
                                      focusNode: _captchaFocusNode,
                                      textInputAction: TextInputAction.done,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      onSubmitted: (_) => _handleLoginTap(),
                                      decoration: InputDecoration(
                                        labelText: context.l10n.captcha,
                                        prefixIcon: const Icon(
                                          Icons.verified_user_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Tooltip(
                                    message: context.l10n.refreshCaptcha,
                                    child: Material(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLowest,
                                      clipBehavior: Clip.antiAlias,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap:
                                            _submitting || auth.isCaptchaLoading
                                            ? null
                                            : auth.refreshCaptcha,
                                        child: SizedBox(
                                          width: 120,
                                          height: 56,
                                          child: _buildCaptcha(context, auth),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _PrivacyConsent(
                                accepted: _privacyAccepted,
                                onChanged: (value) {
                                  setState(() => _privacyAccepted = value);
                                },
                                onOpenCopyright: () =>
                                    context.push(AppRoute.copyrightDisclaimer),
                                onOpenPersonalData: () => context.push(
                                  AppRoute.personalDataStatement,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed: _submitting
                                      ? null
                                      : _handleLoginTap,
                                  icon: _submitting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.login),
                                  label: Text(context.l10n.login),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaptcha(BuildContext context, AuthController auth) {
    if (auth.isCaptchaLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final challenge = auth.captchaChallenge;
    if (challenge != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            challenge.imageBytes,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
          const Positioned(
            top: 2,
            right: 2,
            child: Icon(Icons.refresh, size: 17),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          auth.captchaError == null
              ? context.l10n.refreshCaptcha
              : context.l10n.captchaLoadFailed,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _PrivacyConsent extends StatelessWidget {
  const _PrivacyConsent({
    required this.accepted,
    required this.onChanged,
    required this.onOpenCopyright,
    required this.onOpenPersonalData,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenCopyright;
  final VoidCallback onOpenPersonalData;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: accepted,
          onChanged: (value) => onChanged(value ?? false),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: () => onChanged(!accepted),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      context.l10n.legalConsentPrefix,
                      style: textStyle,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onOpenCopyright,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '《${context.l10n.copyrightDisclaimer}》',
                      style: textStyle?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onOpenPersonalData,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '《${context.l10n.personalDataStatement}》',
                      style: textStyle?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
