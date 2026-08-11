import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/device/scanner_models.dart';
import '../../l10n/l10n.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key, this.formats = const []});

  final List<BarcodeFormat> formats;

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: widget.formats,
    autoZoom: true,
  );
  bool _completed = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_completed) {
      return;
    }
    final barcode = capture.barcodes
        .where((item) => (item.rawValue ?? item.displayValue ?? '').isNotEmpty)
        .firstOrNull;
    final text = barcode?.rawValue ?? barcode?.displayValue;
    if (barcode == null || text == null || text.isEmpty) {
      return;
    }

    _completed = true;
    await _controller.stop();
    if (mounted) {
      Navigator.of(
        context,
      ).pop(ScanCodeResult(text: text, format: barcode.format));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: Text(context.l10n.scannerTitle),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) => IconButton(
              tooltip: state.torchState == TorchState.on ? '关闭闪光灯' : '打开闪光灯',
              onPressed: state.torchState == TorchState.unavailable
                  ? null
                  : _controller.toggleTorch,
              icon: Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) => IconButton(
              tooltip: '切换摄像头',
              onPressed: (state.availableCameras ?? 0) < 2
                  ? null
                  : _controller.switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            tapToFocus: true,
            onDetect: _handleDetection,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          const IgnorePointer(child: _ScanOverlay()),
          const SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 44),
                child: Text(
                  '将二维码或条码放入扫描框内',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.white, size: 54),
              const SizedBox(height: 18),
              Text(
                permissionDenied
                    ? context.l10n.scannerPermissionTitle
                    : context.l10n.scannerStartFailed,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                permissionDenied
                    ? context.l10n.scannerPermissionMessage
                    : context.l10n.scannerStartFailedMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              if (permissionDenied) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(context.l10n.scanOpenSettings),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScanOverlayPainter());
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.width * 0.72).clamp(220.0, 320.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.43),
      width: side,
      height: side,
    );
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = Colors.black54);

    final borderPaint = Paint()
      ..color = const Color(0xFF42D392)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 16, rect.center.dy),
      Offset(rect.right - 16, rect.center.dy),
      Paint()
        ..color = const Color(0xFFE5484D)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
