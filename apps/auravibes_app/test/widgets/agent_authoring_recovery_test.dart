import 'dart:async';

import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/screens/agent_detail_screen.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_resources_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart'
    as app;
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_editor.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ux_capture.dart';
import '../helpers/ux_validation_fixture.dart';

void main() {
  setUpAll(loadUxCaptureFonts);
  tearDownAll(UxValidationFixture.closeDatabase);
  for (final scenario in const [
    (
      name: 'agent-editor-skills-failure',
      route: 'AgentDetailRoute',
      tools: false,
    ),
    (
      name: 'agent-editor-tools-failure',
      route: 'AgentDetailRoute',
      tools: true,
    ),
    (name: 'skills-list-failure', route: 'SkillsRoute', tools: false),
  ]) {
    testWidgets('${scenario.name} can retry', (tester) async {
      final fixture = await UxValidationFixture.create();
      final route = _recoveryRoute(scenario.route, fixture);
      var fails = true;
      const size = Size(466, 678);
      final router = await fixture.pump(
        tester,
        route,
        size: size,
        overrides: [
          if (scenario.tools)
            workspaceToolsProvider(fixture.workspaceId)
                .overrideWith(() => _ControlledTools(() => fails))
          else
            workspaceSkillsProvider(fixture.workspaceId)
                .overrideWith((_) async {
                  if (fails) throw StateError('Controlled skills load failure');

                  return [];
                }),
        ],
      );
      await captureUxWidget(
        tester,
        scenario.name,
        router.routeInformationProvider.value.uri.toString(),
        locale: 'en',
        size: size,
        scale: 1,
        dark: false,
        fixture: scenario.tools
            ? 'Persisted local workspace with a controlled tools load failure'
            : 'Persisted local workspace with a controlled skills load failure',
      );
      expect(
        find.text(
          scenario.tools
              ? 'Could not load tools. Try again.'
              : 'Could not load skills. Try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      fails = false;
      await tester.tap(find.text('Retry'));
      await fixture.settle(tester);
      expect(
        find.text(
          scenario.route == 'SkillsRoute'
              ? 'No skills available'
              : 'Agent details',
        ),
        findsOneWidget,
      );
      if (scenario.route == 'AgentDetailRoute') {
        await tester.enterText(find.byType(AuraInput).first, 'Unsaved draft');
        fails = true;
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AgentDetailScreen)),
        );
        if (scenario.tools) {
          container.invalidate(workspaceToolsProvider(fixture.workspaceId));
        } else {
          container.invalidate(workspaceSkillsProvider(fixture.workspaceId));
        }
        await fixture.settle(tester);
        expect(find.text('Retry'), findsOneWidget);
        fails = false;
        await tester.tap(find.text('Retry'));
        await fixture.settle(tester);
        expect(find.text('Unsaved draft'), findsOneWidget);
      }
      await fixture.close(tester);
    });
  }
  testWidgets('skill-resources-list-failure can retry', (tester) async {
    final fixture = await UxValidationFixture.create();
    final resources = await SkillResourcesRepository(fixture.database)
        .getSkillResources(fixture.skillId);
    var fails = true;
    const size = Size(466, 678);
    final router = await fixture.pump(
      tester,
      _recoveryRoute('SkillDetailRoute', fixture),
      size: size,
      overrides: [
        skillResourcesProvider(
          fixture.workspaceId,
          fixture.skillId,
        ).overrideWith((_) async {
          if (fails) throw StateError('Controlled resources load failure');

          return resources;
        }),
      ],
    );
    await tester.scrollUntilVisible(
      find.textContaining('Could not load'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(
      find
          .descendant(
            of: find.byType(SkillDetailScreen),
            matching: find.byType(ListView),
          )
          .first,
      const Offset(0, -300),
    );
    final _ = await tester.pumpAndSettle();
    await captureUxWidget(
      tester,
      'skill-resources-list-failure',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'en',
      size: size,
      scale: 1,
      dark: false,
      fixture:
          'Persisted local workspace with a controlled skill resources '
          'list failure',
    );
    expect(find.text('Retry').hitTestable(), findsOneWidget);
    fails = false;
    await tester.tap(find.text('Retry'));
    await fixture.settle(tester);
    expect(find.text('Writing guide'), findsOneWidget);
    await fixture.close(tester);
  });
  testWidgets('agent editor retries simultaneous dependency failures', (
    tester,
  ) async {
    final fixture = await UxValidationFixture.create();
    var fails = true;
    final _ = await fixture.pump(
      tester,
      _recoveryRoute('AgentDetailRoute', fixture),
      overrides: [
        workspaceSkillsProvider(fixture.workspaceId).overrideWith((_) async {
          if (fails) throw StateError('Controlled skills load failure');

          return [];
        }),
        workspaceToolsProvider(fixture.workspaceId)
            .overrideWith(() => _ControlledTools(() => fails)),
      ],
    );
    expect(
      find.text('Could not load skills or tools. Try again.'),
      findsOneWidget,
    );
    fails = false;
    await tester.tap(find.text('Retry'));
    await fixture.settle(tester);
    expect(find.text('Agent details'), findsOneWidget);
    await fixture.close(tester);
  });
  testWidgets('agent recovery remains readable in Spanish at large text', (
    tester,
  ) async {
    final fixture = await UxValidationFixture.create();
    var fails = true;
    const size = Size(360, 678);
    final router = await fixture.pump(
      tester,
      _recoveryRoute('AgentDetailRoute', fixture),
      size: size,
      locale: 'es',
      scale: 1.4,
      dark: true,
      overrides: [
        workspaceSkillsProvider(fixture.workspaceId).overrideWith((_) async {
          if (fails) throw StateError('Controlled skills load failure');

          return [];
        }),
      ],
    );
    final message = find.textContaining(
      'No se pudieron cargar las habilidades.',
    );
    expect(message, findsOneWidget);
    final bounds = tester.getRect(message);
    expect(bounds.left, greaterThanOrEqualTo(12));
    expect(bounds.right, lessThanOrEqualTo(size.width - 12));
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureUxWidget(
      tester,
      'agent-editor-skills-failure-es-large-dark',
      router.routeInformationProvider.value.uri.toString(),
      locale: 'es',
      size: size,
      scale: 1.4,
      dark: true,
      fixture:
          'Persisted local workspace with a controlled skills load failure',
    );
    fails = false;
    await tester.tap(find.text('Reintentar'));
    await fixture.settle(tester);
    expect(find.text('Detalles del agente'), findsOneWidget);
    await fixture.close(tester);
  });
  for (final failure in ['tools', 'connections']) {
    testWidgets('connected-editor-$failure-failure can retry', (tester) async {
      final fixture = await UxValidationFixture.create();
      final connector = connectorDefinitions.singleWhere(
        (value) => value.identifier == 'brave',
      );
      final tool = connector.tools.firstWhere(
        (value) => value.slug == 'web_search',
      );
      final toolId = connectorToolId(connector, tool);
      final now = DateTime.utc(2026);
      final configuredTools = [
        WorkspaceToolEntity(
          id: 'fixture-tool',
          workspaceId: fixture.workspaceId,
          toolId: toolId,
          isEnabled: true,
          permissionMode: .alwaysAsk,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      var fails = true;
      var available = true;
      var cancelled = false;
      const size = Size(466, 678);
      final router = await fixture.pump(
        tester,
        WorkspaceRoute(workspaceId: fixture.workspaceId).location,
        size: size,
        overrides: [
          workspaceToolsProvider(fixture.workspaceId).overrideWith(
            () => _ControlledTools(
              () => failure == 'tools' && fails,
              values: configuredTools,
            ),
          ),
          workspaceConnectedConnectionsProvider(
            fixture.workspaceId,
            'brave',
          ).overrideWith((_) async {
            if (failure == 'connections' && fails) {
              throw StateError('Controlled connections load failure');
            }

            return available
                ? [
                    const ConnectorConnectionCandidate(
                      id: 'fixture-connection',
                      name: 'Research connection',
                    ),
                  ]
                : [];
          }),
        ],
      );
      final view = app.WorkspaceView.connectedDraft(name: 'Research')
          .withConnected(
            .new(
              toolId: toolId,
              revision: '1',
              inputs: const {},
              connectionId: 'fixture-connection',
            ),
          );
      final context = tester.element(find.byType(AppScreen).first);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            child: SizedBox(
              height: 500,
              child: WorkspaceConnectedEditor(
                workspaceId: fixture.workspaceId,
                view: view,
                onDone: () => cancelled = true,
              ),
            ),
          ),
        ),
      );
      await fixture.settle(tester);
      await captureUxWidget(
        tester,
        'connected-editor-$failure-failure',
        router.routeInformationProvider.value.uri.toString(),
        locale: 'en',
        size: size,
        scale: 1,
        dark: false,
        fixture:
            'Connected data editor in a test dialog with a controlled '
            'load failure',
      );
      expect(
        find.text(
          failure == 'tools'
              ? 'Could not load tools. Try again.'
              : 'Could not load Connections. Try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      if (failure == 'tools') {
        await tester.tap(find.text('Cancel'));
        expect(cancelled, isTrue);
      }
      final save = find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_connected_save',
      );
      if (failure == 'connections') {
        expect(tester.widget<AuraButton>(save).disabled, isTrue);
      }
      fails = false;
      await tester.tap(find.text('Retry'));
      await fixture.settle(tester);
      expect(find.text('Connection'), findsOneWidget);
      expect(tester.widget<AuraButton>(save).disabled, isFalse);
      available = false;
      ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceConnectedEditor)),
      ).invalidate(
        workspaceConnectedConnectionsProvider(fixture.workspaceId, 'brave'),
      );
      await fixture.settle(tester);
      expect(tester.widget<AuraButton>(save).disabled, isTrue);
      await fixture.close(tester);
    });
  }
  for (final scenario in const [
    (name: 'skill-detail-failure', route: 'SkillDetailRoute', parent: true),
    (
      name: 'skill-resource-parent-failure',
      route: 'SkillResourceEditRoute',
      parent: true,
    ),
    (
      name: 'skill-resource-failure',
      route: 'SkillResourceEditRoute',
      parent: false,
    ),
  ]) {
    testWidgets('${scenario.name} can retry', (tester) async {
      final fixture = await UxValidationFixture.create();
      final skill = await SkillsRepository(fixture.database)
          .getSkillById(fixture.skillId);
      final resource = await SkillResourcesRepository(fixture.database)
          .getResourceById(fixture.resourceId);
      if (skill == null || resource == null) {
        throw StateError('Missing fixture');
      }
      var fails = true;
      const size = Size(466, 678);
      final router = await fixture.pump(
        tester,
        _recoveryRoute(scenario.route, fixture),
        size: size,
        overrides: [
          if (scenario.parent)
            skillDetailProvider(
              fixture.workspaceId,
              fixture.skillId,
            ).overrideWith((_) async {
              if (fails) throw StateError('Controlled skill load failure');

              return SkillDetail.fromUserSkill(skill);
            })
          else
            skillResourceProvider(
              fixture.workspaceId,
              fixture.resourceId,
            ).overrideWith((_) async {
              if (fails) throw StateError('Controlled resource load failure');

              return resource;
            }),
        ],
      );
      await captureUxWidget(
        tester,
        scenario.name,
        router.routeInformationProvider.value.uri.toString(),
        locale: 'en',
        size: size,
        scale: 1,
        dark: false,
        fixture: scenario.parent
            ? 'Persisted local workspace with a controlled skill detail '
                  'load failure'
            : 'Persisted local workspace with a controlled skill resource '
                  'load failure',
      );
      expect(find.text('Retry'), findsOneWidget);
      fails = false;
      await tester.tap(find.text('Retry'));
      await fixture.settle(tester);
      expect(
        find.text(
          scenario.route == 'SkillDetailRoute'
              ? 'Research notes'
              : 'Writing guide',
        ),
        findsWidgets,
      );
      await tester.enterText(
        find.byType(AuraInput).first,
        'Unsaved skill draft',
      );
      fails = true;
      final container = ProviderScope.containerOf(
        tester.element(
          find.byType(
            scenario.route == 'SkillDetailRoute'
                ? SkillDetailScreen
                : SkillResourceEditScreen,
          ),
        ),
      );
      if (scenario.parent) {
        container.invalidate(
          skillDetailProvider(fixture.workspaceId, fixture.skillId),
        );
      } else {
        container.invalidate(
          skillResourceProvider(fixture.workspaceId, fixture.resourceId),
        );
      }
      await fixture.settle(tester);
      expect(find.text('Retry'), findsOneWidget);
      fails = false;
      await tester.tap(find.text('Retry'));
      await fixture.settle(tester);
      expect(find.text('Unsaved skill draft'), findsOneWidget);
      await fixture.close(tester);
    });
  }
}

String _recoveryRoute(String name, UxValidationFixture fixture) =>
    switch (name) {
      'AgentDetailRoute' => AgentDetailRoute(
        workspaceId: fixture.workspaceId,
        agentId: fixture.agentId,
      ).location,
      'SkillsRoute' => SkillsRoute(workspaceId: fixture.workspaceId).location,
      'SkillDetailRoute' => SkillDetailRoute(
        workspaceId: fixture.workspaceId,
        skillId: fixture.skillId,
      ).location,
      'SkillResourceEditRoute' => SkillResourceEditRoute(
        workspaceId: fixture.workspaceId,
        skillId: fixture.skillId,
        resourceId: fixture.resourceId,
      ).location,
      _ => throw ArgumentError.value(name, 'name'),
    };

class _ControlledTools(
  final bool Function() fails, {
  final List<WorkspaceToolEntity> values = const [],
}) extends WorkspaceToolsNotifier {
  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async {
    if (fails()) throw StateError('Controlled tools load failure');

    return values;
  }
}
