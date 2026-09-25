import 'dart:async';

import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

final class MarionetteSubAgentSmokeFixture({
  required String parentConversationId,
  required String workspaceId,
  required agent.SubAgentCatalog agentCatalog,
  required agent.SubAgentConversationStore conversationStore,
  required agent.SubAgentMessageStore messageStore,
  required ActiveSubAgentController activeSubAgents,
}) {
  final String _parentConversationId = parentConversationId;
  final String _workspaceId = workspaceId;
  final agent.SubAgentCatalog _agentCatalog = agentCatalog;
  final agent.SubAgentConversationStore _conversationStore = conversationStore;
  final agent.SubAgentMessageStore _messageStore = messageStore;
  final ActiveSubAgentController _activeSubAgents = activeSubAgents;
  final _children =
      <
        String,
        ({agent.SubAgentRequestHandle request, Future<void> execution})
      >{};
  var _nextChildNumber = 1;

  Future<List<String>> start({required int count}) async {
    if (count != 1 && count != 2) {
      throw ArgumentError.value(count, 'count', 'must be 1 or 2');
    }

    final childIds = <String>[];
    for (var index = 0; index < count; index++) {
      childIds.add(await _startChild());
    }
    return childIds;
  }

  Future<void> finish({required String childId}) async {
    final child = _children.remove(childId);
    if (child == null) {
      throw ArgumentError.value(
        childId,
        'childId',
        'is not an active fixture child',
      );
    }

    child.request.finish();
    await child.execution;
  }

  Future<String> _startChild() async {
    final started = Completer<String>();
    agent.SubAgentRequestHandle? requestHandle;
    String? activeChildId;
    final runner = agent.SubAgentRunner(
      agentCatalog: _agentCatalog,
      conversationStore: _conversationStore,
      messageStore: _messageStore,
      startRequest: ({required parentId, required childId}) {
        final handle = _activeSubAgents.start(
          parentId: parentId,
          childId: childId,
        );
        requestHandle = handle;
        activeChildId = childId;
        return handle;
      },
      continueAgentTurn: ({required conversationId, required context}) async {
        final _ = context;
        _activeSubAgents.markAwaitingApproval(conversationId);
        if (!started.isCompleted) started.complete(conversationId);
        return agent.AgentIterationDecision.waitForToolApproval;
      },
    );
    final run = runner.run(
      parentConversationId: _parentConversationId,
      workspaceId: _workspaceId,
      arguments: {
        'title': 'Marionette smoke child ${_nextChildNumber++}',
        'prompt': 'Deterministic local smoke fixture.',
      },
    );
    final execution = run.then<void>(
      (_) {
        final id = activeChildId;
        if (id != null) _children.remove(id);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!started.isCompleted) started.completeError(error, stackTrace);
        final id = activeChildId;
        if (id != null) _children.remove(id);
      },
    );

    final startedChildId = await started.future;
    final handle = requestHandle;
    if (handle == null) throw StateError('Fixture child did not start.');
    _children[startedChildId] = (request: handle, execution: execution);
    return startedChildId;
  }
}
