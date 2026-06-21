import 'package:auravibes_ui/src/tokens/tokens.dart';
import 'package:flutter/widgets.dart';

@immutable
/// Definition of aura paddings.
class AuraEdgeInsetsGeometry {
  /// Constructor for each side.
  const AuraEdgeInsetsGeometry.only({
    this.left = .none,
    this.top = .none,
    this.right = .none,
    this.bottom = .none,
  });

  /// Constructor for horizontal padding.
  const AuraEdgeInsetsGeometry.horizontal(AuraSpacing spacing)
    : left = spacing,
      right = spacing,
      top = .none,
      bottom = .none;

  /// Constructor for vertical padding.
  const AuraEdgeInsetsGeometry.vertical(AuraSpacing spacing)
    : top = spacing,
      bottom = spacing,
      left = .none,
      right = .none;

  /// Constructor for all same padding.
  const AuraEdgeInsetsGeometry.all(AuraSpacing spacing)
    : left = spacing,
      top = spacing,
      right = spacing,
      bottom = spacing;

  /// Constructor for symmetric padding.
  const AuraEdgeInsetsGeometry.symmetric({
    AuraSpacing horizontal = .none,
    AuraSpacing vertical = .none,
  }) : left = horizontal,
       right = horizontal,
       top = vertical,
       bottom = vertical;

  /// None spacing.
  static const none = AuraEdgeInsetsGeometry.all(.none);

  /// Base spacing.
  static const base = AuraEdgeInsetsGeometry.all(.base);

  /// Medium spacing.
  static const medium = AuraEdgeInsetsGeometry.all(.md);

  /// Large spacing.
  static const large = AuraEdgeInsetsGeometry.all(.lg);

  /// Small spacing.
  static const small = AuraEdgeInsetsGeometry.all(.sm);

  /// Left padding.
  final AuraSpacing left;

  /// Top padding.
  final AuraSpacing top;

  /// Right padding.
  final AuraSpacing right;

  /// Bottom padding.
  final AuraSpacing bottom;

  EdgeInsetsGeometry _padding(BuildContext context) {
    return EdgeInsetsGeometry.only(
      left: context.auraTheme.fromSpacing(left),
      right: context.auraTheme.fromSpacing(right),
      top: context.auraTheme.fromSpacing(top),
      bottom: context.auraTheme.fromSpacing(bottom),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || // Quick check for same instance.
      other is AuraEdgeInsetsGeometry && // Check if 'other' is also a Person.
          runtimeType == other.runtimeType && // Ensure same type.
          left == other.left && // Compare properties.
          right == other.right && // Compare properties.
          top == other.top && // Compare properties.
          bottom == other.bottom; // Compare properties.

  @override
  int get hashCode => Object.hashAll([
    left,
    top,
    right,
    bottom,
  ]); // Combine hash codes.
}

/// Padding for const.
class AuraPadding extends StatelessWidget {
  /// Default constructor.
  const AuraPadding({
    required this.child,
    this.padding = .base,
    super.key,
  });

  /// Pading chilg.
  final Widget child;

  /// Spacing for padding.
  final AuraEdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding._padding(context),
      child: child,
    );
  }
}
