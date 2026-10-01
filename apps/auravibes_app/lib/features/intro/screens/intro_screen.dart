import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_setup_content.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

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
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24)
                .copyWith(bottom: BottomPadding.of(context, minimum: 24)),
            children: [
              AuraText(
                child: TextLocale(
                  _createdWorkspace == null
                      ? 'intro_flow.welcome.title'
                      : 'intro_flow.ready.title',
                ),
                style: .heading3,
              ),
              const SizedBox(height: 12),
              TextLocale(
                _createdWorkspace == null
                    ? 'intro_flow.choice.body'
                    : 'intro_flow.ready.body',
              ),
              const SizedBox(height: 24),
              if (_createdWorkspace case final workspace?) ...[
                Text(workspace.name),
                AuraButton(
                  onPressed: () => ServiceConnectionCreateRoute(
                    workspaceId: workspace.id,
                    returnPath: NewChatRoute(workspaceId: workspace.id)
                        .location,
                    type: 'modelProvider',
                  ).go(context),
                  child: const TextLocale('intro_flow.connect_primary'),
                  key: const Key('intro_connect_ai_button'),
                ),
                AuraButton(
                  onPressed: () =>
                      NewChatRoute(workspaceId: workspace.id).go(context),
                  child: const TextLocale('intro_flow.connect_skip'),
                  key: const Key('intro_skip_ai_button'),
                  variant: .outlined,
                ),
              ] else
                WorkspaceSetupContent(
                  taskId: 'intro',
                  onCreated: (workspace) =>
                      setState(() => _createdWorkspace = workspace),
                ),
            ],
          ),
        ),
      ),
    ),
    variant: .aurora,
  );
}
