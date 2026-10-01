import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_setup_content.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const _introMaxContentWidth = 520.0;
const _introMinimumBottomPadding = 24.0;

class const IntroScreen({super.key}) extends StatefulWidget {
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  WorkspaceEntity? _createdWorkspace;

  @override
  Widget build(BuildContext context) => AuraScreen(
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _introMaxContentWidth),
          child: _IntroContent(
            workspace: _createdWorkspace,
            onCreated: _setCreatedWorkspace,
          ),
        ),
      ),
    ),
    variant: .aurora,
  );

  void _setCreatedWorkspace(WorkspaceEntity workspace) =>
      setState(() => _createdWorkspace = workspace);
}

class const _IntroContent({
  required final WorkspaceEntity? workspace,
  required final ValueChanged<WorkspaceEntity> onCreated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24).copyWith(
      bottom: BottomPadding.of(context, minimum: _introMinimumBottomPadding),
    ),
    children: [
      _IntroHeading(workspace: workspace),
      const SizedBox(height: 12),
      _IntroDescription(workspace: workspace),
      const SizedBox(height: 24),
      if (workspace case final readyWorkspace?)
        _IntroWorkspaceActions(workspace: readyWorkspace)
      else
        WorkspaceSetupContent(taskId: 'intro', onCreated: onCreated),
    ],
  );
}

class const _IntroHeading({required final WorkspaceEntity? workspace})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: TextLocale(
      workspace == null ? 'intro_flow.welcome.title' : 'intro_flow.ready.title',
    ),
    style: .heading3,
  );
}

class const _IntroDescription({required final WorkspaceEntity? workspace})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    workspace == null ? 'intro_flow.choice.body' : 'intro_flow.ready.body',
  );
}

class const _IntroWorkspaceActions({required final WorkspaceEntity workspace})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(workspace.name),
      _IntroConnectAiButton(workspaceId: workspace.id),
      _IntroSkipAiButton(workspaceId: workspace.id),
    ],
  );
}

class const _IntroConnectAiButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => ServiceConnectionCreateRoute(
      workspaceId: workspaceId,
      returnPath: NewChatRoute(workspaceId: workspaceId).location,
      type: 'modelProvider',
    ).go(context),
    child: const TextLocale('intro_flow.connect_primary'),
    key: const Key('intro_connect_ai_button'),
  );
}

class const _IntroSkipAiButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => NewChatRoute(workspaceId: workspaceId).go(context),
    child: const TextLocale('intro_flow.connect_skip'),
    key: const Key('intro_skip_ai_button'),
    variant: .outlined,
  );
}
