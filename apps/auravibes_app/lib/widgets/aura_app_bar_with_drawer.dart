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
    final hasBack = leading != null || Navigator.of(context).canPop();

    return AuraAppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      leading: _AuraAppBarWithDrawerLeading(
        onMenuPressed: () => _toggleDrawer(context),
        showAutomaticBack: hasBack,
        leading: leading,
      ),
      leadingWidth: kToolbarHeight * (hasBack ? 2 : 1),
    );
  }

  void _toggleDrawer(BuildContext context) {
    ResponsiveSlidingDrawerProvider.maybeOf(context)?.toggle();
  }
}

class const _AuraAppBarWithDrawerLeading({
  required final VoidCallback onMenuPressed,
  required final bool showAutomaticBack,
  final Widget? leading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      _DrawerMenuButton(onPressed: onMenuPressed),
      if (leading case final value?)
        _NavigationBackButton(child: value)
      else if (showAutomaticBack)
        const _AutomaticNavigationBackButton(),
    ],
  );
}

class const _DrawerMenuButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('app_drawer_menu'),
    child: AuraIconButton(icon: Icons.menu, onPressed: onPressed),
    identifier: 'app_drawer_menu',
  );
}

class const _NavigationBackButton({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('app_navigation_back'),
    child: child,
    identifier: 'app_navigation_back',
  );
}

class const _AutomaticNavigationBackButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _NavigationBackButton(
    child: AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    ),
  );
}
