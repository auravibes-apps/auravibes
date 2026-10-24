import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceHistoryBlockedFailure({
  required final WorkspaceHistoryBlockedException error,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      const TextLocale(LocaleKeys.workspace_items_history_blocked),
      for (final source in error.resources) Text(source),
    ],
  );
}
