import 'package:material_ui/material_ui.dart';

/// Keeps content reachable when keyboard or enlarged text reduces its space.
class const WorkspaceMinimumViewport({
  required final double minimumHeight,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _layout);

  Widget _layout(BuildContext _, BoxConstraints constraints) {
    if (constraints.maxHeight >= minimumHeight) return child;

    return SingleChildScrollView(
      child: SizedBox(height: minimumHeight, child: child),
    );
  }
}
