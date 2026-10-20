import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('production entrypoint does not import device preview', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, isNot(contains('package:device_preview/')));
  });

  test('preview entrypoint enables device preview outside lib', () {
    expect(File('lib/main_device_preview.dart').existsSync(), isFalse);

    final entrypoint = File('tool/main_device_preview.dart');
    if (!entrypoint.existsSync()) {
      expect(
        entrypoint.existsSync(),
        isTrue,
        reason: 'preview entrypoint must exist',
      );

      return;
    }

    final source = entrypoint.readAsStringSync();

    expect(source, contains('package:device_preview/device_preview.dart'));
    expect(source, contains('DevicePreview.enable'));
  });

  test('preview launch command targets macOS', () {
    final lines = File('../../pubspec.yaml').readAsLinesSync();
    final previewCommandIndex = lines.indexWhere(
      (line) => line.trim() == 'start:device-preview:',
    );

    expect(previewCommandIndex, isNot(-1));
    final previewCommand = lines[previewCommandIndex + 1];

    expect(previewCommand, contains('fvm flutter run -d macos'));
    expect(previewCommand, contains('--target tool/main_device_preview.dart'));
  });
}
