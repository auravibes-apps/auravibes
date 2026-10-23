import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemFailure({required final Object error, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (error) {
    WorkspaceFolderException() => const TextLocale(
      LocaleKeys.workspace_items_invalid_folder,
    ),
    WorkspaceTableException(conflict: true) => const TextLocale(
      LocaleKeys.cloud_errors_conflict,
    ),
    WorkspaceTableException() => const TextLocale(
      LocaleKeys.workspace_items_invalid_table,
    ),
    _ => TextLocale(CloudAppErrors.localizationKey(error)),
  };
}
