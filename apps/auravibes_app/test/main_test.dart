// ignore_for_file: prefer-static-class
// Required: Tests keep helper functions top-level.

import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/main.dart' as app_main;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAppFlavor', () {
    test('resolves flavor by name', () {
      expect(app_main.AppFlavorResolver.resolve('dev'), Flavor.dev);
      expect(app_main.AppFlavorResolver.resolve('prod'), Flavor.prod);
    });

    test('throws when flavor name is missing', () {
      expect(() => app_main.AppFlavorResolver.resolve(null), throwsStateError);
    });
  });
}
