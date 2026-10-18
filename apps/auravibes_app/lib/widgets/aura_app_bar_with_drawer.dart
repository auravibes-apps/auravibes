import 'package:auravibes_app/widgets/app_drawer_menu_button.dart';
import 'package:auravibes_app/widgets/feature_destination_shell_scope.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const AuraAppBarWithDrawer({
  required final Widget title,
  super.key,
  final List<Widget>? actions,
  final PreferredSizeWidget? bottom,
  final Widget? leading,
  final bool? showBackButton,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final shell = FeatureDestinationShellScope.maybeOf(context);
    final currentUri = FeatureDestinations.currentUri(context);

    return _AuraAppBarWithDrawerContent(
      title: title,
      showMenu: _shouldShowMenu(shell, currentUri),
      showBack:
          leading != null || (showBackButton ?? Navigator.of(context).canPop()),
      actions: actions,
      bottom: bottom,
      leading: leading,
    );
  }

  bool _shouldShowMenu(FeatureDestinationShellScope? shell, Uri? currentUri) =>
      shell == null ||
      (shell.isCompact &&
          currentUri != null &&
          FeatureDestinations.isMasterLocation(currentUri));
}

class const _AuraAppBarWithDrawerContent({
  required final Widget title,
  required final bool showMenu,
  required final bool showBack,
  final List<Widget>? actions,
  final PreferredSizeWidget? bottom,
  final Widget? leading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraAppBar(
    title: title,
    actions: actions,
    bottom: bottom,
    leading: _AuraAppBarWithDrawerLeading(
      showMenu: showMenu,
      showAutomaticBack: showBack,
      leading: leading,
    ),
    leadingWidth: kToolbarHeight * ((showMenu ? 1 : 0) + (showBack ? 1 : 0)),
  );
}

class const _AuraAppBarWithDrawerLeading({
  required final bool showMenu,
  required final bool showAutomaticBack,
  final Widget? leading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      if (showMenu) const AppDrawerMenuButton(),
      if (leading case final value?)
        _NavigationBackButton(child: value)
      else if (showAutomaticBack)
        const _AutomaticNavigationBackButton(),
    ],
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
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: () => Navigator.of(context).pop(),
    identifier: 'app_navigation_back',
  );
}
