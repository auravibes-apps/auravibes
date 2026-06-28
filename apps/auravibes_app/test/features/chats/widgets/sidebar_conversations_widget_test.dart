// Required: Existing test and UI helpers keep compact return flow.

// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.

import 'dart:async';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
            conversationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: _SidebarWorkspaceHost(),
          ),
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

  testWidgets(
    're-subscribes when workspace id changes',
    (tester) async {
      final repository = _RecordingConversationRepository();
      addTearDown(repository.close);

      await tester.pumpWidget(
        TestProviderScope(
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: _SidebarWorkspaceHost(),
          ),
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
    },
  );

  testWidgets('renders SizedBox.shrink when workspaceId is null', (
    tester,
  ) async {
    final repository = _RecordingConversationRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      TestProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: _SidebarWorkspaceHost(),
        ),
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
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: _SidebarWorkspaceHost(),
        ),
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
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
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
    );
    await tester.pump();

    expect(
      repository.workspaceWatchCalls,
      equals([
        const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 5),
      ]),
    );
  });

  test('SidebarConversationsWidget stores properties', () {
    const widget = SidebarConversationsWidget(
      workspaceId: 'ws-1',
      limit: 5,
    );
    expect(widget.workspaceId, 'ws-1');
    expect(widget.limit, 5);
  });

  test('SidebarConversationsWidget accepts empty workspaceId', () {
    const widget = SidebarConversationsWidget(
      workspaceId: '',
    );
    expect(widget.workspaceId, isEmpty);
  });

  test('SidebarConversationsWidget default limit is 10', () {
    const widget = SidebarConversationsWidget(
      workspaceId: 'ws-1',
    );
    expect(widget.limit, 10);
  });

  test('SidebarConversationsWidget accepts optional key', () {
    const widget = SidebarConversationsWidget(
      workspaceId: 'ws-1',
      key: Key('test-key'),
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
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
            child: const Material(
              child: SizedBox(
                width: 300,
                height: 800,
                child: SidebarConversationsWidget(
                  workspaceId: '',
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
          conversationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Theme(
            data: ThemeData(extensions: [AuraTheme.light]),
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
                  conversationRepositoryProvider.overrideWithValue(repository),
                ],
                child: MaterialApp(
                  home: Theme(
                    data: ThemeData(extensions: [AuraTheme.light]),
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

  testWidgets(
    'renders conversations with compacting row when compaction is running',
    (
      tester,
    ) async {
      final conversations = [
        ConversationEntity(
          id: 'conv-1',
          title: 'Test Chat',
          workspaceId: 'workspace-1',
          isPinned: false,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
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
                      conversationRepositoryProvider.overrideWithValue(
                        repository,
                      ),
                      compactionExecutionProvider.overrideWith(() {
                        return _TestCompactionExecution({
                          'conv-1': CompactionExecutionState(
                            conversationId: 'conv-1',
                            trigger: CompactionTrigger.auto,
                            startedAt: DateTime(2025),
                            status: CompactionExecutionStatus.running,
                          ),
                        });
                      }),
                    ],
                    child: MaterialApp(
                      home: Theme(
                        data: ThemeData(extensions: [AuraTheme.light]),
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
      expect(find.text('Test Chat'), findsOneWidget);
    },
  );
}

class _SeededConversationRepository extends _RecordingConversationRepository {
  _SeededConversationRepository(this._conversations);

  final List<ConversationEntity> _conversations;

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
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
}

class _TestCompactionExecution extends CompactionExecution {
  _TestCompactionExecution(this._initialState);

  final Map<String, CompactionExecutionState> _initialState;

  @override
  Map<String, CompactionExecutionState> build() {
    return Map.unmodifiable(_initialState);
  }
}

class _SidebarWorkspaceHost extends StatefulWidget {
  const _SidebarWorkspaceHost();

  static const loadWorkspaceKey = Key('load-workspace');
  static const switchWorkspaceKey = Key('switch-workspace');

  @override
  State<_SidebarWorkspaceHost> createState() => _SidebarWorkspaceHostState();
}

class _SidebarWorkspaceHostState extends State<_SidebarWorkspaceHost> {
  String _workspaceId = '';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(extensions: [AuraTheme.light]),
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
    );
  }
}

@immutable
class _WorkspaceWatchCall {
  const _WorkspaceWatchCall({required this.workspaceId, required this.limit});

  final String workspaceId;
  final int? limit;

  @override
  bool operator ==(Object other) {
    return other is _WorkspaceWatchCall &&
        other.workspaceId == workspaceId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(workspaceId, limit);

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
    int? limit,
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
