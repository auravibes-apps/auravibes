import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  group('SubAgentRunner', () {
    test('lists enabled agent catalog entries', () async {
      final runner = _runner(
        catalog: const _Catalog(
          entries: [
            SubAgentCatalogEntry(
              id: 'a1',
              workspaceId: 'w1',
              name: 'Reviewer',
              description: 'Use for review.',
              types: ['main', 'sub_agent'],
            ),
          ],
        ),
      );

      final result =
          jsonDecode(await runner.listAgents('w1')) as Map<String, Object?>;

      expect(result, {
        'agents': [
          {
            'id': 'a1',
            'name': 'Reviewer',
            'description': 'Use for review.',
            'types': ['main', 'sub_agent'],
          },
        ],
      });
    });

    test('filters listed agents by type', () async {
      final runner = _runner(
        catalog: const _Catalog(
          entries: [
            SubAgentCatalogEntry(
              id: 'main',
              workspaceId: 'w1',
              name: 'Main',
              description: 'Main only.',
              types: ['main'],
            ),
            SubAgentCatalogEntry(
              id: 'sub',
              workspaceId: 'w1',
              name: 'Sub',
              description: 'Sub only.',
              types: ['sub_agent'],
            ),
          ],
        ),
      );

      final result =
          jsonDecode(
                await runner.listAgents(
                  'w1',
                  arguments: const {'type': 'sub_agent'},
                ),
              )
              as Map<String, Object?>;

      expect(result['agents'], [
        {
          'id': 'sub',
          'name': 'Sub',
          'description': 'Sub only.',
          'types': ['sub_agent'],
        },
      ]);
    });

    test('rejects unknown list_agents type', () async {
      final runner = _runner();

      final result =
          jsonDecode(
                await runner.listAgents(
                  'w1',
                  arguments: const {'type': 'other'},
                ),
              )
              as Map<String, Object?>;

      expect(result['status'], 'error');
      expect(result['content'], 'Unknown agent type.');
    });

    test('list_agents type schema is optional enum', () {
      final schema = listAgentsToolSpec.inputJsonSchema;
      final properties = schema['properties']! as Map<String, Object?>;
      final type = properties['type']! as Map<String, Object?>;

      expect(type['enum'], ['main', 'sub_agent']);
      expect(schema['required'], isNot(contains('type')));
    });

    test('run_sub_agent agentId schema is optional string only', () {
      final schema = runSubAgentToolSpec.inputJsonSchema;
      final properties = schema['properties']! as Map<String, Object?>;
      final agentId = properties['agentId']! as Map<String, Object?>;

      expect(agentId['type'], 'string');
      expect(schema['required'], isNot(contains('agentId')));
    });

    test(
      'rejects nested sub-agent conversations without creating child',
      () async {
        final conversations = _ConversationStore(
          parent: const SubAgentConversationRecord(
            id: 'child-parent',
            workspaceId: 'w1',
            modelId: 'm1',
            parentConversationId: 'root',
          ),
        );
        final runner = _runner(conversations: conversations);

        final result =
            jsonDecode(
                  await runner.run(
                    parentConversationId: 'child-parent',
                    workspaceId: 'w1',
                    arguments: const {'title': 'Task', 'prompt': 'Do it'},
                  ),
                )
                as Map<String, Object?>;

        expect(result['status'], 'error');
        expect(result['content'], 'Sub-agents cannot start sub-agents.');
        expect(conversations.createdChildren, isEmpty);
      },
    );

    test('rejects unknown agent without creating child', () async {
      final conversations = _ConversationStore();
      final runner = _runner(
        conversations: conversations,
      );

      final result =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {
                    'title': 'Task',
                    'prompt': 'Do it',
                    'agentId': 'missing',
                  },
                ),
              )
              as Map<String, Object?>;

      expect(result['status'], 'error');
      expect(result['agentId'], 'missing');
      expect(result['content'], 'Unknown agent.');
      expect(conversations.createdChildren, isEmpty);
    });

    test('rejects missing title, prompt, and parent conversation', () async {
      final conversations = _ConversationStore();
      final runner = _runner(conversations: conversations);

      final missingTitle =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {'prompt': 'Do it'},
                ),
              )
              as Map<String, Object?>;
      final missingPrompt =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {'title': 'Task'},
                ),
              )
              as Map<String, Object?>;
      final missingParent =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'missing',
                  workspaceId: 'w1',
                  arguments: const {'title': 'Task', 'prompt': 'Do it'},
                ),
              )
              as Map<String, Object?>;

      expect(missingTitle['content'], 'Missing title.');
      expect(missingPrompt['content'], 'Missing prompt.');
      expect(missingParent['content'], 'Parent conversation not found.');
      expect(conversations.createdChildren, isEmpty);
    });

    test('rejects oversized title and prompt without creating child', () async {
      final conversations = _ConversationStore();
      final runner = _runner(conversations: conversations);

      final titleResult =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: {
                    'title': 'x' * (maxSubAgentTitleLength + 1),
                    'prompt': 'Do it',
                  },
                ),
              )
              as Map<String, Object?>;
      final promptResult =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: {
                    'title': 'Task',
                    'prompt': 'x' * (maxSubAgentPromptLength + 1),
                  },
                ),
              )
              as Map<String, Object?>;

      expect(titleResult['content'], 'Title is too long.');
      expect(promptResult['content'], 'Prompt is too long.');
      expect(conversations.createdChildren, isEmpty);
    });

    test('returns done with agentId and child-start callback', () async {
      var started = <String>[];
      final runner = _runner(
        catalog: const _Catalog(
          entries: [
            SubAgentCatalogEntry(
              id: 'agent-1',
              workspaceId: 'w1',
              name: 'Agent',
              description: 'Runs tasks.',
              types: ['sub_agent'],
            ),
          ],
        ),
        onChildStarted: ({required parentId, required childId}) {
          started = [parentId, childId];
        },
      );

      final result =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {
                    'title': ' Task ',
                    'prompt': ' Do it ',
                    'agentId': ' agent-1 ',
                  },
                ),
              )
              as Map<String, Object?>;

      expect(result['status'], 'done');
      expect(result['agentId'], 'agent-1');
      expect(started, ['parent', 'child']);
    });

    test(
      'waits for approval completion before returning final content',
      () async {
        final tracker = _Tracker();
        final messages = _Messages();
        final runner = _runner(
          tracker: tracker,
          messages: messages,
          continueTurn: ({required conversationId, required context}) async {
            messages.latestContent = 'Waiting';
            unawaited(
              Future<void>.microtask(() {
                messages.latestContent = 'Final answer';
                tracker.finish(parentId: 'parent', childId: 'child');
              }),
            );

            return AgentIterationDecision.waitForToolApproval;
          },
        );

        final result =
            jsonDecode(
                  await runner.run(
                    parentConversationId: 'parent',
                    workspaceId: 'w1',
                    arguments: const {'title': 'Task', 'prompt': 'Do it'},
                  ),
                )
                as Map<String, Object?>;

        expect(result['conversationId'], 'child');
        expect(result['status'], 'done');
        expect(result['content'], 'Final answer');
        expect(result, isNot(contains('agentId')));
      },
    );

    test('returns stopped when approval wait is stopped', () async {
      final tracker = _Tracker();
      final runner = _runner(
        tracker: tracker,
        continueTurn: ({required conversationId, required context}) async {
          unawaited(
            Future<void>.microtask(() {
              tracker.finish(
                parentId: 'parent',
                childId: 'child',
                status: SubAgentCompletionStatus.stopped,
              );
            }),
          );

          return AgentIterationDecision.waitForToolApproval;
        },
      );

      final result =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {'title': 'Task', 'prompt': 'Do it'},
                ),
              )
              as Map<String, Object?>;

      expect(result['conversationId'], 'child');
      expect(result['status'], 'stopped');
    });

    test('returns error when approval wait completes with error', () async {
      final tracker = _Tracker();
      final runner = _runner(
        tracker: tracker,
        continueTurn: ({required conversationId, required context}) async {
          Timer.run(() {
            tracker.finish(
              parentId: 'parent',
              childId: 'child',
              status: SubAgentCompletionStatus.error,
            );
          });

          return AgentIterationDecision.waitForToolApproval;
        },
      );

      final result =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {'title': 'Task', 'prompt': 'Do it'},
                ),
              )
              as Map<String, Object?>;

      expect(result['conversationId'], 'child');
      expect(result['status'], 'error');
      expect(result['content'], 'Sub-agent failed.');
    });

    test('returns error when prompt creation throws', () async {
      final runner = _runner(messages: _ThrowingMessages());

      final result =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {'title': 'Task', 'prompt': 'Do it'},
                ),
              )
              as Map<String, Object?>;

      expect(result['conversationId'], 'child');
      expect(result['status'], 'error');
      expect(result['content'], 'Sub-agent failed.');
    });

    test('returns stopped when child is stopped during continuation', () async {
      final tracker = _Tracker();
      final runner = _runner(
        tracker: tracker,
        continueTurn: ({required conversationId, required context}) async {
          tracker.finish(
            parentId: 'parent',
            childId: 'child',
            status: SubAgentCompletionStatus.stopped,
          );

          return AgentIterationDecision.done;
        },
      );

      final result =
          jsonDecode(
                await runner.run(
                  parentConversationId: 'parent',
                  workspaceId: 'w1',
                  arguments: const {'title': 'Task', 'prompt': 'Do it'},
                ),
              )
              as Map<String, Object?>;

      expect(result['conversationId'], 'child');
      expect(result['status'], 'stopped');
    });
  });
}

