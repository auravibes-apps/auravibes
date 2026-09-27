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
        'nextCursor': null,
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

      final result = jsonDecode(
        await runner.listAgents('w1', arguments: const {'type': 'sub_agent'}),
      ) as Map<String, Object?>;

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

      final failure = await _expectFailure(
        runner.listAgents('w1', arguments: const {'type': 'other'}),
      );
      final result = _decodeFailure(failure);

      expect(result['status'], 'error');
      expect(result['content'], 'Unknown agent type.');
      expect(failure.failurePhase, 'listAgents.validate');
    });

    test('list_agents schema exposes optional query, type, limit, cursor', () {
      final schema = listAgentsToolSpec.inputJsonSchema;
      final properties = schema['properties']! as Map<String, Object?>;
      final type = properties['type']! as Map<String, Object?>;

      expect(type['enum'], ['main', 'sub_agent']);
      expect(schema['required'], isNot(contains('type')));
      expect(properties['query'], containsPair('maxLength', 200));
      expect(properties['limit'], containsPair('maximum', 100));
      expect(properties['cursor'], containsPair('maxLength', 2048));
    });

    test('forwards list query, limit, cursor, and next cursor', () async {
      final catalog = _RecordingCatalog();
      final runner = _runner(catalog: catalog);

      final result = jsonDecode(
        await runner.listAgents(
          'w1',
          arguments: const {
            'query': ' review ',
            'type': 'main',
            'limit': 7,
            'cursor': 'cursor-1',
          },
        ),
      ) as Map<String, Object?>;

      expect(catalog.query?.workspaceId, 'w1');
      expect(catalog.query?.query, 'review');
      expect(catalog.query?.type, 'main');
      expect(catalog.query?.limit, 7);
      expect(catalog.query?.cursor, 'cursor-1');
      expect(result['nextCursor'], 'cursor-2');
    });

    test('rejects invalid list query arguments', () async {
      final runner = _runner();

      for (final arguments in <Map<String, dynamic>>[
        {'query': 1},
        {'query': List.filled(201, 'x').join()},
        {'limit': 0},
        {'limit': 101},
        {'cursor': ''},
      ]) {
        final failure = await _expectFailure(
          runner.listAgents('w1', arguments: arguments),
        );
        final result = _decodeFailure(failure);
        expect(result['status'], 'error');
        expect(failure.failurePhase, 'listAgents.validate');
      }
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

        final failure = await _expectFailure(
          runner.run(
            parentConversationId: 'child-parent',
            workspaceId: 'w1',
            arguments: const {'title': 'Task', 'prompt': 'Do it'},
          ),
        );
        final result = _decodeFailure(failure);

        expect(result['status'], 'error');
        expect(result['content'], 'Sub-agents cannot start sub-agents.');
        expect(failure.failurePhase, 'run.parentValidation');
        expect(conversations.createdChildren, isEmpty);
      },
    );

    test('rejects unknown agent without creating child', () async {
      final conversations = _ConversationStore();
      final runner = _runner(conversations: conversations);

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {
            'title': 'Task',
            'prompt': 'Do it',
            'agentId': 'missing',
          },
        ),
      );
      final result = _decodeFailure(failure);

      expect(result['status'], 'error');
      expect(result['agentId'], 'missing');
      expect(result['content'], 'Unknown agent.');
      expect(failure.failurePhase, 'run.agentValidation');
      expect(conversations.createdChildren, isEmpty);
    });

    test('rejects missing title, prompt, and parent conversation', () async {
      final conversations = _ConversationStore();
      final runner = _runner(conversations: conversations);

      final missingTitle = _decodeFailure(
        await _expectFailure(
          runner.run(
            parentConversationId: 'parent',
            workspaceId: 'w1',
            arguments: const {'prompt': 'Do it'},
          ),
        ),
      );
      final missingPrompt = _decodeFailure(
        await _expectFailure(
          runner.run(
            parentConversationId: 'parent',
            workspaceId: 'w1',
            arguments: const {'title': 'Task'},
          ),
        ),
      );
      final missingParent = _decodeFailure(
        await _expectFailure(
          runner.run(
            parentConversationId: 'missing',
            workspaceId: 'w1',
            arguments: const {'title': 'Task', 'prompt': 'Do it'},
          ),
        ),
      );

      expect(missingTitle['content'], 'Missing title.');
      expect(missingPrompt['content'], 'Missing prompt.');
      expect(missingParent['content'], 'Parent conversation not found.');
      expect(conversations.createdChildren, isEmpty);
    });

    test('rejects oversized title and prompt without creating child', () async {
      final conversations = _ConversationStore();
      final runner = _runner(conversations: conversations);

      final titleResult = _decodeFailure(
        await _expectFailure(
          runner.run(
            parentConversationId: 'parent',
            workspaceId: 'w1',
            arguments: {
              'title': 'x' * (maxSubAgentTitleLength + 1),
              'prompt': 'Do it',
            },
          ),
        ),
      );
      final promptResult = _decodeFailure(
        await _expectFailure(
          runner.run(
            parentConversationId: 'parent',
            workspaceId: 'w1',
            arguments: {
              'title': 'Task',
              'prompt': 'x' * (maxSubAgentPromptLength + 1),
            },
          ),
        ),
      );

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

      final result = jsonDecode(
        await runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {
            'title': ' Task ',
            'prompt': ' Do it ',
            'agentId': ' agent-1 ',
          },
        ),
      ) as Map<String, Object?>;

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

        final result = jsonDecode(
          await runner.run(
            parentConversationId: 'parent',
            workspaceId: 'w1',
            arguments: const {'title': 'Task', 'prompt': 'Do it'},
          ),
        ) as Map<String, Object?>;

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
                status: .stopped,
              );
            }),
          );

          return AgentIterationDecision.waitForToolApproval;
        },
      );

      final result = jsonDecode(
        await runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      ) as Map<String, Object?>;

      expect(result['conversationId'], 'child');
      expect(result['status'], 'stopped');
      expect(tracker.status('child'), SubAgentCompletionStatus.stopped);
    });

    test('returns error when approval wait completes with error', () async {
      final tracker = _Tracker();
      final error = StateError('child provider secret');
      final runner = _runner(
        tracker: tracker,
        continueTurn: ({required conversationId, required context}) async {
          Timer.run(() {
            tracker.finish(
              parentId: 'parent',
              childId: 'child',
              status: .error,
              error: error,
            );
          });

          return AgentIterationDecision.waitForToolApproval;
        },
      );

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      );
      final result = _decodeFailure(failure);

      expect(result['conversationId'], 'child');
      expect(result['status'], 'error');
      expect(result['content'], 'Sub-agent failed.');
      expect(failure.failurePhase, 'run.waitForApproval');
      expect(failure.error, same(error));
      expect(failure.responseRaw, isNot(contains('child provider secret')));
    });

    test('returns error when prompt creation throws', () async {
      final runner = _runner(messages: _ThrowingMessages());

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      );
      final result = _decodeFailure(failure);

      expect(result['conversationId'], 'child');
      expect(result['status'], 'error');
      expect(result['content'], 'Sub-agent failed.');
      expect(failure.failurePhase, 'run.createPrompt');
      expect(failure.error, isA<StateError>());
      expect(failure.responseRaw, isNot(contains('boom')));
    });

    test('preserves child ID and continuation diagnostics safely', () async {
      final error = StateError('provider secret');
      final tracker = _Tracker();
      final runner = _runner(
        tracker: tracker,
        continueTurn: ({required conversationId, required context}) async {
          throw error;
        },
      );

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      );
      final result = _decodeFailure(failure);

      expect(result, containsPair('conversationId', 'child'));
      expect(result['status'], 'error');
      expect(result['content'], 'Sub-agent failed.');
      expect(failure.error, same(error));
      expect(tracker.failure('child')?.error, same(error));
      expect(tracker.status('child'), SubAgentCompletionStatus.error);
      expect(failure.failurePhase, 'run.continueAgent');
      expect(failure.responseRaw, isNot(contains('provider secret')));
    });

    test('wraps typed continuation failures with the child ID', () async {
      final error = StateError('nested provider secret');
      final runner = _runner(
        continueTurn: ({required conversationId, required context}) async {
          throw AgentToolExecutionFailure(
            responseRaw: '{"status":"error"}',
            error: error,
            stackTrace: StackTrace.current,
            failurePhase: 'nested.continueAgent',
          );
        },
      );

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      );
      final result = _decodeFailure(failure);

      expect(result['conversationId'], 'child');
      expect(result['status'], 'error');
      expect(result['content'], 'Sub-agent failed.');
      expect(failure.error, same(error));
      expect(failure.failurePhase, 'run.continueAgent');
      expect(failure.responseRaw, isNot(contains('nested provider secret')));
    });

    test('reports result loading failures with child ID', () async {
      final runner = _runner(messages: _ThrowingResultMessages());

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      );
      final result = _decodeFailure(failure);

      expect(result['conversationId'], 'child');
      expect(result['content'], 'Sub-agent failed.');
      expect(failure.failurePhase, 'run.readResult');
    });

    test('reports child creation failures with the creation phase', () async {
      final error = StateError('database secret');
      final runner = _runner(conversations: _ThrowingConversationStore(error));

      final failure = await _expectFailure(
        runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      );

      expect(failure.error, same(error));
      expect(failure.failurePhase, 'run.createChild');
      expect(_decodeFailure(failure)['conversationId'], isNull);
    });

    test('returns stopped when child is stopped during continuation', () async {
      final tracker = _Tracker();
      final runner = _runner(
        tracker: tracker,
        continueTurn: ({required conversationId, required context}) async {
          tracker.finish(
            parentId: 'parent',
            childId: 'child',
            status: .stopped,
          );

          return AgentIterationDecision.done;
        },
      );

      final result = jsonDecode(
        await runner.run(
          parentConversationId: 'parent',
          workspaceId: 'w1',
          arguments: const {'title': 'Task', 'prompt': 'Do it'},
        ),
      ) as Map<String, Object?>;

      expect(result['conversationId'], 'child');
      expect(result['status'], 'stopped');
    });
  });
}

