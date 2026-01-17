import 'package:auravibes_app/widgets/responsive_sliding_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class AuraAppBarWithDrawer extends StatelessWidget
    implements PreferredSizeWidget {
  const AuraAppBarWithDrawer({
    super.key,
    this.title,
    this.actions,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final controller = ResponsiveSlidingDrawerProvider.maybeOf(context);
          if (controller != null) {
            controller.toggle();
          }
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}
