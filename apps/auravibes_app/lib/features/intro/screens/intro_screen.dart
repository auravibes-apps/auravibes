import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_setup_content.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
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
  Widget build(BuildContext context) => AppScreen(
    child: _IntroResponsiveLayout(
      workspace: _createdWorkspace,
      onCreated: _setCreatedWorkspace,
    ),
    variant: .aurora,
  );

  void _setCreatedWorkspace(WorkspaceEntity workspace) =>
      setState(() => _createdWorkspace = workspace);
}

class const _IntroResponsiveLayout({
  required final WorkspaceEntity? workspace,
  required final ValueChanged<WorkspaceEntity> onCreated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    child: _IntroResponsiveBounds(workspace: workspace, onCreated: onCreated),
  );
}

class const _IntroResponsiveBounds({
  required final WorkspaceEntity? workspace,
  required final ValueChanged<WorkspaceEntity> onCreated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _IntroContentBounds(
      isWide: constraints.maxWidth >= DesignBreakpoints.md,
      workspace: workspace,
      onCreated: onCreated,
    ),
  );
}

class const _IntroContentBounds({
  required final bool isWide,
  required final WorkspaceEntity? workspace,
  required final ValueChanged<WorkspaceEntity> onCreated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: .new(
        maxWidth: isWide ? DesignBreakpoints.xl : _introMaxContentWidth,
      ),
      child: _IntroContent(
        isWide: isWide,
        workspace: workspace,
        onCreated: onCreated,
      ),
    ),
  );
}

class const _IntroContent({
  required final bool isWide,
  required final WorkspaceEntity? workspace,
  required final ValueChanged<WorkspaceEntity> onCreated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _IntroContentLayout(
    isWide: isWide,
    padding: _padding(context),
    heading: _IntroHeading(workspace: workspace),
    description: _IntroDescription(workspace: workspace),
    setup: _IntroSetup(workspace: workspace, onCreated: onCreated),
  );

  EdgeInsets _padding(BuildContext context) => const EdgeInsets.all(24)
      .copyWith(
        bottom: BottomPadding.of(context, minimum: _introMinimumBottomPadding),
      );
}

class const _IntroSetup({
  required final WorkspaceEntity? workspace,
  required final ValueChanged<WorkspaceEntity> onCreated,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (workspace) {
    final readyWorkspace? => _IntroWorkspaceActions(workspace: readyWorkspace),
    null => WorkspaceSetupContent(taskId: 'intro', onCreated: onCreated),
  };
}

class const _IntroContentLayout({
  required final bool isWide,
  required final EdgeInsets padding,
  required final Widget heading,
  required final Widget description,
  required final Widget setup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isWide
      ? _WideIntroContent(
          padding: padding,
          heading: heading,
          description: description,
          setup: setup,
        )
      : _CompactIntroContent(
          padding: padding,
          heading: heading,
          description: description,
          setup: setup,
        );
}

class const _WideIntroContent({
  required final EdgeInsets padding,
  required final Widget heading,
  required final Widget description,
  required final Widget setup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: ListView(
          padding: padding,
          children: [heading, const SizedBox(height: 12), description],
        ),
      ),
      Expanded(
        child: ListView(padding: padding, children: [setup]),
      ),
    ],
  );
}

class const _CompactIntroContent({
  required final EdgeInsets padding,
  required final Widget heading,
  required final Widget description,
  required final Widget setup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: padding,
    children: [
      heading,
      const SizedBox(height: 12),
      description,
      const SizedBox(height: 24),
      setup,
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
