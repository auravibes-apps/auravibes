// Required: UI callbacks stay local to their widgets.
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const AuraAppBarWithDrawer({
  required final Widget title,
  super.key,
  final List<Widget>? actions,
  final PreferredSizeWidget? bottom,
  final Widget? leading,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final back =
        leading ??
        (Navigator.of(context).canPop()
            ? AuraIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null);
    final leadingItems = [
      Semantics(
        key: const ValueKey<String>('app_drawer_menu'),
        child: AuraIconButton(
          icon: Icons.menu,
          onPressed: () => _toggleDrawer(context),
        ),
        identifier: 'app_drawer_menu',
      ),
      if (back case final value?)
        Semantics(
          key: const ValueKey<String>('app_navigation_back'),
          child: value,
          identifier: 'app_navigation_back',
        ),
    ];

    return AuraAppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      leading: Row(mainAxisSize: .min, children: leadingItems),
      leadingWidth: kToolbarHeight * leadingItems.length,
    );
  }

  void _toggleDrawer(BuildContext context) {
    ResponsiveSlidingDrawerProvider.maybeOf(context)?.toggle();
  }
}
