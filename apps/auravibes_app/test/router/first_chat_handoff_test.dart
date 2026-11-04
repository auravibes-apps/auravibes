import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
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

  testWidgets('first-use draft stays editable and unsent without a model', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await clearAppDatabase(database);
    final workspace = await WorkspaceRepository(database)
        .createWorkspace(const .new(name: 'First chat', type: .local));
    const starter = 'Help me plan my day';
    final chat = NewChatRoute(workspaceId: workspace.id).location;
    final router = GoRouter(
      routes: $appRoutes,
      initialLocation: chat,
      initialExtra: const ChatDraft(text: starter),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
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
        ],
        workspaceId: workspace.id,
      ),
    );
    final _ = await tester.pumpAndSettle();

    final input = find.byType(ChatInputWidget);
    final editable = find
        .descendant(of: input, matching: find.byType(EditableText))
        .first;
    expect(tester.widget<EditableText>(editable).controller.text, starter);
    expect(tester.widget<ChatInputWidget>(input).disabled, isTrue);

    await tester.enterText(editable, 'Help me plan an easy first day');
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(editable).controller.text,
      'Help me plan an easy first day',
    );
    expect(
      await database.conversationDao
          .watchConversationsByWorkspace(workspace.id)
          .first,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new chat ignores route extras that are not drafts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await clearAppDatabase(database);
    final workspace = await WorkspaceRepository(database)
        .createWorkspace(const .new(name: 'First chat', type: .local));
    final chat = NewChatRoute(workspaceId: workspace.id).location;
    final router = GoRouter(
      routes: $appRoutes,
      initialLocation: chat,
      initialExtra: 'unrelated route state',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
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
        ],
        workspaceId: workspace.id,
      ),
    );
    final _ = await tester.pumpAndSettle();
    final editable = find
        .descendant(
          of: find.byType(ChatInputWidget),
          matching: find.byType(EditableText),
        )
        .first;
    expect(tester.widget<EditableText>(editable).controller.text, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
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
        await tester.pumpWidget(
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
