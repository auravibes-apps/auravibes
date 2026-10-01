// Required: Tests use numeric fixtures.

import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/models/credential_definition_usage.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/credential_definition_usage_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definition_edit_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _CredentialDefinitionEditHarness({
  required final AppDatabase database,
  required final String workspaceId,
  required final ProviderContainer container,
  required final SkillCredentialDefinitionsRepository repository,
}) {
  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

Future<_CredentialDefinitionEditHarness> _createHarness() async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final workspace = await WorkspaceRepository(database)
      .createWorkspace(const .new(name: 'Test Workspace', type: .local));
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: workspace.id),
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      workspaceSessionProvider(session).overrideWithValue(session),
      cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
      cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
    ],
  );

  return _CredentialDefinitionEditHarness(
    database: database,
    workspaceId: workspace.id,
    container: container,
    repository: .new(database),
  );
}

Future<void> _setSurfaceSize(
  WidgetTester tester, {
  Size size = const Size(1000, 1000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Finder _editableInputAt(int index) => find.descendant(
  of: find.byType(AuraInput).at(index),
  matching: find.byType(EditableText),
);

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen({
    required ProviderContainer container,
    required String workspaceId,
    String? definitionId,
    Widget? home,
    GoRouter? router,
  }) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: router != null
                ? MaterialApp.router(
                    routerConfig: router,
                    builder: (context, child) => AuraSnackBarHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  )
                : MaterialApp(
                    home:
                        home ??
                        SkillCredentialDefinitionEditScreen(
                          workspaceId: workspaceId,
                          definitionId: definitionId,
                        ),
                    builder: (context, child) => AuraSnackBarHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  ),
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  Widget editorLauncher(String workspaceId, {String? definitionId}) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => SkillCredentialDefinitionEditScreen(
                workspaceId: workspaceId,
                definitionId: definitionId,
              ),
            ),
          );
        },
        child: const Text('Open editor'),
      ),
    ),
  );

  testWidgets('usage errors retry without claiming zero dependencies', (
    tester,
  ) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(title: 'Type', attributesJson: '{"token":{}}'),
    );
    var reads = 0;
    final provider = credentialDefinitionUsageProvider(
      harness.workspaceId,
      definition.id,
    );
    final scope = ProviderContainer(
      parent: harness.container,
      overrides: [
        provider.overrideWith((ref) async {
          if (reads++ == 0) throw StateError('Fixture unavailable');

          return const CredentialDefinitionUsage();
        }),
      ],
    );
    addTearDown(scope.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: scope,
          workspaceId: harness.workspaceId,
          definitionId: definition.id,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('Could not load usage'), findsOneWidget);
    expect(
      find.text('No saved credentials, skills or tools use this type.'),
      findsNothing,
    );
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('No saved credentials, skills or tools use this type.'),
      findsOneWidget,
    );
    expect(reads, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('usage links retain schema draft and refresh after return', (
    tester,
  ) async {
    await _setSurfaceSize(tester, size: const Size(1000, 1600));
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Type',
        attributesJson: '{"token":{},"region":{"optional":true}}',
      ),
    );
    final usageProvider = credentialDefinitionUsageProvider(
      harness.workspaceId,
      definition.id,
    );
    var repaired = false;
    var reads = 0;
    final scope = ProviderContainer(
      parent: harness.container,
      overrides: [
        usageProvider.overrideWith((ref) async {
          reads++;

          return repaired
              ? const CredentialDefinitionUsage()
              : const CredentialDefinitionUsage(
                  credentials: [
                    .new(
                      id: 'credential-1',
                      title: 'Saved access',
                      isEnabled: false,
                    ),
                  ],
                  skills: [
                    .new(
                      id: 'skill-1',
                      title: 'Related skill',
                      isEnabled: false,
                    ),
                  ],
                  tools: [
                    .new(
                      id: 'tool-1',
                      title: 'Related tool',
                      isEnabled: false,
                      parentSkillId: 'skill-1',
                    ),
                  ],
                );
        }),
      ],
    );
    addTearDown(scope.dispose);
    final parent = SkillCredentialDefinitionEditRoute(
      workspaceId: harness.workspaceId,
      definitionId: definition.id,
    ).location;
    final targets = [
      ServiceConnectionEditRoute(
        workspaceId: harness.workspaceId,
        connectionId: 'credential-1',
      ).location,
      SkillDetailRoute(
        workspaceId: harness.workspaceId,
        skillId: 'skill-1',
      ).location,
      SkillToolEditRoute(
        workspaceId: harness.workspaceId,
        skillId: 'skill-1',
        toolId: 'tool-1',
      ).location,
    ];
    String? visited;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: parent,
          builder: (_, _) => SkillCredentialDefinitionEditScreen(
            workspaceId: harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
        for (final target in targets)
          GoRoute(
            path: target,
            builder: (context, state) {
              visited = state.uri.path;

              return Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Return to type'),
                ),
              );
            },
          ),
      ],
      initialLocation: parent,
    );
    addTearDown(router.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: scope,
          workspaceId: harness.workspaceId,
          router: router,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('Used by'), findsOneWidget);
    await tester.enterText(_editableInputAt(0), 'Unsaved type');
    await tester.tap(find.byIcon(Icons.arrow_downward).first);
    final _ = await tester.pumpAndSettle();
    final snapshot = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((w) => w.controller.text)
        .toList();
    for (final entry in [
      'Saved access',
      'Related skill',
      'Related tool',
    ].indexed) {
      await tester.tap(find.text(entry.$2));
      final _ = await tester.pumpAndSettle();
      expect(visited, targets[entry.$1]);
      expect(find.text('Return to type'), findsOneWidget);
      if (entry.$1 == 2) repaired = true;
      await tester.tap(find.text('Return to type'));
      final _ = await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, parent);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .map((w) => w.controller.text)
            .toList(),
        snapshot,
      );
    }
    expect(reads, 4);
    expect(
      find.text('No saved credentials, skills or tools use this type.'),
      findsOneWidget,
    );
    expect(
      (await harness.repository.getDefinitionById(definition.id))?.title,
      'Type',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets(
    'new required fields show impact before save and reject the write',
    (tester) async {
      await _setSurfaceSize(tester, size: const Size(1000, 1600));
      final harness = await _createHarness();
      addTearDown(harness.dispose);
      final definition = await harness.repository.createDefinition(
        harness.workspaceId,
        const .new(title: 'Type', attributesJson: '{"token":{}}'),
      );
      final _ = await harness.database.skillCredentialsDao.createCredential(
        .new(
          name: const .new('Saved access'),
          serviceId: .new(definition.id),
          kind: const Value(ServiceConnectionKindTable.skillCredential),
          authenticationType: const Value(
            ServiceAuthenticationTypeTable.apiKey,
          ),
          workspaceId: .new(harness.workspaceId),
        ),
      );
      await tester.runAsync(
        () => tester.pumpWidget(
          buildScreen(
            container: harness.container,
            workspaceId: harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Add attribute'));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(_editableInputAt(3), 'new_field');
      final _ = await tester.pumpAndSettle();
      expect(
        find.text('new_field: now required, including any newly added field.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('These changes cannot be saved'),
        findsOneWidget,
      );
      expect(
        (await harness.repository.getDefinitionById(definition.id))
            ?.attributesJson,
        '{"token":{}}',
      );
      await tester.tap(find.byIcon(Icons.save_outlined));
      final _ = await tester.pumpAndSettle();
      expect(
        (await harness.repository.getDefinitionById(definition.id))
            ?.attributesJson,
        '{"token":{}}',
      );
      expect(find.text('Manage saved credentials'), findsOneWidget);
    },
  );

  testWidgets('creates credential definition from attribute rows', (
    tester,
  ) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(harness.workspaceId),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Create credential type'), findsOneWidget);
    expect(find.text('Attributes JSON'), findsNothing);
    expect(find.text('Add attribute'), findsOneWidget);
    expect(find.text('Secret'), findsOneWidget);

    await tester.enterText(_editableInputAt(0), 'Example Service');
    await tester.enterText(_editableInputAt(1), 'api_key');
    await tester.enterText(_editableInputAt(2), 'API key');
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(_editableInputAt(3), 'user_id');
    await tester.ensureVisible(find.text('Optional').last);
    await tester.tap(find.byType(AuraSwitch).at(2));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraSwitch).at(3));
    final _ = await tester.pumpAndSettle();
    final inputActions = tester
        .widgetList<AuraInput>(find.byType(AuraInput))
        .map((input) => input.textInputAction)
        .toList();
    expect(inputActions, <TextInputAction>[.next, .next, .next, .next, .done]);
    await tester.enterText(_editableInputAt(4), 'User id');
    await tester.testTextInput.receiveAction(.done);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Open editor'), findsOneWidget);
    expect(find.byType(AuraConfirmDialog), findsNothing);

    final definition = await harness.repository.getDefinitionBySlug(
      harness.workspaceId,
      'example_service',
    );
    expect(definition?.attributesJson, contains('"api_key"'));
    expect(definition?.attributesJson, contains('"description":"API key"'));
    expect(definition?.attributesJson, contains('"user_id"'));
    expect(definition?.attributesJson, contains('"optional":true'));
    expect(definition?.attributesJson, contains('"secret":false'));
  });

  testWidgets('keeps or discards unsaved credential definition changes', (
    tester,
  ) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Example Service',
        attributesJson: '{"api_key":{"description":"API key"}}',
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(
            harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    await tester.enterText(_editableInputAt(0), 'Changed Service');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(SkillCredentialDefinitionEditScreen), findsOneWidget);
    expect(find.byType(AuraConfirmDialog), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Open editor'), findsOneWidget);
    final unchanged = await harness.repository.getDefinitionById(definition.id);
    expect(unchanged?.title, 'Example Service');
  });

  testWidgets('ignores empty placeholder but treats attribute order as dirty', (
    tester,
  ) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Example Service',
        attributesJson: '''
          {
            "api_key": {"description": "API key"},
            "user_id": {"description": "User id"}
          }
          ''',
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(
            harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Open editor'), findsOneWidget);

    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_downward).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('persists credential attribute order', (tester) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Example Service',
        attributesJson: '''
          {
            "api_key": {"description": "API key"},
            "user_id": {"description": "User id"}
          }
          ''',
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(
            harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    expect(find.byTooltip('Move attribute up'), findsNWidgets(2));
    expect(find.byTooltip('Move attribute down'), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.arrow_downward).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    final updated = await harness.repository.getDefinitionById(definition.id);
    if (updated == null) fail('Updated definition was not found.');
    final attributes = jsonDecode(updated.attributesJson) as Map;
    expect(attributes.keys, ['user_id', 'api_key']);
  });

  testWidgets('shows required and duplicate variable errors inline', (
    tester,
  ) async {
    await _setSurfaceSize(tester, size: const Size(1000, 1200));
    final harness = await _createHarness();
    addTearDown(harness.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(harness.workspaceId),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    await tester.enterText(_editableInputAt(0), 'Example Service');
    await tester.ensureVisible(find.text('Add attribute'));
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add attribute'));
    await tester.tap(find.text('Add attribute'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(_editableInputAt(3), 'api_key');
    await tester.enterText(_editableInputAt(5), 'api_key');
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Variable is required'), findsOneWidget);
    expect(find.text('Variable must be unique'), findsNWidgets(2));
    expect(find.text('Unable to save credential type'), findsNothing);
    expect(find.byType(SkillCredentialDefinitionEditScreen), findsOneWidget);
    expect(
      await harness.repository.getDefinitionBySlug(
        harness.workspaceId,
        'example_service',
      ),
      isNull,
    );
  });

  testWidgets('copies the exact credential definition slug', (tester) async {
    await _setSurfaceSize(tester);
    final harness = await _createHarness();
    addTearDown(harness.dispose);
    final definition = await harness.repository.createDefinition(
      harness.workspaceId,
      const .new(
        title: 'Example Service',
        attributesJson: '{"api_key":{"description":"API key"}}',
      ),
    );
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        buildScreen(
          container: harness.container,
          workspaceId: harness.workspaceId,
          home: editorLauncher(
            harness.workspaceId,
            definitionId: definition.id,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Open editor'));
    final _ = await tester.pumpAndSettle();

    expect(find.byTooltip('Copy slug'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy_outlined));
    final _ = await tester.pumpAndSettle();

    expect(copiedText, definition.slug);
    expect(find.text('Slug copied'), findsOneWidget);
  });

  testWidgets(
    'keeps definition and explains linked-credential deletion conflict',
    (tester) async {
      await _setSurfaceSize(tester);
      final harness = await _createHarness();
      addTearDown(harness.dispose);
      final definition = await harness.repository.createDefinition(
        harness.workspaceId,
        const .new(
          title: 'Example Service',
          attributesJson: '{"api_key":{"description":"API key"}}',
        ),
      );
      final _ = await harness.database.skillCredentialsDao.createCredential(
        .new(
          name: const .new('Linked'),
          serviceId: .new(definition.id),
          kind: const Value(ServiceConnectionKindTable.skillCredential),
          authenticationType: const Value(
            ServiceAuthenticationTypeTable.apiKey,
          ),
          workspaceId: .new(harness.workspaceId),
          isEnabled: const Value(false),
        ),
      );
      final _ = await tester.runAsync(
        () => tester.pumpWidget(
          buildScreen(
            container: harness.container,
            workspaceId: harness.workspaceId,
            home: editorLauncher(
              harness.workspaceId,
              definitionId: definition.id,
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Open editor'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Used by'), findsOneWidget);
      expect(find.text('Linked'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete credential type'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      final _ = await tester.pumpAndSettle();

      expect(find.textContaining('1 linked credentials'), findsOneWidget);
      expect(find.text('Manage saved credentials'), findsOneWidget);
      expect(find.byType(SkillCredentialDefinitionEditScreen), findsOneWidget);
      expect(
        await harness.repository.getDefinitionById(definition.id),
        isNotNull,
      );
    },
  );
}
