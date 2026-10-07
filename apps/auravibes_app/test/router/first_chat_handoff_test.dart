import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database/drift/database_test_utils.dart';
import '../helpers/test_app.dart';

void main() {
  final database = AppDatabase(connection: NativeDatabase.memory());
  tearDownAll(database.close);
  testWidgets('pushed credential returns true and retains parent draft', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await clearAppDatabase(database);
    final workspace = await WorkspaceRepository(database)
        .createWorkspace(const .new(name: 'Credential parent', type: .local));
    final definition = await SkillCredentialDefinitionsRepository(database)
        .createDefinition(
          workspace.id,
          const .new(
            title: 'Test type',
            attributesJson: '{"secret":{"description":"Key"}}',
          ),
        );
    final chat = NewChatRoute(workspaceId: workspace.id).location;
    final router = GoRouter(routes: $appRoutes, initialLocation: chat);
    addTearDown(router.dispose);
    SkillCredentialToCreate? created;
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: AuraThemeScope(
            theme: .light,
            child: Portal(child: Router.withConfig(config: router)),
          ),
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            routerProvider.overrideWithValue(router),
            chatModelConnectionsProvider(workspace.id)
                .overrideWith((ref) => Stream.value([])),
            listModelsGroupedByProviderProvider(workspaceId: workspace.id)
                .overrideWith((ref) => Stream.value({})),
            skillCredentialOperationsProvider(workspace.id).overrideWithValue(
              .new(
                create: (workspaceId, value) async {
                  expect(workspaceId, workspace.id);
                  created = value;

                  return .new(
                    id: 'created-credential',
                    workspaceId: workspaceId,
                    credentialDefinitionId: value.credentialDefinitionId,
                    name: value.name,
                    attributes: value.attributes,
                    isEnabled: true,
                    createdAt: .new(2026),
                    updatedAt: .new(2026),
                  );
                },
                getForEdit: (_) => throw UnimplementedError(),
                update: (_, _) => throw UnimplementedError(),
                delete: (_) => throw UnimplementedError(),
              ),
            ),
          ],
          workspaceId: workspace.id,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(ChatInputWidget),
            matching: find.byType(EditableText),
          )
          .first,
      'Retain the parent draft',
    );
    final result = ServiceConnectionCreateRoute(
      workspaceId: workspace.id,
      type: 'skillCredential',
      credentialDefinitionId: definition.id,
    ).push<bool>(tester.element(find.byType(NewChatScreen)));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Test type'), findsOneWidget);
    await tester.enterText(find.byType(AuraInput).first, 'Created connection');
    await tester.enterText(find.byType(AuraInput).last, 'fixture-secret');
    await tester.tap(find.text('Save'));
    final _ = await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(created?.credentialDefinitionId, definition.id);
    expect(created?.name, 'Created connection');
    expect(find.text('Retain the parent draft'), findsOneWidget);
    expect(find.text('Continue to chat'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, chat);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  for (final action in ['save', 'cancel']) {
    for (final direct in [false, true]) {
      testWidgets('first chat $action returns to real chat direct=$direct', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await clearAppDatabase(database);
        final workspace = await WorkspaceRepository(database)
            .createWorkspace(const .new(name: 'Handoff', type: .local));
        final chat = NewChatRoute(workspaceId: workspace.id).location;
        final setup = ServiceConnectionCreateRoute(
          workspaceId: workspace.id,
          returnPath: chat,
          type: 'modelProvider',
        );
        final router = GoRouter(
          routes: $appRoutes,
          initialLocation: direct ? setup.location : chat,
        );
        addTearDown(router.dispose);
        await tester.runAsync(
          () => tester.pumpWidget(
            TestableApp(
              child: AuraThemeScope(
                theme: .light,
                child: Portal(child: Router.withConfig(config: router)),
              ),
              overrides: [
                appDatabaseProvider.overrideWithValue(database),
                routerProvider.overrideWithValue(router),
                chatModelConnectionsProvider(workspace.id).overrideWith(
                  (ref) => Stream.value([_connection(workspace.id)]),
                ),
                listModelsGroupedByProviderProvider(workspaceId: workspace.id)
                    .overrideWith(
                      (ref) => Stream.value({
                        'connection': [_model(workspace.id)],
                      }),
                    ),
              ],
              workspaceId: workspace.id,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        if (!direct) {
          await tester.enterText(
            find
                .descendant(
                  of: find.byType(ChatInputWidget),
                  matching: find.byType(EditableText),
                )
                .first,
            'Keep my draft',
          );
          unawaited(
            setup.push<void>(tester.element(find.byType(NewChatScreen))),
          );
          final _ = await tester.pumpAndSettle();
        }
        if (action == 'save') {
          tester
              .widget<AddModelProviderWidget>(
                find.byType(AddModelProviderWidget),
              )
              .onCreated
              ?.call();
          final _ = await tester.pumpAndSettle();
          expect(find.text('Connection saved'), findsWidgets);
          expect(find.text('Ready to chat'), findsNothing);
          expect(
            find.text('Continue to chat to choose a model.'),
            findsOneWidget,
          );
          expect(find.text('Use the model selector below.'), findsNothing);
          await tester.tap(find.text('Continue to chat'));
        } else {
          await tester.tap(find.byIcon(Icons.arrow_back).last);
        }
        final _ = await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, chat);
        expect(find.byType(NewChatScreen), findsOneWidget);
        expect(find.text('Use the model selector below.'), findsOneWidget);
        expect(find.text('Continue to chat to choose a model.'), findsNothing);
        if (!direct) expect(find.text('Keep my draft'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 10));
      });
    }
  }
}

ModelConnectionEntity _connection(String workspaceId) => .new(
  id: 'connection',
  name: 'Provider',
  modelId: 'openai',
  createdAt: .new(2026),
  updatedAt: .new(2026),
  workspaceId: workspaceId,
  hasKey: true,
);
WorkspaceModelSelectionWithConnectionEntity _model(String workspaceId) => .new(
  workspaceModelSelection: .new(
    id: 'model',
    modelId: 'test',
    modelConnectionId: 'connection',
    createdAt: .new(2026),
    updatedAt: .new(2026),
  ),
  modelConnection: _connection(workspaceId),
  modelsProvider: const .new(id: 'openai', name: 'OpenAI', type: .openai),
);
