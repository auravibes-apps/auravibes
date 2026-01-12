import 'package:auravibes_ui/src/tokens/tokens.dart';
import 'package:flutter/widgets.dart';

@immutable
/// definition of aura paddings
class AuraEdgeInsetsGeometry {
  /// constructor for each side
  const AuraEdgeInsetsGeometry.only({
    this.left = .none,
    this.top = .none,
    this.right = .none,
    this.bottom = .none,
  });

  /// constructor for horizontal padding
  const AuraEdgeInsetsGeometry.horizontal(AuraSpacing spacing)
    : left = spacing,
      right = spacing,
      top = .none,
      bottom = .none;

  /// constructor for vertical padding
  const AuraEdgeInsetsGeometry.vertical(AuraSpacing spacing)
    : top = spacing,
      bottom = spacing,
      left = .none,
      right = .none;

  /// constructor for all same padding
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

  /// none spacing
  static const none = AuraEdgeInsetsGeometry.all(.none);

  /// base spacing
  static const base = AuraEdgeInsetsGeometry.all(.base);

  /// medium spacing
  static const medium = AuraEdgeInsetsGeometry.all(.md);

  /// large spacing
  static const large = AuraEdgeInsetsGeometry.all(.lg);

  /// small spacing
  static const small = AuraEdgeInsetsGeometry.all(.sm);

  /// left padding
  final AuraSpacing left;

  /// top padding
  final AuraSpacing top;

  /// right padding
  final AuraSpacing right;

  /// bottom padding
  final AuraSpacing bottom;

  EdgeInsetsGeometry _padding(BuildContext context) {
    return EdgeInsetsGeometry.only(
      bottom: context.auraTheme.fromSpacing(bottom),
      left: context.auraTheme.fromSpacing(left),
      top: context.auraTheme.fromSpacing(top),
      right: context.auraTheme.fromSpacing(right),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || // Quick check for same instance
      other is AuraEdgeInsetsGeometry && // Check if 'other' is also a Person
          runtimeType == other.runtimeType && // Ensure same type
          left == other.left && // Compare properties
          right == other.right && // Compare properties
          top == other.top && // Compare properties
          bottom == other.bottom; // Compare properties

  @override
  int get hashCode => Object.hashAll([
    left,
    top,
    bottom,
    top,
  ]); // Combine hash codes
}

/// Padding for const
class AuraPadding extends StatelessWidget {
  /// default constructor
  const AuraPadding({
    required this.child,
    this.padding = .base,
    super.key,
  });

  /// pading chilg
  final Widget? child;

  /// spacing for padding
  final AuraEdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding._padding(context),
      child: child,
    );
  }
}
