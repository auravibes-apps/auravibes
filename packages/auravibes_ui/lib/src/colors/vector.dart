// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'dart:math';

/// Represents a 3D vector for color space transformations.
class Vector {
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
  Vector cbrt() => Vector(pow(x, 1 / 3), pow(y, 1 / 3), pow(z, 1 / 3));

  /// Returns each component cubed.
  Vector cubed() => Vector(pow(x, 3), pow(y, 3), pow(z, 3));

  /// Transforms this vector using the matrix [m].
  Vector transform(MatrixTransformation m) => m.transform(this);
}

/// Represents a 3x3 matrix for color space transformations.
class MatrixTransformation {
  /// Creates a matrix transformation from three row vectors.
  const MatrixTransformation(this.v1, this.v2, this.v3);

  /// Creates a matrix by multiplying [a] and [b].
  factory MatrixTransformation.multiply(
    MatrixTransformation a,
    MatrixTransformation b,
  ) => MatrixTransformation(
    a.transform(b.v1),
    a.transform(b.v2),
    a.transform(b.v3),
  );

  /// First row vector of the matrix.
  final Vector v1;

  /// Second row vector of the matrix.
  final Vector v2;

  /// Third row vector of the matrix.
  final Vector v3;

  /// Transforms vector [v] using this matrix.
  Vector transform(Vector v) => Vector(
    v1.x * v.x + v1.y * v.y + v1.z * v.z,
    v2.x * v.x + v2.y * v.y + v2.z * v.z,
    v3.x * v.x + v3.y * v.y + v3.z * v.z,
  );

  /// Multiplies this matrix with [other] and returns the result.
  MatrixTransformation operator *(MatrixTransformation other) =>
      MatrixTransformation.multiply(this, other);
}

/// Matrix transformation from LMS to Oklab color space.
const lmsToOklab = MatrixTransformation(
  Vector(0.2104542553, 0.793617785, -0.0040720468),
  Vector(1.9779984951, -2.428592205, 0.4505937099),
  Vector(0.0259040371, 0.7827717662, -0.808675766),
);

/// Matrix transformation from Oklab to LMS color space.
const oklabToLms = MatrixTransformation(
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
const lrgbToLms = MatrixTransformation(
  Vector(0.41222147079999993, 0.5363325363, 0.0514459929),
  Vector(0.2119034981999999, 0.6806995450999999, 0.1073969566),
  Vector(0.08830246189999998, 0.2817188376, 0.6299787005000002),
);

/// Matrix transformation from LMS to linear RGB color space.
const lmsTolrgb = MatrixTransformation(
  Vector(4.076741661347994, -3.307711590408193, 0.230969928729428),
  Vector(-1.2684380040921763, 2.6097574006633715, -0.3413193963102197),
  Vector(-0.004196086541837188, -0.7034186144594493, 1.7076147009309444),
);
