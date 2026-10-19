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
}
