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
    final started = Completer<_StartedMarionetteChild>();
    final requestStarted = Completer<agent.SubAgentRequestHandle>();
    final launched = await _launchChild(started, requestStarted);
    _storeLaunchedChild(launched);

    return launched.child.childId;
  }

  void _storeLaunchedChild(
    ({_StartedMarionetteChild child, Future<void> execution}) launched,
  ) {
    final child = launched.child;
    _children[child.childId] = (
      request: child.request,
      execution: launched.execution,
    );
  }

  agent.SubAgentRunner _createRunner(
    Completer<_StartedMarionetteChild> started,
    Completer<agent.SubAgentRequestHandle> requestStarted,
    void Function(String) onChildStarted,
  ) => agent.SubAgentRunner(
    agentCatalog: _agentCatalog,
    conversationStore: _conversationStore,
    messageStore: _messageStore,
    startRequest: _startRequestCallback(this, requestStarted, onChildStarted),
    continueAgentTurn: _continueAgentTurnCallback(
      this,
      started,
      requestStarted,
    ),
  );

  Future<({_StartedMarionetteChild child, Future<void> execution})>
  _launchChild(
    Completer<_StartedMarionetteChild> started,
    Completer<agent.SubAgentRequestHandle> requestStarted,
  ) async {
    String? activeChildId;
    final runner = _createRunner(
      started,
      requestStarted,
      (childId) => activeChildId = childId,
    );
    final execution = _runChild(runner, started, () => activeChildId);

    return (child: await started.future, execution: execution);
  }

  Future<void> _runChild(
    agent.SubAgentRunner runner,
    Completer<_StartedMarionetteChild> started,
    String? Function() activeChildId,
  ) => _observeExecution(
    run: runner.run(
      parentConversationId: _parentConversationId,
      workspaceId: _workspaceId,
      arguments: {
        'title': 'Marionette smoke child ${_nextChildNumber++}',
        'prompt': 'Deterministic local smoke fixture.',
      },
    ),
    started: started,
    activeChildId: activeChildId,
  );

  agent.SubAgentRequestHandle _startRequest(
    String parentId,
    String childId,
    Completer<agent.SubAgentRequestHandle> requestStarted,
    void Function(String) onChildStarted,
  ) {
    final request = _activeSubAgents.start(
      parentId: parentId,
      childId: childId,
    );
    onChildStarted(childId);
    if (!requestStarted.isCompleted) requestStarted.complete(request);

    return request;
  }

  Future<agent.AgentIterationDecision> _continueAgentTurn(
    String conversationId,
    Completer<_StartedMarionetteChild> started,
    Completer<agent.SubAgentRequestHandle> requestStarted,
  ) async {
    _activeSubAgents.markAwaitingApproval(conversationId);
    final request = await requestStarted.future;
    if (!started.isCompleted) {
      started.complete((childId: conversationId, request: request));
    }

    return agent.AgentIterationDecision.waitForToolApproval;
  }

  Future<void> _observeExecution({
    required Future<String> run,
    required Completer<_StartedMarionetteChild> started,
    required String? Function() activeChildId,
  }) async {
    try {
      // Discard response while preserving runner completion and errors.
      await run.asStream().drain<void>();
    } on Object catch (error, stackTrace) {
      if (!started.isCompleted) {
        started.completeError(error, stackTrace);
      }
    } finally {
      final childId = activeChildId();
      if (childId != null) {
        final _ = _children.remove(childId);
      }
    }
  }
}

agent.StartSubAgentRequest _startRequestCallback(
  MarionetteSubAgentSmokeFixture fixture,
  Completer<agent.SubAgentRequestHandle> requestStarted,
  void Function(String) onChildStarted,
) =>
    ({required parentId, required childId}) => fixture._startRequest(
      parentId,
      childId,
      requestStarted,
      onChildStarted,
    );

agent.ContinueSubAgentTurn _continueAgentTurnCallback(
  MarionetteSubAgentSmokeFixture fixture,
  Completer<_StartedMarionetteChild> started,
  Completer<agent.SubAgentRequestHandle> requestStarted,
) => ({required conversationId, required context}) {
  final _ = context;

  return fixture._continueAgentTurn(conversationId, started, requestStarted);
};

typedef _StartedMarionetteChild = ({
  String childId,
  agent.SubAgentRequestHandle request,
});
