import 'package:auravibes_engine/auravibes_engine.dart';

class FakeCancellationEffects implements AgentCancellationEffects {
  final _scopes = <String, AgentCancellationScope>{};

  @override
  AgentCancellationScope start(String conversationId) {
    final scope = AgentCancellationScope();
    _scopes.remove(conversationId)?.requestStop();
    _scopes[conversationId] = scope;
    return scope;
  }

  @override
  AgentCancellationScope? current(String conversationId) =>
      _scopes[conversationId];

  bool isCancellationRequested(String conversationId) =>
      current(conversationId)?.isCancellationRequested ?? false;

  @override
  void requestStop(String conversationId) {
    _scopes[conversationId]?.requestStop();
  }

  @override
  void requestStopOnStart(String conversationId) => requestStop(conversationId);

  @override
  void clear(String conversationId, AgentCancellationScope scope) {
    if (identical(_scopes[conversationId], scope)) {
      _scopes.remove(conversationId);
    }
  }

  @override
  void forceClear(String conversationId) {
    _scopes.remove(conversationId)?.requestStop();
  }
}
