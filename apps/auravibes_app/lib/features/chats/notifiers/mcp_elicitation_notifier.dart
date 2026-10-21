import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_elicitation_notifier.g.dart';

@riverpod
class McpElicitationNotifier extends _$McpElicitationNotifier {
  var _nextRequestId = 0;

  @override
  List<McpElicitationPending> build(String conversationId) => [];

  Future<McpElicitationResponse> request(McpElicitationRequest request) {
    final response = Completer<McpElicitationResponse>();
    final keepAliveLink = ref.keepAlive();
    final pending = McpElicitationPending(
      id: 'mcp-elicitation-${_nextRequestId++}',
      request: request,
      response: response,
      closeKeepAlive: keepAliveLink.close,
    );
    state = [...state, pending];

    return response.future;
  }

  void respond({
    required String requestId,
    required McpElicitationResponse response,
  }) {
    final pendingIndex = state.indexWhere((pending) => pending.id == requestId);
    if (pendingIndex < 0) return;

    final pending = state[pendingIndex];
    if (pending.response.isCompleted) return;
    state = [...state]..removeAt(pendingIndex);
    pending.closeKeepAlive();
    pending.response.complete(response);
  }
}

final class McpElicitationPending({
  required final String id,
  required final McpElicitationRequest request,
  required final Completer<McpElicitationResponse> response,
  required final void Function() closeKeepAlive,
});
