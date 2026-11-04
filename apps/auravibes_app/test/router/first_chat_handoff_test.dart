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
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_access_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart' as riverpod_misc;

import '../data/database/drift/database_test_utils.dart';

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
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    const starter = 'Help me plan my day';
    final chat = NewChatRoute(workspaceId: workspace.id).location;
    final router = GoRouter(
      routes: $appRoutes,
      initialLocation: chat,
      initialExtra: const ChatDraft(text: starter),
    );
    addTearDown(router.dispose);

    final container = _firstChatContainer(
      database: database,
      workspaceId: workspace.id,
      session: session,
      router: router,
      extraOverrides: [
        chatModelConnectionsProvider(workspace.id)
            .overrideWith((ref) => Stream.value([])),
        listModelsGroupedByProviderProvider(workspaceId: workspace.id)
            .overrideWith((ref) => Stream.value({})),
      ],
    );
    addTearDown(container.dispose);
    await _pumpFirstChatApp(
      tester: tester,
      container: container,
      workspaceId: workspace.id,
      router: router,
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
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    final chat = NewChatRoute(workspaceId: workspace.id).location;
    final router = GoRouter(
      routes: $appRoutes,
      initialLocation: chat,
      initialExtra: 'unrelated route state',
    );
    addTearDown(router.dispose);

    final container = _firstChatContainer(
      database: database,
      workspaceId: workspace.id,
      session: session,
      router: router,
      extraOverrides: [
        chatModelConnectionsProvider(workspace.id)
            .overrideWith((ref) => Stream.value([])),
        listModelsGroupedByProviderProvider(workspaceId: workspace.id)
            .overrideWith((ref) => Stream.value({})),
      ],
    );
    addTearDown(container.dispose);
    await _pumpFirstChatApp(
      tester: tester,
      container: container,
      workspaceId: workspace.id,
      router: router,
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
        final session = WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: workspace.id),
        );
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
        final container = _firstChatContainer(
          database: database,
          workspaceId: workspace.id,
          session: session,
          router: router,
          extraOverrides: [
            chatModelConnectionsProvider(
              workspace.id,
            ).overrideWith((ref) => Stream.value([_connection(workspace.id)])),
            listModelsGroupedByProviderProvider(workspaceId: workspace.id)
                .overrideWith(
                  (ref) => Stream.value({
                    'connection': [_model(workspace.id)],
                  }),
                ),
          ],
        );
        addTearDown(container.dispose);
        await _pumpFirstChatApp(
          tester: tester,
          container: container,
          workspaceId: workspace.id,
          router: router,
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

ProviderContainer _firstChatContainer({
  required AppDatabase database,
  required String workspaceId,
  required WorkspaceSession session,
  required GoRouter router,
  required List<riverpod_misc.Override> extraOverrides,
}) => ProviderContainer(
  overrides: [
    appDatabaseProvider.overrideWithValue(database),
    workspaceSessionProvider(session).overrideWithValue(session),
    workspaceSessionForRouteProvider(workspaceId)
        .overrideWith((_) async => session),
    routerProvider.overrideWithValue(router),
    ...extraOverrides,
  ],
  retry: (_, _) => null,
);

Future<void> _pumpFirstChatApp({
  required WidgetTester tester,
  required ProviderContainer container,
  required String workspaceId,
  required GoRouter router,
}) async {
  final _ = await container.read(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final _ = await container.read(workspaceAccessProvider(workspaceId).future);
  await tester.pumpWidget(_FirstChatApp(container: container, router: router));
}

class const _FirstChatApp({
  required final ProviderContainer container,
  required final GoRouter router,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    child: Builder(
      builder: (context) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => AuraThemeScope(
            theme: .light,
            child: AuraLegacyMaterialBridge(
              child: Portal(
                child: AuraSnackBarHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          locale: context.locale,
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            sdk_localizations.GlobalMaterialLocalizations.delegate,
            ...context.localizationDelegates,
          ],
          supportedLocales: context.supportedLocales,
        ),
      ),
    ),
    supportedLocales: const [Locale('en'), Locale('es')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}
