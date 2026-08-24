// Required: UI callbacks stay local to their widgets.
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class AuraAppBarWithDrawer extends StatelessWidget
    implements PreferredSizeWidget {
  const AuraAppBarWithDrawer({
    required this.title,
    super.key,
    this.actions,
    this.bottom,
    this.leading,
  });

  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      leading:
          leading ??
          AuraIconButton(
            icon: Icons.menu,
            onPressed: () => _toggleDrawer(context),
          ),
    );
  }

  void _toggleDrawer(BuildContext context) {
    ResponsiveSlidingDrawerProvider.maybeOf(context)?.toggle();
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}
