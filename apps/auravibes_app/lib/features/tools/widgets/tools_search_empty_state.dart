import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// Empty state shown when a tool search has no matches.
class const ToolsSearchEmptyState({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: AuraColumn(
      children: [
        AuraIcon(Icons.search_off, size: .large),
        AuraText(
          child: TextLocale(LocaleKeys.tools_screen_no_tools_found),
          style: .bodySmall,
          textAlign: .center,
        ),
      ],
      spacing: .sm,
      mainAxisSize: .min,
    ),
  );
}
