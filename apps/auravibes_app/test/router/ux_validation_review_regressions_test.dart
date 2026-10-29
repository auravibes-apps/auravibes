import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ux_validation_fixture.dart';

void main() {
  tearDownAll(UxValidationFixture.closeDatabase);
  testWidgets('ordinary Markdown Close and Apply retain dirty owning agent', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final parent = AgentDetailRoute(
      workspaceId: f.workspaceId,
      agentId: f.agentId,
    ).location;
    final original = await AgentsRepository(f.database).getAgentById(f.agentId);
    final router = await f.pump(tester, parent, size: const Size(1280, 1600));
    await tester.enterText(
      find.byType(AuraInput).first,
      'Retained parent draft',
    );
    await tester.ensureVisible(find.text('Edit prompt'));
    await tester.tap(find.text('Edit prompt'));
    await f.settle(tester);
    await tester.tap(find.byIcon(Icons.close));
    await f.settle(tester);
    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(find.text('Keep editing'), findsNothing);
    expect(find.text('Retained parent draft'), findsOneWidget);
    await tester.tap(find.text('Edit prompt'));
    await f.settle(tester);
    await tester.enterText(find.byType(TextFormField), 'Applied nested draft');
    await tester.tap(find.text('Apply'));
    await f.settle(tester);
    expect(find.byType(MarkdownEditorScreen), findsNothing);
    expect(find.text('Keep editing'), findsNothing);
    expect(find.text('Retained parent draft'), findsOneWidget);
    expect(router.state.uri.toString(), parent);
    await tester.tap(find.text('Connections').first);
    await f.settle(tester);
    expect(find.text('Discard'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await f.settle(tester);
    await tester.ensureVisible(find.text('Edit prompt'));
    await tester.tap(find.text('Edit prompt'));
    await f.settle(tester);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      'Applied nested draft',
    );
    expect(
      await AgentsRepository(f.database).getAgentById(f.agentId),
      original,
    );
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  for (final drafts in [
    (parent: false, editor: true),
    (parent: true, editor: true),
    (parent: true, editor: false),
  ]) {
    final parentDirty = drafts.parent;
    for (final workspaceSwitch in [false, true]) {
      final title =
          'actual ${drafts.editor ? 'dirty' : 'clean'} Markdown guards '
          '${workspaceSwitch ? 'workspace' : 'sidebar'} '
          'exit with ${parentDirty ? 'dirty' : 'clean'} parent';
      testWidgets(title, (tester) async {
        final f = await UxValidationFixture.create();
        final second = await WorkspaceRepository(
          f.database,
        ).createWorkspace(const .new(name: 'Second workspace', type: .local));
        final initial = AgentDetailRoute(
          workspaceId: f.workspaceId,
          agentId: f.agentId,
        ).location;
        final original = await AgentsRepository(f.database)
            .getAgentById(f.agentId);
        final router = await f.pump(
          tester,
          initial,
          size: const Size(1280, 1600),
          realSessions: true,
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AgentDetailScreen)),
          listen: false,
        );
        final selection = container.read(
          lastWorkspaceSelectionRepositoryProvider,
        );
        await tester.runAsync(() => selection.save(f.workspaceId));
        if (parentDirty) {
          await tester.enterText(
            find.byType(AuraInput).first,
            'Unsaved parent name',
          );
        }
        await tester.ensureVisible(find.text('Edit prompt'));
        await tester.tap(find.text('Edit prompt'));
        await f.settle(tester);
        final draft = drafts.editor
            ? 'Exact nested unsaved Markdown'
            : tester
                  .widget<TextFormField>(find.byType(TextFormField))
                  .controller
                  ?.text;
        if (drafts.editor) {
          await tester.enterText(
            find.byType(TextFormField),
            'Exact nested unsaved Markdown',
          );
        }
        await f.settle(tester);
        Future<void> leave() async {
          if (workspaceSwitch) {
            await tester.tap(
              find.byKey(const ValueKey<String>('workspace_choice')),
            );
            await f.settle(tester);
            await tester.tap(find.text('Second workspace / Local').last);
          } else {
            await tester.tap(find.text('Connections').first);
          }
          await f.settle(tester);
        }

        await leave();
        expect(await tester.runAsync(selection.read), f.workspaceId);
        expect(router.state.uri.toString(), initial);
        expect(find.text('Keep editing'), findsOneWidget);
        expect(find.byType(MarkdownEditorScreen), findsOneWidget);
        await tester.tap(find.text('Keep editing'));
        await f.settle(tester);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller
              ?.text,
          draft,
        );
        expect(router.state.uri.toString(), initial);
        await leave();
        final discard = drafts.editor ? 'Discard changes' : 'Discard';
        expect(find.text(discard), findsOneWidget);
        await tester.tap(find.text(discard));
        await f.settle(tester);
        expect(find.byType(MarkdownEditorScreen), findsNothing);
        expect(find.text('Keep editing'), findsNothing);
        expect(
          router.state.uri.toString(),
          workspaceSwitch
              ? NewChatRoute(workspaceId: second.id).location
              : FeatureDestinations.masterLocation(
                  ServiceConnectionsRoute(workspaceId: f.workspaceId).location,
                ),
        );
        expect(
          await tester.runAsync(selection.read),
          workspaceSwitch ? second.id : f.workspaceId,
        );
        expect(
          await AgentsRepository(f.database).getAgentById(f.agentId),
          original,
        );
        expect(tester.takeException(), isNull);
        await f.close(tester);
      });
    }
  }
}
