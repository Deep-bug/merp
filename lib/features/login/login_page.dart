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
import '../settings/settings_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authController, this.settingsController});

  /// 测试可显式注入；生产路由默认从 AppScope 获取。
  final AuthController? authController;
  final SettingsController? settingsController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _contentMaxWidth = 320.0;
  static const _fieldHeight = 48.0;

  final _accountController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _captchaController = TextEditingController(text: '');
  final _accountFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _captchaFocusNode = FocusNode();
  AuthController? _authController;
  SettingsController? _settingsController;
  bool _captchaRequested = false;
  bool _privacyAccepted = false;
  bool _submitting = false;
  bool _passwordVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authController =
        widget.authController ?? AppScope.of(context).authController;
    _settingsController =
        widget.settingsController ?? AppScope.of(context).settingsController;
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
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final auth = _authController!;
    var navigationStarted = false;
    try {
      final ok = await auth.login(
        account: _accountController.text,
        password: _passwordController.text,
        captchaCode: _captchaController.text,
      );
      if (!mounted) {
        return;
      }
      if (!ok) {
        _captchaController.clear();
        AppNotice.show(
          context,
          message: auth.lastError ?? context.l10n.loginFailed,
          tone: AppNoticeTone.error,
        );
        return;
      }

      final session = auth.session!;
      final settings = _settingsController!;
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
      // 路由已经接管页面生命周期，不要在下一帧前把按钮恢复成普通状态。
      navigationStarted = true;
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      AppScope.of(
        context,
      ).logger.error('auth', '登录后初始化失败', error: error, stackTrace: stackTrace);
      AppNotice.show(
        context,
        message: context.l10n.loginFailed,
        tone: AppNoticeTone.error,
      );
    } finally {
      if (mounted && !navigationStarted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _authController!;
    final settings = _settingsController!;
    return ListenableBuilder(
      // 版本号来自 SettingsController 的 PackageInfo 读取结果。登录页也
      // 监听它，以免应用启动时先短暂显示默认版本号。
      listenable: Listenable.merge([auth, settings]),
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
                      // 将登录内容略微上移，为表单与协议区保留更舒适的空间。
                      alignment: const Alignment(0, -0.28),
                      child: ConstrainedBox(
                        // 手机端保持细长的表单比例，避免在宽屏手机上横向铺满。
                        constraints: const BoxConstraints(
                          maxWidth: _contentMaxWidth,
                        ),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 品牌图标与版本信息固定居中，避免受表单宽度影响。
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(19),
                                    child: Image.asset(
                                      'assets/branding/splash_logo.png',
                                      fit: BoxFit.contain,
                                      semanticLabel: 'MERP',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'v${settings.currentVersion}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              // 品牌信息与登录表单形成两个独立区域。
                              const SizedBox(height: 30),
                              SizedBox(
                                height: _fieldHeight,
                                child: TextField(
                                  enabled: !_submitting,
                                  controller: _accountController,
                                  focusNode: _accountFocusNode,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
                                  decoration: _compactInputDecoration(
                                    label: context.l10n.account,
                                    prefixIcon: Icons.person_outline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: _fieldHeight,
                                child: TextField(
                                  enabled: !_submitting,
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.next,
                                  obscureText: !_passwordVisible,
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
                                  decoration: _compactInputDecoration(
                                    label: context.l10n.password,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      key: const ValueKey(
                                        'login.password.visibility',
                                      ),
                                      tooltip: _passwordVisible
                                          ? context.l10n.hidePassword
                                          : context.l10n.showPassword,
                                      onPressed: _submitting
                                          ? null
                                          : () => setState(
                                              () => _passwordVisible =
                                                  !_passwordVisible,
                                            ),
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 21,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 42,
                                            height: 42,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: _fieldHeight,
                                      child: TextField(
                                        enabled: !_submitting,
                                        controller: _captchaController,
                                        focusNode: _captchaFocusNode,
                                        textInputAction: TextInputAction.done,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        onSubmitted: (_) => _handleLoginTap(),
                                        decoration: _compactInputDecoration(
                                          label: context.l10n.captcha,
                                          prefixIcon:
                                              Icons.verified_user_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
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
                                          width: 104,
                                          height: _fieldHeight,
                                          child: _buildCaptcha(context, auth),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _PrivacyConsent(
                                accepted: _privacyAccepted,
                                enabled: !_submitting,
                                onChanged: (value) {
                                  setState(() => _privacyAccepted = value);
                                },
                                onOpenCopyright: () =>
                                    context.push(AppRoute.copyrightDisclaimer),
                                onOpenPersonalData: () => context.push(
                                  AppRoute.personalDataStatement,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: FractionallySizedBox(
                                  // 保持按钮比输入框短，同时适配不同屏幕宽度。
                                  widthFactor: 0.64,
                                  child: SizedBox(
                                    height: 46,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        // 登录按钮使用固定浅蓝色，不随主题变化。
                                        backgroundColor: const Color(
                                          0xFFDCEEFF,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF155D9C,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFFE1E5EA,
                                        ),
                                        disabledForegroundColor: const Color(
                                          0xFF5F6B76,
                                        ),
                                      ),
                                      onPressed: _submitting
                                          ? null
                                          : _handleLoginTap,
                                      icon: _submitting
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF5F6B76),
                                              ),
                                            )
                                          : const Icon(Icons.login, size: 20),
                                      label: Text(
                                        _submitting
                                            ? context.l10n.loggingIn
                                            : context.l10n.login,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
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

  /// 登录页三个输入栏统一使用紧凑规格，避免单独修改导致高度和图标错位。
  InputDecoration _compactInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: Icon(prefixIcon, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIcon == null
          ? null
          : const BoxConstraints(minWidth: 42, minHeight: 42),
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
    required this.enabled,
    required this.onChanged,
    required this.onOpenCopyright,
    required this.onOpenPersonalData,
  });

  final bool accepted;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenCopyright;
  final VoidCallback onOpenPersonalData;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.35,
    );
    final linkStyle = textStyle?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: accepted,
          onChanged: enabled ? (value) => onChanged(value ?? false) : null,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 8),
        Expanded(
          // 宽屏优先在同一行展示；小屏或系统大字体下自然换行，不缩小文字。
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: enabled ? () => onChanged(!accepted) : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      context.l10n.legalConsentPrefix,
                      style: textStyle,
                    ),
                  ),
                ),
                _LegalLink(
                  label: '《${context.l10n.copyrightDisclaimer}》',
                  onTap: enabled ? onOpenCopyright : null,
                  style: linkStyle,
                ),
                _LegalLink(
                  label: '《${context.l10n.personalDataStatement}》',
                  onTap: enabled ? onOpenPersonalData : null,
                  style: linkStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.onTap,
    required this.style,
  });

  final String label;
  final VoidCallback? onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: style),
      ),
    );
  }
}
