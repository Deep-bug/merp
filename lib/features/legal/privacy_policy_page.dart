// -----------------------------------------------------------------------------
// 文件：privacy_policy_page.dart
// 作用：展示内置的多语言用户隐私协议 HTML 内容
// 维护说明：正式发布前由法务替换 assets/legal 下的对应 HTML 文件
// -----------------------------------------------------------------------------

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/platform/webview_support.dart';
import '../../l10n/l10n.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_routes.dart';
import '../../shared/app_error_view.dart';

enum _PolicyLanguage {
  simplified('assets/legal/privacy_policy_zh_CN.html'),
  traditional('assets/legal/privacy_policy_zh_TW.html');

  const _PolicyLanguage(this.assetPath);

  final String assetPath;
}

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  WebViewController? _controller;
  _PolicyLanguage? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_language != null) {
      return;
    }
    _language = _languageFromDevice();
    if (WebViewSupport.isSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..loadFlutterAsset(_language!.assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.back,
          onPressed: () => AppNavigator.backTo(context, AppRoute.login),
          icon: const Icon(Icons.chevron_left),
        ),
        title: Text(context.l10n.privacyPolicy),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(
              context.l10n.privacyPolicyDemoNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: controller == null
                ? AppErrorView(
                    icon: Icons.phone_android_outlined,
                    tone: AppErrorTone.warning,
                    title: context.l10n.webViewUnsupported,
                    message: WebViewSupport.unsupportedDetail,
                    primaryLabel: context.l10n.back,
                    onPrimary: () =>
                        AppNavigator.backTo(context, AppRoute.login),
                  )
                : WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }

  _PolicyLanguage _languageFromDevice() {
    final locale = PlatformDispatcher.instance.locale;
    if (locale.languageCode.toLowerCase() != 'zh') {
      return _PolicyLanguage.traditional;
    }

    final script = locale.scriptCode?.toLowerCase();
    final region = locale.countryCode?.toUpperCase();
    if (script == 'hans' || region == 'CN' || region == 'SG') {
      return _PolicyLanguage.simplified;
    }
    return _PolicyLanguage.traditional;
  }
}
