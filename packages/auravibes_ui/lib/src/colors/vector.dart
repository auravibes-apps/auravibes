// Required: UI package exposes top-level helpers and constants.
import 'dart:math';

/// Represents a 3D vector for color space transformations.
class Vector {
  static const double _cubeRootExponent = 1 / 3;
  static const int _cubeExponent = 3;

  /// Creates a 3D vector with the given [x], [y], and [z] components.
  const Vector(this.x, this.y, this.z);

  /// The X component of the vector.
  final num x;

  /// The Y component of the vector.
  final num y;

  /// The Z component of the vector.
  final num z;

  /// Adds this vector to [other] and returns the result.
  Vector operator +(Vector other) =>
      Vector(x + other.x, y + other.y, z + other.z);

  /// Subtracts [other] from this vector and returns the result.
  Vector operator -(Vector other) =>
      Vector(x - other.x, y - other.y, z - other.z);

  /// Returns the cube root of each component.
  Vector cbrt() => Vector(
    pow(x, _cubeRootExponent),
    pow(y, _cubeRootExponent),
    pow(z, _cubeRootExponent),
  );

  /// Returns each component cubed.
  Vector cubed() => Vector(
    pow(x, _cubeExponent),
    pow(y, _cubeExponent),
    pow(z, _cubeExponent),
  );

  /// Transforms this vector using the matrix [m].
  Vector transform(MatrixTransformation m) => m.transform(this);
}

/// Represents a 3x3 matrix for color space transformations.
class MatrixTransformation {
  /// Creates a matrix transformation from three row vectors.
  const MatrixTransformation(this.first, this.second, this.third);

  /// Creates a matrix by multiplying [a] and [b].
  factory MatrixTransformation.multiply(
    MatrixTransformation a,
    MatrixTransformation b,
  ) => MatrixTransformation(
    a.transform(b.first),
    a.transform(b.second),
    a.transform(b.third),
  );

  /// First row vector of the matrix.
  final Vector first;

  /// Second row vector of the matrix.
  final Vector second;

  /// Third row vector of the matrix.
  final Vector third;

  /// Transforms vector [v] using this matrix.
  Vector transform(Vector v) => Vector(
    first.x * v.x + first.y * v.y + first.z * v.z,
    second.x * v.x + second.y * v.y + second.z * v.z,
    third.x * v.x + third.y * v.y + third.z * v.z,
  );

  /// Multiplies this matrix with [other] and returns the result.
  MatrixTransformation operator *(MatrixTransformation other) =>
      MatrixTransformation.multiply(this, other);
}

/// Matrix transformations used by the color conversion pipeline.
abstract final class ColorSpaceMatrices {
  /// Matrix transformation from LMS to Oklab color space.
  static const lmsToOklab = MatrixTransformation(
    Vector(0.2104542553, 0.793617785, -0.0040720468),
    Vector(1.9779984951, -2.428592205, 0.4505937099),
    Vector(0.0259040371, 0.7827717662, -0.808675766),
  );

  /// Matrix transformation from Oklab to LMS color space.
  static const oklabToLms = MatrixTransformation(
    Vector(
      0.99999999845051981432,
      0.39633779217376785678,
      0.21580375806075880339,
    ),
    Vector(
      1.0000000088817607767,
      -0.1055613423236563494,
      -0.063854174771705903402,
    ),
    Vector(
      1.0000000546724109177,
      -0.089484182094965759684,
      -1.2914855378640917399,
    ),
  );

  /// Matrix transformation from linear RGB to LMS color space.
  static const lrgbToLms = MatrixTransformation(
    Vector(0.41222147079999993, 0.5363325363, 0.0514459929),
    Vector(0.2119034981999999, 0.6806995450999999, 0.1073969566),
    Vector(0.08830246189999998, 0.2817188376, 0.6299787005000002),
  );

  /// Matrix transformation from LMS to linear RGB color space.
  static const lmsTolrgb = MatrixTransformation(
    Vector(4.076741661347994, -3.307711590408193, 0.230969928729428),
    Vector(-1.2684380040921763, 2.6097574006633715, -0.3413193963102197),
    Vector(-0.004196086541837188, -0.7034186144594493, 1.7076147009309444),
  );
}
// Matrix constants are public implementation data used by color conversion.
