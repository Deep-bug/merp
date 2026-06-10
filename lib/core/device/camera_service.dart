import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCapture {
  const CameraCapture({required this.path, required this.name});

  final String path;
  final String name;
}

class CameraService {
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<CameraCapture?> takePhoto() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const DevicePermissionException('相机权限未授权');
    }

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1920,
    );
    if (file == null) {
      return null;
    }
    return CameraCapture(path: file.path, name: file.name);
  }
}

class DevicePermissionException implements Exception {
  const DevicePermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
