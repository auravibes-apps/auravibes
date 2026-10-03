import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _LoadingConversation extends ConversationChatNotifier {
  @override
  Future<ConversationResult> build(String workspaceId, String conversationId) =>
      Completer<ConversationResult>().future;
}

class _Selection implements WorkspaceSelectionRepository {
  String? selected;
  @override
  Future<String?> read() async => selected;
  @override
  Future<void> save(String id) async {
    selected = id;
  }

  @override
  Future<void> clearIfMatches(String id) async {
    if (selected == id) selected = null;
  }
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router,
  ProviderContainer container,
) async {
  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (_, child) => AuraLegacyMaterialBridge(
                child: AuraSnackBarHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        startLocale: const Locale('en'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets(
    'failed workspace gate can choose a healthy workspace outside the '
    'failed session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final repository = WorkspaceRepository(database);
      final broken = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Broken workspace', type: .local),
      );
      final healthy = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Healthy workspace', type: .local),
      );
      final selection = _Selection()..selected = broken.id;
      final session = WorkspaceSession(
        LocalWorkspaceRef(localWorkspaceId: healthy.id),
      );
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: WorkspaceManagementRoute(workspaceId: broken.id)
            .location,
      );
      addTearDown(router.dispose);
      final attempts = <Completer<WorkspaceSession>>[];
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          routerProvider.overrideWithValue(router),
          lastWorkspaceSelectionRepositoryProvider.overrideWithValue(selection),
          cloudAccountsProvider.overrideWith((_) async => const []),
          workspaceSessionForRouteProvider(broken.id).overrideWith((_) {
            final attempt = Completer<WorkspaceSession>();
            attempts.add(attempt);

            return attempt.future;
          }),
          workspaceSessionForRouteProvider(healthy.id)
              .overrideWith((_) async => session),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      expect(find.text('Opening workspace...'), findsOneWidget);
      attempts.firstOrNull?.completeError(StateError('token=do-not-display'));
      final _ = await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not open this workspace. Retry or choose another workspace.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('do-not-display'), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Opening workspace...'), findsOneWidget);
      expect(attempts.length, 2);
      attempts.last.completeError(StateError('Second failure'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Choose workspace'));
      final _ = await tester.pumpAndSettle();
      expect(find.byType(WorkspaceManagementScreen), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey<String>('workspace_select_${healthy.id}')),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();
      expect(selection.selected, healthy.id);
      expect(
        router.state.uri.path,
        WorkspaceManagementRoute(workspaceId: healthy.id).location,
      );
      expect(
        find.text(
          'Could not open this workspace. Retry or choose another workspace.',
        ),
        findsNothing,
      );
      expect(find.text('Healthy workspace'), findsWidgets);
      expect(
        find.byType(WorkspaceManagementScreen, skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'child gate shows loading, retries errors and returns to the same parent',
    (tester) async {
      final route = SubAgentConversationRoute(
        workspaceId: 'workspace',
        chatId: 'parent',
        subAgentConversationId: 'child',
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/child', builder: route.build),
          GoRoute(
            path: ConversationRoute(
              workspaceId: 'workspace',
              chatId: 'parent',
            ).location,
            builder: (_, _) => const Text('Parent destination'),
          ),
        ],
        initialLocation: '/child',
      );
      addTearDown(router.dispose);
      final streams = <StreamController<ConversationEntity?>>[];
      final container = ProviderContainer(
        overrides: [
          conversationByIdStreamProvider(
            'workspace',
            conversationId: 'child',
          ).overrideWith((ref) {
            final stream = StreamController<ConversationEntity?>();
            streams.add(stream);
            final _ = ref.onDispose(() => unawaited(stream.close()));

            return stream.stream;
          }),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      expect(find.text('Opening child conversation...'), findsOneWidget);
      streams.firstOrNull?.addError(StateError('secret=hidden'));
      final _ = await tester.pumpAndSettle();
      expect(
        find.text('Could not load this child conversation.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret=hidden'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(streams.length, 2);
      expect(find.text('Opening child conversation...'), findsOneWidget);
      streams.last.add(null);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Conversation not found'), findsOneWidget);
      await tester.tap(find.text('Return to parent conversation'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Parent destination'), findsOneWidget);
      expect(router.state.uri.path, '/workspaces/workspace/chats/parent');
    },
  );

  for (final mismatch in ['workspace', 'parent', 'child', 'none']) {
    final name =
        'child identity validates $mismatch and preserves a read-only '
        'matching run';
    testWidgets(name, (tester) async {
      final child = ConversationEntity(
        id: mismatch == 'child' ? 'different' : 'child',
        title: 'Child run',
        workspaceId: mismatch == 'workspace' ? 'other' : 'workspace',
        isPinned: false,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        parentConversationId: mismatch == 'parent' ? 'other' : 'parent',
      );
      final route = SubAgentConversationRoute(
        workspaceId: 'workspace',
        chatId: 'parent',
        subAgentConversationId: 'child',
      );
      final router = GoRouter(
        routes: [GoRoute(path: '/child', builder: route.build)],
        initialLocation: '/child',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          conversationByIdStreamProvider(
            'workspace',
            conversationId: 'child',
          ).overrideWith((_) => Stream.value(child)),
          conversationChatProvider(
            'workspace',
            'child',
          ).overrideWith(_LoadingConversation.new),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      await tester.pump();
      if (mismatch == 'none') {
        expect(
          tester
              .widget<ChatConversationScreen>(
                find.byType(ChatConversationScreen),
              )
              .showInputComposer,
          isFalse,
        );
      } else {
        expect(find.byType(ChatConversationScreen), findsNothing);
        expect(find.text('Conversation not found'), findsOneWidget);
      }
    });
  }
}
