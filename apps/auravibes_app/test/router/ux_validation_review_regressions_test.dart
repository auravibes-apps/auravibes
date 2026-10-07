import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/skills/models/app_skill_credential_candidate.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ux_validation_fixture.dart';

void main() {
  tearDownAll(UxValidationFixture.closeDatabase);
  for (final skill in ['anthropic', 'codex', 'jina']) {
    testWidgets(
      'actual app skill $skill recovery opens usable credential form',
      (tester) async {
        final f = await UxValidationFixture.create();
        final _ = await f.database.apiModelProvidersDao.upsertProvider(
          .insert(
            id: 'anthropic',
            name: 'Anthropic',
            type: const Value(.anthropic),
          ),
        );
        final _ = await f.database.apiModelProvidersDao.upsertProvider(
          .insert(id: 'openai', name: 'OpenAI', type: const Value(.openai)),
        );
        await tester.runAsync(_cacheProviderLogos);
        addTearDown(svg.cache.clear);
        final parent = SkillDetailRoute(
          workspaceId: f.workspaceId,
          skillId: skill,
        ).location;
        final router = await f.pump(
          tester,
          parent,
          size: const Size(1280, 1800),
        );
        if (skill == 'jina') {
          final container = ProviderScope.containerOf(
            tester.element(find.byType(SkillDetailScreen)),
            listen: false,
          );
          final summary = await container.read(
            skillAccessSummaryProvider(f.workspaceId, skill).future,
          );
          expect(summary?.instructionsAvailable, isTrue);
          expect(summary?.status.name, 'partial');
          expect(
            summary?.tools.any((tool) => tool.status.name == 'available'),
            isTrue,
          );
          expect(
            find.text('Instructions available; access setup incomplete'),
            findsOneWidget,
          );
          expect(
            find.text('This skill needs a credential before it can be loaded.'),
            findsNothing,
          );
          expect(find.text('Add Credential'), findsOneWidget);
        }
        await tester.ensureVisible(find.text('Set up credentials'));
        await tester.tap(find.text('Set up credentials'));
        await f.settle(tester);
        expect(find.byType(ServiceConnectionCreateScreen), findsOneWidget);
        final destination = tester.widget<ServiceConnectionCreateScreen>(
          find.byType(ServiceConnectionCreateScreen),
        );
        if (skill == 'jina') {
          expect(destination.initialAppSkillId, 'jina');
          expect(find.byType(AddModelProviderWidget), findsNothing);
          expect(find.text('API key'), findsOneWidget);
          expect(
            find.byWidgetPredicate((widget) => widget is AuraInput),
            findsNWidgets(2),
          );
        } else {
          expect(find.byType(AddModelProviderWidget), findsOneWidget);
          expect(destination.initialAppSkillId, isNull);
          await tester.tap(
            find.text(skill == 'codex' ? 'OpenAI Codex' : 'Anthropic').last,
          );
          await f.settle(tester);
          if (skill == 'codex') {
            expect(find.text('Use device code'), findsOneWidget);
            expect(
              find.textContaining('Browser sign-in requires'),
              findsOneWidget,
            );
          } else {
            expect(find.text('Verify connection'), findsOneWidget);
            expect(
              find.byWidgetPredicate((widget) => widget is AuraInput),
              findsNWidgets(2),
            );
          }
        }
        router.pop();
        await f.settle(tester);
        if (find.text('Discard changes').evaluate().isNotEmpty) {
          await tester.tap(find.text('Discard changes'));
          await f.settle(tester);
        }
        expect(find.byType(SkillDetailScreen), findsOneWidget);
        expect(router.state.uri.toString(), parent);
        expect(find.text('Set up credentials'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await f.close(tester);
      },
    );
  }

  for (final failed in [false, true]) {
    testWidgets(
      'actual Jina credential ${failed ? 'error' : 'count'} stays explicit',
      (tester) async {
        final f = await UxValidationFixture.create();
        final _ = await f.pump(
          tester,
          SkillDetailRoute(
            workspaceId: f.workspaceId,
            skillId: 'jina',
          ).location,
          size: const Size(1280, 1800),
          overrides: [
            appSkillCredentialCandidatesProvider(
              f.workspaceId,
              'jina',
            ).overrideWith((_) async {
              if (failed) {
                throw StateError('Controlled credential lookup failure');
              }

              return const [
                AppSkillCredentialCandidate(
                  id: 'saved-credential',
                  name: 'Saved access',
                ),
              ];
            }),
          ],
        );
        expect(
          find.text(
            failed ? 'Error loading credentials' : '1 credential configured',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            failed ? 'Access status unknown' : 'Saved access available',
          ),
          findsWidgets,
        );
        expect(
          find.text('This skill needs a credential before it can be loaded.'),
          findsNothing,
        );
        if (failed) expect(find.text('Add Credential'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await f.close(tester);
      },
    );
  }

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
    await tester.tap(find.byTooltip('Apply changes'));
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
              : ServiceConnectionsRoute(workspaceId: f.workspaceId).location,
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

Future<void> _cacheProviderLogos() async {
  final bytes = await const SvgStringLoader(
    '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20">'
    ' <circle cx="10" cy="10" r="8"/></svg>',
  ).loadBytes(null);
  for (final id in ['anthropic', 'openai', 'openai-codex']) {
    final loader = SvgNetworkLoader('https://models.dev/logos/$id.svg');
    final _ = await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () async => bytes,
    );
  }
}
