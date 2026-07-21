// -----------------------------------------------------------------------------
// 文件：file_service.dart
// 作用：为 WebView Bridge 提供受控文件选择和可选 Base64 返回
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class AppFileSelection {
  const AppFileSelection({
    required this.name,
    required this.size,
    required this.extension,
    required this.path,
    this.base64,
  });

  final String name;
  final int size;
  final String? extension;
  final String? path;
  final String? base64;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'size': size,
      'extension': extension,
      'path': path,
      'base64': base64,
    };
  }
}

typedef PickFilesCallback =
    Future<FilePickerResult?> Function({
      FileType type,
      List<String>? allowedExtensions,
      bool allowMultiple,
      bool withData,
    });

class FileService {
  FileService({PickFilesCallback? pickFiles})
    : _pickFiles = pickFiles ?? _pickFilesFromPlatform;

  final PickFilesCallback _pickFiles;

  static Future<FilePickerResult?> _pickFilesFromPlatform({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
  }) {
    return FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
      withData: withData,
    );
  }

  Future<List<AppFileSelection>?> pickFiles({
    bool allowMultiple = false,
    bool includeBase64 = false,
    List<String> allowedExtensions = const [],
    int maximumFileBytes = 10 * 1024 * 1024,
  }) async {
    final normalizedExtensions = allowedExtensions
        .map((item) => item.trim().replaceFirst('.', '').toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final result = await _pickFiles(
      type: normalizedExtensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: normalizedExtensions.isEmpty
          ? null
          : normalizedExtensions,
      allowMultiple: allowMultiple,
      withData: includeBase64,
    );
    if (result == null) {
      return null;
    }

    final selections = <AppFileSelection>[];
    for (final file in result.files) {
      if (file.size > maximumFileBytes) {
        throw FileSelectionException(
          '文件“${file.name}”超过大小限制',
          details: {
            'fileName': file.name,
            'fileSize': file.size,
            'maximumFileBytes': maximumFileBytes,
          },
        );
      }
      if (includeBase64 && file.bytes == null) {
        throw FileSelectionException(
          '无法读取文件“${file.name}”的内容',
          details: {'fileName': file.name},
        );
      }
      selections.add(
        AppFileSelection(
          name: file.name,
          size: file.size,
          extension: file.extension,
          path: file.path,
          base64: file.bytes == null ? null : base64Encode(file.bytes!),
        ),
      );
    }
    return selections;
  }
}

class FileSelectionException implements Exception {
  const FileSelectionException(this.message, {this.details = const {}});

  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => message;
}
