import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

/// Search field used by tool lists.
class const ToolsSearchInput({
  required final ValueChanged<String> onChanged,
  final String searchQuery = '',
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: AuraInput(
      controller: useTextEditingController(text: searchQuery),
      placeholder: const TextLocale(LocaleKeys.tools_screen_search_tools),
      prefixIcon: const AuraIcon(Icons.search),
      size: .small,
      textInputAction: .search,
      onChanged: onChanged,
    ),
  );
}
