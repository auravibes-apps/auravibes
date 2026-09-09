part of 'aura_flex.dart';

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
