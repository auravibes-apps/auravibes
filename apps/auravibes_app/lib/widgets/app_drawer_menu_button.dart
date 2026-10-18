import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const AppDrawerMenuButton({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.menu,
    onPressed: () => _toggleDrawer(context),
    identifier: 'app_drawer_menu',
    semanticLabel: LocaleKeys.navigation_drawer_toggle_tooltip.tr(),
    tooltip: LocaleKeys.navigation_drawer_toggle_tooltip.tr(),
  );

  void _toggleDrawer(BuildContext context) {
    ResponsiveSlidingDrawerProvider.maybeOf(context)?.toggle();
  }
}
