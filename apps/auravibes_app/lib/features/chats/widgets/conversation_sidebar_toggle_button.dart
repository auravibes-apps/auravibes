import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const ConversationSidebarToggleButton({
  required final bool isPanelVisible,
  required final int? tabCount,
  required final VoidCallback onPressed,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label =
        (isPanelVisible ? LocaleKeys.sidebar_close : LocaleKeys.sidebar_open)
            .tr();

    return AuraIconButton.custom(
      child: Stack(
        clipBehavior: .none,
        children: [
          AuraIcon(
            isPanelVisible ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            semanticLabel: label,
          ),
          if (tabCount case final count?)
            Positioned(
              top: -8,
              right: -8,
              child: AuraBadge.count(
                count: count,
                size: .small,
                semanticLabel: LocaleKeys.sidebar_tabs_count.plural(count),
              ),
            ),
        ],
      ),
      onPressed: onPressed,
      identifier: 'chat_sidebar_button',
      semanticLabel: label,
      tooltip: label,
    );
  }
}
