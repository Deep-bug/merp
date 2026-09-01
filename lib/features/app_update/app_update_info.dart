// -----------------------------------------------------------------------------
// 文件：app_update_info.dart
// 作用：定义版本接口的严格数据模型和升级类型
// -----------------------------------------------------------------------------

enum AppUpdateType {
  none,
  optional,
  force;

  static AppUpdateType fromValue(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'force' => force,
      'optional' => optional,
      'none' => none,
      _ => throw FormatException('版本接口 updateType 不受支持：${value ?? 'null'}'),
    };
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateType,
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  final AppUpdateType updateType;
  final String latestVersionName;
  final int latestVersionCode;
  final String releaseNotes;
  final Uri downloadUrl;

  bool get isForceUpdate => updateType == AppUpdateType.force;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final latestVersionName = _requiredText(json, 'latestVersionName');
    final releaseNotes = _requiredText(json, 'releaseNotes');
    final downloadUrlText = _requiredText(json, 'downloadUrl');
    final downloadUrl = Uri.tryParse(downloadUrlText);
    if (downloadUrl == null || !downloadUrl.hasScheme) {
      throw const FormatException('版本接口 downloadUrl 不是有效链接');
    }

    final rawVersionCode = json['latestVersionCode'];
    final latestVersionCode = rawVersionCode is int
        ? rawVersionCode
        : int.tryParse(rawVersionCode?.toString() ?? '');
    if (latestVersionCode == null || latestVersionCode <= 0) {
      throw const FormatException('版本接口 latestVersionCode 不是有效正整数');
    }

    return AppUpdateInfo(
      updateType: AppUpdateType.fromValue(json['updateType']),
      latestVersionName: latestVersionName,
      latestVersionCode: latestVersionCode,
      releaseNotes: releaseNotes,
      downloadUrl: downloadUrl,
    );
  }

  static String _requiredText(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isEmpty) {
      throw FormatException('版本接口缺少 $key');
    }
    return value;
  }
}
