// Required: Existing test and UI helpers keep compact return flow.

// Required: Widget tests override scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/data/repositories/browser_session_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'loads sidebar conversations when workspace id becomes available',
    (tester) async {
      final repository = _RecordingConversationRepository();
      addTearDown(repository.close);

      await tester.pumpWidget(
        TestProviderScope(
          overrides: [
            workspaceSessionForRouteProvider.overrideWith(
              (_, workspaceId) async => WorkspaceSession(
                LocalWorkspaceRef(localWorkspaceId: workspaceId),
              ),
            ),
            conversationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: _SidebarWorkspaceHost()),
        ),
      );

      expect(repository.workspaceWatchCalls, isEmpty);

      await tester.tap(find.byKey(_SidebarWorkspaceHost.loadWorkspaceKey));
      await tester.pump();

      expect(
        repository.workspaceWatchCalls,
        equals([
          const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 10),
        ]),
      );
    },
  );

  testWidgets('re-subscribes when workspace id changes', (tester) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: _SidebarWorkspaceHost()),
      ),
    );

    await tester.tap(find.byKey(_SidebarWorkspaceHost.loadWorkspaceKey));
    await tester.pump();

    expect(
      repository.workspaceWatchCalls,
      equals([
        const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 10),
      ]),
    );
    expect(repository._controllers, hasLength(1));
    final firstController = repository._controllers.single;

    await tester.tap(find.byKey(_SidebarWorkspaceHost.switchWorkspaceKey));
    await tester.pump();
    await tester.pump();

    expect(
      repository.workspaceWatchCalls,
      equals([
        const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 10),
        const _WorkspaceWatchCall(workspaceId: 'workspace-2', limit: 10),
      ]),
    );
    expect(repository._controllers, hasLength(1));
    expect(repository._controllers, isNot(contains(firstController)));
  });

  testWidgets('renders SizedBox.shrink when workspaceId is null', (
    tester,
  ) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: _SidebarWorkspaceHost()),
      ),
    );
    await tester.pump();

    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('shows spinner when loading', (tester) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: _SidebarWorkspaceHost()),
      ),
    );

    await tester.tap(find.byKey(_SidebarWorkspaceHost.loadWorkspaceKey));
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('uses custom limit parameter', (tester) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: AuraThemeScope(
            theme: .light,
            child: Theme(
              data: .new(),
              child: const Material(
                child: SizedBox(
                  width: 300,
                  height: 800,
                  child: SidebarConversationsWidget(
                    workspaceId: 'workspace-1',
                    limit: 5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      repository.workspaceWatchCalls,
      equals([const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 5)]),
    );
  });

  testWidgets('keeps an active recent conversation visible only once', (
    tester,
  ) async {
    final conversations = List.generate(
      10,
      (index) => _conversation('chat-$index', title: 'Recent Chat $index'),
    );
    final activeConversation = conversations[3];
    final repository = _SeededConversationRepository(conversations);
    addTearDown(repository.close);

    await _pumpSidebarAtConversation(
      tester,
      conversationId: activeConversation.id,
      repository: repository,
    );

    expect(find.text(activeConversation.title), findsOneWidget);
    final activeTile = tester.widget<AuraTile>(
      find
          .ancestor(
            of: find.text(activeConversation.title),
            matching: find.byType(AuraTile),
          )
          .first,
    );
    expect(activeTile.variant, AuraTileVariant.selected);
    expect(activeTile.onTap, isNotNull);
    expect(activeTile.trailing, isNotNull);
    expect(repository.byIdWatchCalls, isEmpty);
  });

  testWidgets('keeps an active conversation outside the first ten visible', (
    tester,
  ) async {
    final recentConversations = List.generate(
      10,
      (index) => _conversation('recent-$index', title: 'Recent Chat $index'),
    );
    final activeConversation = _conversation(
      'active-chat',
      title: 'Active Conversation',
    );
    final repository = _SeededConversationRepository(
      recentConversations,
      lookupConversations: [activeConversation],
    );
    addTearDown(repository.close);

    await _pumpSidebarAtConversation(
      tester,
      conversationId: activeConversation.id,
      repository: repository,
    );

    expect(repository.byIdWatchCalls, equals([activeConversation.id]));
    expect(find.text(activeConversation.title), findsOneWidget);
    final activeTile = tester.widget<AuraTile>(
      find
          .ancestor(
            of: find.text(activeConversation.title),
            matching: find.byType(AuraTile),
          )
          .first,
    );
    expect(activeTile.variant, AuraTileVariant.selected);
    expect(activeTile.onTap, isNotNull);
    expect(activeTile.trailing, isNotNull);
  });

  testWidgets(
    'updates stream indicators per conversation without changing selection',
    (tester) async {
      final semanticHandle = tester.ensureSemantics();

      final selectedConversation = _conversation(
        'chat-1',
        title: 'Selected Chat',
        isPinned: true,
      );
      final otherConversation = _conversation('chat-2', title: 'Other Chat');
      final repository = _SeededConversationRepository([
        selectedConversation,
        otherConversation,
      ]);
      addTearDown(repository.close);

      ProviderContainer? providerContainer;
      await _pumpSidebarAtConversation(
        tester,
        conversationId: selectedConversation.id,
        repository: repository,
        onProviderContainer: (container) => providerContainer = container,
      );

      final container = providerContainer;
      if (container == null) {
        throw StateError(
          'Provider container was not available in the sidebar.',
        );
      }

      final streamingNotifier = container.read(
        conversationStreamingProvider.notifier,
      );
      container
          .read(
            conversationDraftProvider(
              selectedConversation.workspaceId,
              selectedConversation.id,
            ).notifier,
          )
          .save(const ChatDraft(text: 'Unsent message'));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('conversation-draft-marker-chat-1')),
        findsOneWidget,
      );
      expect(find.text('Draft'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      final startStreaming = streamingNotifier.start;
      final stopStreaming = streamingNotifier.remove;

      startStreaming(otherConversation.id);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-1')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(RegExp('Assistant response in progress')),
        findsOneWidget,
      );

      startStreaming(selectedConversation.id);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-2')),
        findsOneWidget,
      );
      final selectedTile = tester.widget<AuraTile>(
        find
            .ancestor(
              of: find.text(selectedConversation.title),
              matching: find.byType(AuraTile),
            )
            .first,
      );
      expect(selectedTile.variant, AuraTileVariant.selected);
      expect(
        tester
            .getSemantics(
              find
                  .ancestor(
                    of: find.text(selectedConversation.title),
                    matching: find.byType(AuraTile),
                  )
                  .first,
            )
            .label,
        contains('Draft'),
      );

      stopStreaming(otherConversation.id);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-2')),
        findsNothing,
      );

      stopStreaming(selectedConversation.id);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('sidebar-streaming-status-chat-2')),
        findsNothing,
      );
      semanticHandle.dispose();
    },
  );

  test('SidebarConversationsWidget stores properties', () {
    const widget = SidebarConversationsWidget(workspaceId: 'ws-1', limit: 5);
    expect(widget.workspaceId, 'ws-1');
    expect(widget.limit, 5);
  });

  test('SidebarConversationsWidget accepts empty workspaceId', () {
    const widget = SidebarConversationsWidget(workspaceId: '');
    expect(widget.workspaceId, isEmpty);
  });

  test('SidebarConversationsWidget default limit is 10', () {
    const widget = SidebarConversationsWidget(workspaceId: 'ws-1');
    expect(widget.limit, 10);
  });

  test('SidebarConversationsWidget accepts optional key', () {
    const widget = SidebarConversationsWidget(
      workspaceId: 'ws-1',
      key: .new('test-key'),
    );
    expect(widget.key, const Key('test-key'));
  });

  testWidgets('renders SizedBox.shrink when workspaceId is empty', (
    tester,
  ) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: AuraThemeScope(
            theme: .light,
            child: Theme(
              data: .new(),
              child: const Material(
                child: SizedBox(
                  width: 300,
                  height: 800,
                  child: SidebarConversationsWidget(workspaceId: ''),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SizedBox), findsWidgets);
    expect(repository.workspaceWatchCalls, isEmpty);
  });

  testWidgets('shows spinner when loading conversations', (tester) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          workspaceSessionForRouteProvider.overrideWith(
            (_, workspaceId) async => WorkspaceSession(
              LocalWorkspaceRef(localWorkspaceId: workspaceId),
            ),
          ),
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: AuraThemeScope(
            theme: .light,
            child: Theme(
              data: .new(),
              child: const Material(
                child: SizedBox(
                  width: 300,
                  height: 800,
                  child: SidebarConversationsWidget(workspaceId: 'workspace-1'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
  });

  testWidgets('shows quiet empty state when there are no recent chats', (
    tester,
  ) async {
    final repository = _SeededConversationRepository(const []);
    addTearDown(repository.close);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return TestProviderScope(
                overrides: [
                  workspaceSessionForRouteProvider.overrideWith(
                    (_, workspaceId) async => WorkspaceSession(
                      LocalWorkspaceRef(localWorkspaceId: workspaceId),
                    ),
                  ),
                  conversationRepositoryProvider.overrideWithValue(repository),
                ],
                child: MaterialApp(
                  home: AuraThemeScope(
                    theme: .light,
                    child: Theme(
                      data: .new(),
                      child: const Material(
                        child: SizedBox(
                          width: 300,
                          height: 800,
                          child: SidebarConversationsWidget(
                            workspaceId: 'workspace-1',
                          ),
                        ),
                      ),
                    ),
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
        ),
      );
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('Recent Chats'), findsOneWidget);
    expect(find.text('Chats will appear here'), findsOneWidget);
    expect(find.text('View All'), findsNothing);
  });

  testWidgets('shows pinned icon during compaction', (tester) async {
    final conversations = [
      ConversationEntity(
        id: 'conv-1',
        title: 'Test Chat',
        workspaceId: 'workspace-1',
        isPinned: true,
        createdAt: .new(2025),
        updatedAt: .new(2025),
      ),
    ];

    final repository = _SeededConversationRepository(conversations);
    addTearDown(repository.close);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return Portal(
                child: TestProviderScope(
                  overrides: [
                    workspaceSessionForRouteProvider.overrideWith(
                      (_, workspaceId) async => WorkspaceSession(
                        LocalWorkspaceRef(localWorkspaceId: workspaceId),
                      ),
                    ),
                    conversationRepositoryProvider.overrideWithValue(
                      repository,
                    ),
                    compactionExecutionProvider.overrideWith(() {
                      return _TestCompactionExecution({
                        'conv-1': CompactionExecutionState(
                          conversationId: 'conv-1',
                          trigger: .auto,
                          startedAt: .new(2025),
                          status: .running,
                        ),
                      });
                    }),
                  ],
                  child: MaterialApp(
                    home: AuraThemeScope(
                      theme: .light,
                      child: Theme(
                        data: .new(),
                        child: const Material(
                          child: SizedBox(
                            width: 300,
                            height: 800,
                            child: SidebarConversationsWidget(
                              workspaceId: 'workspace-1',
                            ),
                          ),
                        ),
                      ),
                    ),
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  ),
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
        ),
      );
    });
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuraSpinner), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    expect(find.text('Test Chat'), findsOneWidget);
  });

  testWidgets('shows browser icon and manages tabs from conversation menu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final browserRepository = BrowserSessionRepository(preferences);
    await browserRepository.save(
      'browser-chat',
      const BrowserSessionState(
        tabs: [
          BrowserTab(id: 'tab-1', url: 'https://one.example'),
          BrowserTab(id: 'tab-2', url: 'https://two.example'),
        ],
        activeTabId: 'tab-2',
      ),
    );
    final repository = _SeededConversationRepository([
      _conversation('browser-chat', title: 'Browser Chat'),
    ]);
    addTearDown(repository.close);

    await _pumpSidebarAtConversation(
      tester,
      conversationId: 'browser-chat',
      repository: repository,
    );

    const browserIconKey = ValueKey('sidebar-browser-status-browser-chat');
    expect(find.byKey(browserIconKey), findsOneWidget);
    expect(find.text('2 tabs'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Suspend browser'));
    final _ = await tester.pumpAndSettle();

    var session = await browserRepository.load('browser-chat');
    expect(session.isSuspended, isTrue);
    expect(session.tabs, hasLength(2));
    expect(find.byKey(browserIconKey), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Resume browser'));
    final _ = await tester.pumpAndSettle();

    session = await browserRepository.load('browser-chat');
    expect(session.isSuspended, isFalse);
    expect(find.byKey(browserIconKey), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Close all browser tabs'));
    final _ = await tester.pumpAndSettle();

    session = await browserRepository.load('browser-chat');
    expect(session.tabs, isEmpty);
    expect(find.byKey(browserIconKey), findsNothing);
  });
}

class _SeededConversationRepository(
  final List<ConversationEntity> _conversations, {
  final List<ConversationEntity> lookupConversations = const [],
}) extends _RecordingConversationRepository {
  final byIdWatchCalls = <String>[];
  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) {
    workspaceWatchCalls.add(
      _WorkspaceWatchCall(workspaceId: workspaceId, limit: limit),
    );

    StreamController<List<ConversationEntity>>? controller;
    controller = StreamController<List<ConversationEntity>>.broadcast(
      onCancel: () {
        final activeController = controller;
        if (activeController != null) {
          final _ = _controllers.remove(activeController);
        }
      },
    );
    final activeController = controller;
    _controllers.add(activeController);

    Future.microtask(() => activeController.add(_conversations));

    return activeController.stream;
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    byIdWatchCalls.add(id);
    for (final conversation in [..._conversations, ...lookupConversations]) {
      if (conversation.id == id) return Stream.value(conversation);
    }

    return Stream.value(null);
  }
}

class _TestCompactionExecution(
  final Map<String, CompactionExecutionState> _initialState,
) extends CompactionExecution {
  @override
  Map<String, CompactionExecutionState> build() {
    return Map.unmodifiable(_initialState);
  }
}

ConversationEntity _conversation(
  String id, {
  required String title,
  bool isPinned = false,
}) => ConversationEntity(
  id: id,
  title: title,
  workspaceId: 'workspace-1',
  isPinned: isPinned,
  createdAt: .new(2025),
  updatedAt: .new(2025),
);

Future<void> _pumpSidebarAtConversation(
  WidgetTester tester, {
  required String conversationId,
  required _SeededConversationRepository repository,
  void Function(ProviderContainer container)? onProviderContainer,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/workspaces/:workspaceId/chats/:chatId',
        builder: (_, _) => AuraThemeScope(
          theme: .light,
          child: Theme(
            data: .new(),
            child: Material(
              child: SizedBox(
                width: 300,
                child: ListView(
                  children: const [
                    SidebarConversationsWidget(workspaceId: 'workspace-1'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
    initialLocation: '/workspaces/workspace-1/chats/$conversationId',
  );
  addTearDown(router.dispose);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => Portal(
            child: TestProviderScope(
              overrides: [
                workspaceSessionForRouteProvider.overrideWith(
                  (_, workspaceId) async => WorkspaceSession(
                    LocalWorkspaceRef(localWorkspaceId: workspaceId),
                  ),
                ),
                conversationRepositoryProvider.overrideWithValue(repository),
              ],
              child: Builder(
                builder: (context) {
                  onProviderContainer?.call(ProviderScope.containerOf(context));

                  return MaterialApp.router(
                    routerConfig: router,
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  );
                },
              ),
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
}

class const _SidebarWorkspaceHost() extends StatefulWidget {
  static const loadWorkspaceKey = Key('load-workspace');
  static const switchWorkspaceKey = Key('switch-workspace');

  @override
  State<_SidebarWorkspaceHost> createState() => _SidebarWorkspaceHostState();
}

class _SidebarWorkspaceHostState extends State<_SidebarWorkspaceHost> {
  String _workspaceId = '';

  @override
  Widget build(BuildContext context) {
    return AuraThemeScope(
      theme: .light,
      child: Theme(
        data: .new(),
        child: Material(
          child: Column(
            children: [
              TextButton(
                key: _SidebarWorkspaceHost.loadWorkspaceKey,
                onPressed: () => setState(() => _workspaceId = 'workspace-1'),
                child: const Text('Load workspace'),
              ),
              TextButton(
                key: _SidebarWorkspaceHost.switchWorkspaceKey,
                onPressed: () => setState(() => _workspaceId = 'workspace-2'),
                child: const Text('Switch workspace'),
              ),
              SidebarConversationsWidget(workspaceId: _workspaceId),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class const _WorkspaceWatchCall({
  required final String workspaceId,
  required final int? limit,
}) {
  @override
  int get hashCode => Object.hash(workspaceId, limit);

  @override
  bool operator ==(Object other) {
    return other is _WorkspaceWatchCall &&
        other.workspaceId == workspaceId &&
        other.limit == limit;
  }

  @override
  String toString() {
    return '_WorkspaceWatchCall(workspaceId: $workspaceId, limit: $limit)';
  }
}

class _RecordingConversationRepository implements ConversationRepository {
  final workspaceWatchCalls = <_WorkspaceWatchCall>[];
  final _controllers = <StreamController<List<ConversationEntity>>>[];

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    String? search,
    int? limit,
    int offset = 0,
  }) {
    workspaceWatchCalls.add(
      _WorkspaceWatchCall(workspaceId: workspaceId, limit: limit),
    );

    StreamController<List<ConversationEntity>>? controller;
    controller = StreamController<List<ConversationEntity>>.broadcast(
      onCancel: () {
        final activeController = controller;
        if (activeController != null) {
          final _ = _controllers.remove(activeController);
        }
      },
    );
    final activeController = controller;
    _controllers.add(activeController);

    return activeController.stream;
  }

  @override
  Stream<List<ConversationEntity>> watchChildConversations(
    String parentConversationId,
  ) {
    return const Stream.empty();
  }

  @override
  Future<List<ConversationEntity>> getChildConversations(
    String parentConversationId,
  ) async {
    return const [];
  }

  Future<void> close() async {
    final _ = await Future.wait(
      _controllers
          .where((controller) => !controller.isClosed)
          .map((controller) => controller.close()),
    );
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> forkConversation(
    String sourceConversationId, {
    String? throughMessageId,
  }) => throw UnimplementedError();

  @override
  Future<ConversationEntity?> getConversationById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    throw UnimplementedError();
  }
}
