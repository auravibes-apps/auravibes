import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('production entrypoint does not import device preview', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, isNot(contains('package:device_preview/')));
  });

  test('preview entrypoint enables device preview', () {
    final entrypoint = File('lib/main_device_preview.dart');
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
    expect(
      lines[previewCommandIndex + 1],
      contains('fvm flutter run -d macos'),
    );
  });
}
