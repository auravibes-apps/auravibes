import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A responsive grid using a minimum item width and theme spacing.
class AuraGrid extends StatelessWidget {
  /// Creates a grid.
  const new({
    required this.children,
    super.key,
    this.minimumItemWidth = 220,
    this.spacing,
  });

  /// Grid items.
  final List<Widget> children;

  /// Minimum width before another column is added.
  final double minimumItemWidth;

  /// Optional item spacing.
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? context.auraTheme.spacing.md;

    return LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth.isFinite
            ? (constraints.maxWidth / (minimumItemWidth + gap)).floor().clamp(
                1,
                6,
              )
            : 1;
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - gap * (columns - 1)) / columns
            : minimumItemWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

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
