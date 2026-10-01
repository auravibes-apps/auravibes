import 'package:auravibes_app/features/workspaces/widgets/workspace_setup_content.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

export 'create_workspace_form.dart';

/// Screen for creating a workspace.
class CreateWorkspaceScreen extends StatelessWidget {
  /// Creates a workspace screen.
  const new({required this.workspaceId, super.key});

  /// Workspace id used for the return route.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _CreateWorkspaceContent(workspaceId: workspaceId),
      appBar: const _CreateWorkspaceAppBar(),
    );
  }
}

class const _CreateWorkspaceContent({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _WorkspaceCreateTaskList(workspaceId: workspaceId);
}

class const _WorkspaceCreateTaskList({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16)
        .copyWith(bottom: BottomPadding.of(context)),
    children: [_WorkspaceCreateTask(workspaceId: workspaceId)],
    keyboardDismissBehavior: .onDrag,
  );
}

class const _WorkspaceCreateTask({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceSetupContent(
    taskId: WorkspaceCreateRoute(workspaceId: workspaceId).location,
    onCreated: (workspace) => _openWorkspace(context, workspace.id),
    onReturn: () =>
        WorkspaceManagementRoute(workspaceId: workspaceId).go(context),
  );

  void _openWorkspace(BuildContext context, String workspaceId) =>
      context.go(NewChatRoute(workspaceId: workspaceId).location);
}

class const _CreateWorkspaceAppBar()
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.workspace_management_create_title),
    leading: AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  );
}