SubAgentRunner _runner({
  _Catalog catalog = const _Catalog(),
  _ConversationStore? conversations,
  _Messages? messages,
  _Tracker? tracker,
  ContinueSubAgentTurn? continueTurn,
  SubAgentChildStarted? onChildStarted,
}) {
  return SubAgentRunner(
    agentCatalog: catalog,
    conversationStore: conversations ?? _ConversationStore(),
    messageStore: messages ?? _Messages(),
    startRequest: (tracker ?? _Tracker()).start,
    continueAgentTurn:
        continueTurn ??
        ({required conversationId, required context}) async {
          return AgentIterationDecision.done;
        },
    onChildStarted: onChildStarted,
  );
}

class _Catalog implements SubAgentCatalog {
  const _Catalog({this.entries = const []});

  final List<SubAgentCatalogEntry> entries;

  @override
  Future<SubAgentCatalogEntry?> getSubAgent(String agentId) async {
    return entries.where((entry) => entry.id == agentId).firstOrNull;
  }

  @override
  Future<List<SubAgentCatalogEntry>> listSubAgents(String workspaceId) async {
    return entries.where((entry) => entry.workspaceId == workspaceId).toList();
  }
}

class _ConversationStore implements SubAgentConversationStore {
  _ConversationStore({
    this.parent = const SubAgentConversationRecord(
      id: 'parent',
      workspaceId: 'w1',
      modelId: 'm1',
      parentConversationId: null,
    ),
  });

