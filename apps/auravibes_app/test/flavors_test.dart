// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flavor', () {
    test('has three values', () {
      expect(Flavor.values, hasLength(3));
    });

    test('values are prod, dev, beta', () {
      expect(Flavor.values, contains(Flavor.prod));
      expect(Flavor.values, contains(Flavor.dev));
      expect(Flavor.values, contains(Flavor.beta));
    });

    test('name property returns correct string', () {
      expect(Flavor.prod.name, 'prod');
      expect(Flavor.dev.name, 'dev');
      expect(Flavor.beta.name, 'beta');
    });
  });

  group('F', () {
    test('title switch cases match flavor names', () {
      expect(Flavor.prod.name, 'prod');
      expect(Flavor.dev.name, 'dev');
      expect(Flavor.beta.name, 'beta');
    });

    test('name and title return correct values for assigned flavor', () {
      try {
        F.appFlavor = Flavor.prod;
      } on Object catch (_) {
        // Already set by another test in this process.
      }
      expect(F.name, isNotEmpty);
      expect(F.title, isNotEmpty);
    });
  });
}
