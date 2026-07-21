import 'dart:io';

/// 写入应用沙箱临时目录，便于真机 Release 问题通过 Xcode 设备服务排查。
/// 调用方传入的内容已经经过 AppLogger 脱敏。
void writePlatformLog(String text) {
  try {
    final file = File('${Directory.systemTemp.path}/merp_diagnostics.log');
    if (file.existsSync() && file.lengthSync() > 512 * 1024) {
      file.writeAsStringSync('');
    }
    file.writeAsStringSync('$text\n', mode: FileMode.append, flush: true);
  } on FileSystemException {
    // 诊断日志不可影响正常业务流程。
  }
}
