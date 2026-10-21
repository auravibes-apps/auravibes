import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// App-owned screen wrapper for content that must avoid device cutouts.
class const AppScreen({
  required final Widget child,
  final PreferredSizeWidget? appBar,
  final AuraScreenVariation variant = AuraScreenVariation.standard,
  final AuraEdgeInsetsGeometry? padding,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: SafeArea(top: false, bottom: false, child: child),
    appBar: switch (appBar) {
      final bar? => _AppScreenSafeAppBar(appBar: bar),
      _ => null,
    },
    variant: variant,
    padding: padding,
  );
}

class const _AppScreenSafeAppBar({required final PreferredSizeWidget appBar})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) =>
      SafeArea(top: false, bottom: false, child: appBar);
}
