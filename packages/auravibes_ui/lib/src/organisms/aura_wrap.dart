part of 'aura_grid.dart';

/// A token-spaced flow layout.
class AuraWrap extends StatelessWidget {
  /// Creates a wrapping layout.
  const new({required this.children, super.key, this.spacing});

  /// Flow children.
  final List<Widget> children;

  /// Optional item gap.
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? context.auraTheme.spacing.sm;

    return Wrap(spacing: gap, runSpacing: gap, children: children);
  }
}
