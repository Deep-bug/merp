import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerFormatException implements Exception {
  const ScannerFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ScanCodeResult {
  const ScanCodeResult({required this.text, required this.format});

  final String text;
  final BarcodeFormat format;

  Map<String, Object?> toJson() => {'text': text, 'format': format.name};
}

List<BarcodeFormat> parseScannerFormats(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw const ScannerFormatException('formats 必须是字符串数组');
  }
  if (value.isEmpty) {
    return const [];
  }

  final formats = <BarcodeFormat>{};
  for (final item in value) {
    final name = item.toString().trim();
    if (name == 'barCode') {
      formats.addAll(_oneDimensionalFormats);
      continue;
    }
    final format = _formatByName[name];
    if (format == null) {
      throw ScannerFormatException('不支持的扫码格式：$name');
    }
    formats.add(format);
  }
  return formats.toList(growable: false);
}

const _oneDimensionalFormats = <BarcodeFormat>[
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.itf14,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
];

const _formatByName = <String, BarcodeFormat>{
  'qrCode': BarcodeFormat.qrCode,
  'code128': BarcodeFormat.code128,
  'code39': BarcodeFormat.code39,
  'code93': BarcodeFormat.code93,
  'codabar': BarcodeFormat.codabar,
  'dataMatrix': BarcodeFormat.dataMatrix,
  'ean13': BarcodeFormat.ean13,
  'ean8': BarcodeFormat.ean8,
  'itf14': BarcodeFormat.itf14,
  'upcA': BarcodeFormat.upcA,
  'upcE': BarcodeFormat.upcE,
  'pdf417': BarcodeFormat.pdf417,
  'aztec': BarcodeFormat.aztec,
};
