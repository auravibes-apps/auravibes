import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

class const AppContent({required final Widget child, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: DesignBreakpoints.sm),
      child: child,
    );
  }
}
