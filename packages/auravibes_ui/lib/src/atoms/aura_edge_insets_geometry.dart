import 'package:auravibes_ui/src/tokens/tokens.dart';
import 'package:flutter/widgets.dart';

class _AuraEdgeInsetsGeometryData {
  const new({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final AuraSpacing left;
  final AuraSpacing top;
  final AuraSpacing right;
  final AuraSpacing bottom;
}

@immutable
/// Definition of aura paddings.
class AuraEdgeInsetsGeometry extends _AuraEdgeInsetsGeometryData {
  /// No padding on any side.
  static const none = AuraEdgeInsetsGeometry.all(.none);

  /// Standard base padding on every side.
  static const base = AuraEdgeInsetsGeometry.all(.base);

  /// Medium padding on every side.
  static const medium = AuraEdgeInsetsGeometry.all(.md);

  /// Large padding on every side.
  static const large = AuraEdgeInsetsGeometry.all(.lg);

  /// Small padding on every side.
  static const small = AuraEdgeInsetsGeometry.all(.sm);

  /// Constructor for each side.
  const new only({
    super.left = .none,
    super.top = .none,
    super.right = .none,
    super.bottom = .none,
  });

  /// Constructor for horizontal padding.
  const new horizontal(AuraSpacing spacing)
    : super(left: spacing, right: spacing, top: .none, bottom: .none);

  /// Constructor for vertical padding.
  const new vertical(AuraSpacing spacing)
    : super(top: spacing, bottom: spacing, left: .none, right: .none);

  /// Constructor for all same padding.
  const new all(AuraSpacing spacing)
    : super(left: spacing, top: spacing, right: spacing, bottom: spacing);

  /// Constructor for symmetric padding.
  const new symmetric({
    AuraSpacing horizontal = .none,
    AuraSpacing vertical = .none,
  }) : super(
         left: horizontal,
         right: horizontal,
         top: vertical,
         bottom: vertical,
       );
  @override
  int get hashCode => Object.hashAll([left, top, right, bottom]);

  /// Resolves spacing values against the current Aura theme.
  EdgeInsetsGeometry toEdgeInsets(BuildContext context) =>
      EdgeInsetsGeometry.only(
        left: context.auraTheme.fromSpacing(left),
        right: context.auraTheme.fromSpacing(right),
        top: context.auraTheme.fromSpacing(top),
        bottom: context.auraTheme.fromSpacing(bottom),
      );

  /// Creates geometry with selected sides replaced.
  AuraEdgeInsetsGeometry copyWith({
    AuraSpacing? left,
    AuraSpacing? top,
    AuraSpacing? right,
    AuraSpacing? bottom,
  }) => AuraEdgeInsetsGeometry.only(
    left: left ?? this.left,
    top: top ?? this.top,
    right: right ?? this.right,
    bottom: bottom ?? this.bottom,
  );

  /// Describes this padding geometry.
  @override
  String toString() =>
      'AuraEdgeInsetsGeometry('
      'left: $left, top: $top, right: $right, bottom: $bottom)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuraEdgeInsetsGeometry &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          right == other.right &&
          top == other.top &&
          bottom == other.bottom;
}

/// Padding for const.
class AuraPadding extends StatelessWidget {
  /// Default constructor.
  const new({required this.child, this.padding = .base, super.key});

  /// The widget below this padding.
  final Widget child;

  /// Spacing for padding.
  final AuraEdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding.toEdgeInsets(context), child: child);
  }
}
