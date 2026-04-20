import 'package:auravibes_ui/src/colors/matrix_transformations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vector', () {
    test('creates with x, y, z components', () {
      const v = Vector(1, 2, 3);
      expect(v.x, 1);
      expect(v.y, 2);
      expect(v.z, 3);
    });

    test('adds two vectors', () {
      const v1 = Vector(1, 2, 3);
      const v2 = Vector(4, 5, 6);
      final result = v1 + v2;
      expect(result.x, 5);
      expect(result.y, 7);
      expect(result.z, 9);
    });

    test('subtracts two vectors', () {
      const v1 = Vector(5, 7, 9);
      const v2 = Vector(1, 2, 3);
      final result = v1 - v2;
      expect(result.x, 4);
      expect(result.y, 5);
      expect(result.z, 6);
    });

    test('cbrt returns cube root of each component', () {
      const v = Vector(8, 27, 64);
      final result = v.cbrt();
      expect(result.x, closeTo(2, 0.0001));
      expect(result.y, closeTo(3, 0.0001));
      expect(result.z, closeTo(4, 0.0001));
    });

    test('cubed returns each component cubed', () {
      const v = Vector(2, 3, 4);
      final result = v.cubed();
      expect(result.x, 8);
      expect(result.y, 27);
      expect(result.z, 64);
    });

    test('transform applies matrix transformation', () {
      const v = Vector(1, 0, 0);
      const m = MatrixTransformation(
        Vector(2, 0, 0),
        Vector(0, 3, 0),
        Vector(0, 0, 4),
      );
      final result = v.transform(m);
      expect(result.x, 2);
      expect(result.y, 0);
      expect(result.z, 0);
    });

    test('transform with full matrix', () {
      const v = Vector(1, 2, 3);
      const m = MatrixTransformation(
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
      );
      final result = v.transform(m);
      expect(result.x, 1);
      expect(result.y, 2);
      expect(result.z, 3);
    });
  });

  group('MatrixTransformation', () {
    test('creates from three row vectors', () {
      const m = MatrixTransformation(
        Vector(1, 2, 3),
        Vector(4, 5, 6),
        Vector(7, 8, 9),
      );
      expect(m.v1.x, 1);
      expect(m.v2.y, 5);
      expect(m.v3.z, 9);
    });

    test('transforms vector correctly', () {
      const m = MatrixTransformation(
        Vector(1, 2, 3),
        Vector(4, 5, 6),
        Vector(7, 8, 9),
      );
      const v = Vector(1, 0, 0);
      final result = m.transform(v);
      expect(result.x, 1);
      expect(result.y, 4);
      expect(result.z, 7);
    });

    test('multiply factory creates product of two matrices', () {
      const a = MatrixTransformation(
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
      );
      const b = MatrixTransformation(
        Vector(2, 0, 0),
        Vector(0, 3, 0),
        Vector(0, 0, 4),
      );
      final result = MatrixTransformation.multiply(a, b);
      expect(result.v1.x, 2);
      expect(result.v2.y, 3);
      expect(result.v3.z, 4);
    });

    test('operator * multiplies matrices', () {
      const a = MatrixTransformation(
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
      );
      const b = MatrixTransformation(
        Vector(2, 0, 0),
        Vector(0, 3, 0),
        Vector(0, 0, 4),
      );
      final result = a * b;
      expect(result.v1.x, 2);
      expect(result.v2.y, 3);
      expect(result.v3.z, 4);
    });
  });

  group('Predefined matrices', () {
    test('xyzToRgb is defined', () {
      expect(xyzToRgb, isA<MatrixTransformation>());
    });

    test('rgbToXyz is defined', () {
      expect(rgbToXyz, isA<MatrixTransformation>());
    });

    test('xyzToLms is defined', () {
      expect(xyzToLms, isA<MatrixTransformation>());
    });

    test('lmsToOklab is defined', () {
      expect(lmsToOklab, isA<MatrixTransformation>());
    });

    test('oklabToLms is defined', () {
      expect(oklabToLms, isA<MatrixTransformation>());
    });

    test('lmsToXyz is defined', () {
      expect(lmsToXyz, isA<MatrixTransformation>());
    });

    test('lrgbToLms is defined', () {
      expect(lrgbToLms, isA<MatrixTransformation>());
    });

    test('lmsTolrgb is defined', () {
      expect(lmsTolrgb, isA<MatrixTransformation>());
    });

    test('rgbToXyz and xyzToRgb are approximate inverses', () {
      const v = Vector(0.5, 0.3, 0.2);
      final rgb = xyzToRgb.transform(v);
      final back = rgbToXyz.transform(rgb);
      expect(back.x, closeTo(v.x, 0.0001));
      expect(back.y, closeTo(v.y, 0.0001));
      expect(back.z, closeTo(v.z, 0.0001));
    });
  });
}
