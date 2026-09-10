import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

part 'aura_wrap.dart';

typedef _GridItemWidthRequest = ({
  AuraGrid grid,
  BoxConstraints constraints,
  double gap,
  int columns,
});

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
  Widget build(BuildContext context) => _AuraGridLayout(grid: this);
}

class const _AuraGridLayout({required final AuraGrid grid})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildLayout);

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final gap = _gridGap(grid, context);
    final columns = _gridColumnCount(grid, constraints, gap);
    final width = _gridItemWidth((
      grid: grid,
      constraints: constraints,
      gap: gap,
      columns: columns,
    ));

    return _AuraGridWrap(children: grid.children, gap: gap, width: width);
  }
}

double _gridGap(AuraGrid grid, BuildContext context) =>
    grid.spacing ?? context.auraTheme.spacing.md;

int _gridColumnCount(AuraGrid grid, BoxConstraints constraints, double gap) =>
    constraints.maxWidth.isFinite
    ? (constraints.maxWidth / (grid.minimumItemWidth + gap)).floor().clamp(1, 6)
    : 1;

double _gridItemWidth(_GridItemWidthRequest request) =>
    request.constraints.maxWidth.isFinite
    ? (request.constraints.maxWidth - request.gap * (request.columns - 1)) /
          request.columns
    : request.grid.minimumItemWidth;

class const _AuraGridWrap({
  required final List<Widget> children,
  required final double gap,
  required final double width,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: gap,
    runSpacing: gap,
    children: [
      for (final child in children) SizedBox(width: width, child: child),
    ],
  );
}
