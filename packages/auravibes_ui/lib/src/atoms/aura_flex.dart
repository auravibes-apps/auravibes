import 'package:flutter/widgets.dart';

/// A token-free spacer for generated and ordinary Aura layouts.
class AuraSpacer extends StatelessWidget {
  /// Creates a fixed or flexible spacer.
  const new({super.key, this.size, this.flex = 1});

  /// Fixed size. When omitted, the spacer expands in a Flex parent.
  final double? size;

  /// Flex factor when [size] is omitted.
  final int flex;

  @override
  Widget build(BuildContext context) =>
      size == null ? Spacer(flex: flex) : SizedBox(width: size, height: size);
}

/// Gives a child a controlled flex factor in an Aura row or column.
class AuraFlexItem extends StatelessWidget {
  /// Creates a flex item.
  const new({
    required this.child,
    super.key,
    this.flex = 1,
    this.fit = FlexFit.loose,
  });

  /// Child laid out by the surrounding Flex.
  final Widget child;

  /// Flex factor.
  final int flex;

  /// Whether the item fills its allocation.
  final FlexFit fit;

  @override
  Widget build(BuildContext context) =>
      Flexible(flex: flex, fit: fit, child: child);
}
