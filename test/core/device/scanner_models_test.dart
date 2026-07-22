import 'package:flutter_test/flutter_test.dart';
import 'package:merp/core/device/scanner_models.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  test('empty scanner formats enable all supported formats', () {
    expect(parseScannerFormats(null), isEmpty);
    expect(parseScannerFormats(const []), isEmpty);
  });

  test('parses qrCode and generic barCode formats without duplicates', () {
    final formats = parseScannerFormats(const ['qrCode', 'barCode', 'ean13']);

    expect(formats, contains(BarcodeFormat.qrCode));
    expect(formats, contains(BarcodeFormat.code128));
    expect(formats.where((item) => item == BarcodeFormat.ean13), hasLength(1));
  });

  test('rejects unsupported scanner format', () {
    expect(
      () => parseScannerFormats(const ['unsupported']),
      throwsA(isA<ScannerFormatException>()),
    );
  });

  test('serializes scanner result using bridge contract', () {
    const result = ScanCodeResult(
      text: 'MERP-ORDER-10001',
      format: BarcodeFormat.qrCode,
    );

    expect(result.toJson(), {'text': 'MERP-ORDER-10001', 'format': 'qrCode'});
  });
}