Future<AgentToolExecutionFailure> _expectFailure(Future<String> result) async {
  try {
    await result;
  } on AgentToolExecutionFailure catch (failure) {
    return failure;
  }

  fail('Expected AgentToolExecutionFailure.');
}

Map<String, Object?> _decodeFailure(AgentToolExecutionFailure failure) =>
    jsonDecode(failure.responseRaw) as Map<String, Object?>;

SubAgentRunner _runner({
  SubAgentCatalog catalog = const _Catalog(),
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

class const _Catalog({final List<SubAgentCatalogEntry> entries = const []})
    implements SubAgentCatalog {
  @override
  Future<SubAgentCatalogEntry?> getSubAgent(String agentId) async {
    return entries.where((entry) => entry.id == agentId).firstOrNull;
  }

  @override
  Future<SubAgentCatalogPage> listSubAgents(SubAgentCatalogQuery query) async {
    final filtered = entries.where(
      (entry) =>
          entry.workspaceId == query.workspaceId &&
          (query.type == null || entry.types.contains(query.type)) &&
          (query.query.isEmpty ||
              entry.name.toLowerCase().contains(query.query.toLowerCase()) ||
              entry.description.toLowerCase().contains(
                query.query.toLowerCase(),
              )),
    );
    return SubAgentCatalogPage(agents: filtered.take(query.limit).toList());
  }
}

class _RecordingCatalog implements SubAgentCatalog {
  SubAgentCatalogQuery? query;

  @override
  Future<SubAgentCatalogEntry?> getSubAgent(String agentId) async => null;

  @override
  Future<SubAgentCatalogPage> listSubAgents(SubAgentCatalogQuery query) async {
    this.query = query;
    return const SubAgentCatalogPage(agents: [], nextCursor: 'cursor-2');
  }
}

class _ConversationStore({
  final SubAgentConversationRecord parent = const SubAgentConversationRecord(
    id: 'parent',
    workspaceId: 'w1',
    modelId: 'm1',
    parentConversationId: null,
  ),
}) implements SubAgentConversationStore {
  final createdChildren = <String>[];

  @override
  Future<SubAgentConversationRecord> createChildConversation(
    SubAgentChildConversationRequest request,
  ) async {
    createdChildren.add(request.title);

    return SubAgentConversationRecord(
      id: 'child',
      workspaceId: request.workspaceId,
      modelId: request.modelId,
      parentConversationId: request.parentConversationId,
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

class _ThrowingResultMessages extends _Messages {
  @override
  Future<String> latestAssistantContent(String conversationId) async {
    throw StateError('read secret');
  }
}

class _ThrowingConversationStore extends _ConversationStore {
  new(this.error);

  final Error error;

  @override
  Future<SubAgentConversationRecord> createChildConversation(
    SubAgentChildConversationRequest request,
  ) async {
    throw error;
  }
}

class _Tracker {
  final _completers = <String, Completer<SubAgentCompletionStatus>>{};
  final _stoppedChildIds = <String>{};
  final _failures = <String, SubAgentCompletionFailure>{};
  final _statuses = <String, SubAgentCompletionStatus>{};

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
    Object? error,
    StackTrace? stackTrace,
  }) {
    _statuses[childId] = status;
    final completer = _completers.remove(childId);
    if (error != null) {
      _failures[childId] = SubAgentCompletionFailure(
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
      );
    } else if (completer == null) {
      _failures.remove(childId);
    }
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

  SubAgentCompletionFailure? failure(String childId) => _failures[childId];
  SubAgentCompletionStatus? status(String childId) => _statuses[childId];
}

class const _TestSubAgentRequestHandle(
  final _Tracker _tracker,
  final String _parentId,
  final String _childId,
) implements SubAgentRequestHandle {
  @override
  Future<SubAgentCompletionStatus> get completion =>
      _tracker.waitForCompletion(_childId);

  @override
  SubAgentCompletionFailure? get failure => _tracker.failure(_childId);

  @override
  bool get isStopped => _tracker.isStopped(_childId);

  @override
  void finish({
    SubAgentCompletionStatus status = SubAgentCompletionStatus.done,
    SubAgentCompletionFailure? failure,
  }) {
    _tracker.finish(
      parentId: _parentId,
      childId: _childId,
      status: status,
      error: failure?.error,
      stackTrace: failure?.stackTrace,
    );
  }
}
