import 'package:auravibes_app/features/workspaces/screens/create_workspace_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

export 'create_workspace_form.dart';

/// Screen for creating a workspace.
class CreateWorkspaceScreen extends StatelessWidget {
  /// Creates a workspace screen.
  const new({required this.workspaceId, super.key});

  /// Workspace id used for the return route.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final createLocation = WorkspaceCreateRoute(workspaceId: workspaceId)
        .location;

    return AuraScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CreateWorkspaceForm(
            onCreated: (workspace) =>
                context.go(NewChatRoute(workspaceId: workspace.id).location),
            onAddCloudAccount: () => context.go(
              CloudAccountAddRoute(
                workspaceId: workspaceId,
                returnPath: createLocation,
              ).location,
            ),
          ),
        ],
      ),
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.workspace_management_create_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
