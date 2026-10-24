import 'package:auravibes_app/features/workspaces/models/workspace_history_policy.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemFailure({required final Object error, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (error) {
    final WorkspaceHistoryPolicyException failure => TextLocale(failure.localizationKey),
    final WorkspaceCsvException failure => TextLocale(failure.localizationKey),
    final WorkspaceFolderException failure => TextLocale(
      failure.localizationKey,
    ),
    final WorkspaceTableException failure => TextLocale(
      failure.localizationKey,
    ),
    _ => TextLocale(CloudAppErrors.localizationKey(error)),
  };
}
