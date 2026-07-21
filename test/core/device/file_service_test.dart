// -----------------------------------------------------------------------------
// 文件：file_service_test.dart
// 作用：验证 Bridge 文件选择的 Base64、大小限制和取消语义
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/device/file_service.dart';

void main() {
  test('returns selected file metadata and optional base64', () async {
    final service = FileService(
      pickFiles: _FakeFilePicker(
        FilePickerResult([
          PlatformFile(
            name: 'report.txt',
            size: 4,
            path: '/tmp/report.txt',
            bytes: Uint8List.fromList([1, 2, 3, 4]),
          ),
        ]),
      ).pickFiles,
    );

    final files = await service.pickFiles(includeBase64: true);

    expect(files, hasLength(1));
    expect(files!.single.name, 'report.txt');
    expect(files.single.extension, 'txt');
    expect(files.single.base64, 'AQIDBA==');
  });

  test('rejects files larger than bridge limit', () async {
    final service = FileService(
      pickFiles: _FakeFilePicker(
        FilePickerResult([PlatformFile(name: 'large.pdf', size: 4096)]),
      ).pickFiles,
    );

    await expectLater(
      service.pickFiles(maximumFileBytes: 1024),
      throwsA(isA<FileSelectionException>()),
    );
  });

  test('returns null when user cancels picker', () async {
    final service = FileService(pickFiles: _FakeFilePicker(null).pickFiles);

    expect(await service.pickFiles(), isNull);
  });
}

class _FakeFilePicker {
  _FakeFilePicker(this.result);

  final FilePickerResult? result;

  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) async {
    return result;
  }
}
