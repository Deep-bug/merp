// -----------------------------------------------------------------------------
// 文件：l10n.dart
// 作用：提供 BuildContext 的强类型国际化快捷访问入口
// 编写时间：2026-07-10
// 维护说明：页面统一使用 context.l10n，禁止散落 Locale 判断
// -----------------------------------------------------------------------------

import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// 页面获取本地化文案的统一入口。
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