  final SubAgentConversationRecord parent;
  final createdChildren = <String>[];

  @override
  Future<SubAgentConversationRecord> createChildConversation({
    required String parentConversationId,
    required String workspaceId,
    required String? modelId,
    required String? agentId,
    required String title,
  }) async {
    createdChildren.add(title);

    return SubAgentConversationRecord(
      id: 'child',
      workspaceId: workspaceId,
      modelId: modelId,
      parentConversationId: parentConversationId,
    );
  }

  @override
  Future<SubAgentConversationRecord?> getConversation(
    String conversationId,
  ) async {
    return parent.id == conversationId ? parent : null;
  }
}

class _Messages implements SubAgentMessageStore {
  String latestContent = 'Answer';

  @override
  Future<SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  }) async {
    return const SubAgentMessageRecord(id: 'message');
  }

  @override
  Future<String> latestAssistantContent(String conversationId) async {
    return latestContent;
  }
}

class _ThrowingMessages extends _Messages {
  @override
  Future<SubAgentMessageRecord> createUserPrompt({
    required String conversationId,
    required String prompt,
  }) async {
    throw StateError('boom');
  }
}

class _Tracker {
  final _completers = <String, Completer<SubAgentCompletionStatus>>{};
  final _stoppedChildIds = <String>{};

  SubAgentRequestHandle start({
    required String parentId,
    required String childId,
  }) {
    _completers[childId] = Completer<SubAgentCompletionStatus>();
    return _TestSubAgentRequestHandle(this, parentId, childId);
  }

  void finish({
    required String parentId,
    required String childId,
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  }) {
    final completer = _completers.remove(childId);
    if (status == SubAgentCompletionStatus.stopped) {
      _stoppedChildIds.add(childId);
    }
    if (completer == null || completer.isCompleted) return;

    completer.complete(status);
  }

  Future<SubAgentCompletionStatus> waitForCompletion(String childId) {
    if (_stoppedChildIds.remove(childId)) {
      return Future<SubAgentCompletionStatus>.value(
        SubAgentCompletionStatus.stopped,
      );
    }

    return _completers[childId]?.future ??
        Future<SubAgentCompletionStatus>.value(SubAgentCompletionStatus.done);
  }

  bool isStopped(String childId) => _stoppedChildIds.contains(childId);
}

class _TestSubAgentRequestHandle implements SubAgentRequestHandle {
  const _TestSubAgentRequestHandle(
    this._tracker,
    this._parentId,
    this._childId,
  );

  final _Tracker _tracker;
  final String _parentId;
  final String _childId;

  @override
  Future<SubAgentCompletionStatus> get completion =>
      _tracker.waitForCompletion(_childId);

  @override
  bool get isStopped => _tracker.isStopped(_childId);

  @override
  void finish([
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
  ]) {
    _tracker.finish(parentId: _parentId, childId: _childId, status: status);
  }
}
