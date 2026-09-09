part of 'aura_flex.dart';

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
