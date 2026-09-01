import 'package:flutter/widgets.dart';

/// A scrollable list of static Aura UI child widgets.
///
/// [alignment] controls how children are placed along the axis perpendicular
/// to [direction]. The list fills bounded parent constraints and shrink-wraps
/// its content when the scroll axis is unbounded.
class AuraList extends StatelessWidget {
  /// Creates a scrollable Aura list.
  const new({
    required this.children,
    this.direction = Axis.vertical,
    this.alignment = CrossAxisAlignment.stretch,
    super.key,
  });

  /// The static widgets displayed by the list.
  final List<Widget> children;

  /// The axis in which children are laid out and scrolled.
  final Axis direction;

  /// The alignment of children along the cross axis.
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: direction,
      primary: false,
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: children,
      ),
    );
  }
}
