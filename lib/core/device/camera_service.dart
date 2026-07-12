// -----------------------------------------------------------------------------
// 文件：camera_service.dart
// 作用：统一处理相机权限、拍照参数和返回给 WebView 的图片结构
// 编写时间：2026-07-10
// 维护说明：业务与 Bridge 不直接依赖 image_picker 和 permission_handler
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 原生相机返回给旧 Vue2 页面的标准数据结构。
///
/// 这里刻意不绑定具体业务字段，旧系统只需要通过 bridge 拿到图片路径、
/// 文件信息和可选 base64，就可以继续沿用原来的上传或预览流程。
class CameraCapture {
  const CameraCapture({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.size,
    this.base64,
  });

  /// App 沙盒内的临时文件路径，适合后续再扩展“原生上传”bridge。
  final String path;

  /// 文件名，直接透传给 Vue2 页面用于显示或表单提交。
  final String name;

  /// MIME 类型，image_picker 在部分平台拿不到时默认按 jpg 处理。
  final String mimeType;

  /// 文件字节数，方便 Vue2 做大小校验。
  final int size;

  /// 可选 base64。旧 Vue2 需要直接预览时传 true，普通拍照可不返回以降低内存占用。
  final String? base64;

  String? get dataUrl =>
      base64 == null ? null : 'data:$mimeType;base64,$base64';

  Map<String, Object?> toJson() {
    return {
      'path': path,
      'name': name,
      'mimeType': mimeType,
      'size': size,
      'base64': base64,
      'dataUrl': dataUrl,
    };
  }
}

/// 设备相机能力封装。
///
/// 业务页面不要直接依赖 image_picker；旧 Vue2 页面统一走 WebView bridge，
/// Flutter 原生页面后续如需拍照也复用这个服务，避免权限和返回结构各写一套。
class CameraService {
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<CameraCapture?> takePhoto({
    bool includeBase64 = false,
    int imageQuality = 88,
    double maxWidth = 1920,
  }) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const DevicePermissionException('相机权限未授权，请在系统设置中开启相机权限');
    }

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality.clamp(1, 100),
      maxWidth: maxWidth,
    );
    if (file == null) {
      return null;
    }

    final bytes = includeBase64 ? await file.readAsBytes() : null;
    final size = bytes?.length ?? await file.length();

    return CameraCapture(
      path: file.path,
      name: file.name,
      mimeType: file.mimeType ?? 'image/jpeg',
      size: size,
      base64: bytes == null ? null : base64Encode(bytes),
    );
  }
}

class DevicePermissionException implements Exception {
  const DevicePermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
