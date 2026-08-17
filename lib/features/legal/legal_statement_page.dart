// -----------------------------------------------------------------------------
// 文件：legal_statement_page.dart
// 作用：展示内置的多语言版权声明与个资法声明 HTML 内容
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

enum LegalStatementType { copyrightDisclaimer, personalDataStatement }

class LegalStatementPage extends StatefulWidget {
  const LegalStatementPage({required this.type, super.key});

  final LegalStatementType type;

  @override
  State<LegalStatementPage> createState() => _LegalStatementPageState();
}

class _LegalStatementPageState extends State<LegalStatementPage> {
  WebViewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !WebViewSupport.isSupported) {
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..loadFlutterAsset(_assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.back,
          onPressed: () => AppNavigator.backTo(context, AppRoute.settings),
          icon: const Icon(Icons.chevron_left),
        ),
        title: Text(_title(context)),
        centerTitle: true,
      ),
      body: controller == null
          ? AppErrorView(
              icon: Icons.phone_android_outlined,
              tone: AppErrorTone.warning,
              title: context.l10n.webViewUnsupported,
              message: WebViewSupport.unsupportedDetail,
              primaryLabel: context.l10n.back,
              onPrimary: () => AppNavigator.backTo(context, AppRoute.settings),
            )
          : WebViewWidget(controller: controller),
    );
  }

  String get _assetPath {
    final language = _languageFromDevice();
    return switch (widget.type) {
      LegalStatementType.copyrightDisclaimer =>
        'assets/legal/copyright_disclaimer_$language.html',
      LegalStatementType.personalDataStatement =>
        'assets/legal/personal_data_statement_$language.html',
    };
  }

  String _title(BuildContext context) => switch (widget.type) {
    LegalStatementType.copyrightDisclaimer => context.l10n.copyrightDisclaimer,
    LegalStatementType.personalDataStatement =>
      context.l10n.personalDataStatement,
  };

  String _languageFromDevice() {
    final locale = PlatformDispatcher.instance.locale;
    if (locale.languageCode.toLowerCase() != 'zh') {
      return 'zh_TW';
    }
    final script = locale.scriptCode?.toLowerCase();
    final region = locale.countryCode?.toUpperCase();
    return script == 'hans' || region == 'CN' || region == 'SG'
        ? 'zh_CN'
        : 'zh_TW';
  }
}
