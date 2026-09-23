/// 持久化 code 保持兼容；不要随枚举或 UI 文案重命名这些值。
enum UnlockMethod {
  gesture('gesture'),
  fingerprint('fingerprint'),
  face('face');

  const UnlockMethod(this.code);

  final String code;

  static UnlockMethod fromCode(String? code) =>
      values.firstWhere((method) => method.code == code, orElse: () => gesture);
}
