import 'package:auravibes_engine/src/agent_background_work_status.dart';
import 'package:auravibes_engine/src/tool_output_policy.dart';

/// Durable, provider-neutral description of detached work.
class const AgentBackgroundWork({
  required final AgentBackgroundWorkIdentity identity,
  required final AgentBackgroundWorkState state,
});

/// Stable identifiers that tie detached work to its origin.
class const AgentBackgroundWorkIdentity({
  required final String id,
  required final String workspaceId,
  required final String conversationId,
  required final String toolCallId,
  required final String toolKind,
  final String? originatingMessageId,
});

/// Lifecycle and bounded outcome data for detached work.
class const AgentBackgroundWorkState({
  required final AgentBackgroundWorkStatus status,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? statusPreview,
  final String? resultContent,
  final int resultByteLength = 0,
  final String? errorCode,
});

abstract final class AgentBackgroundWorkLimits {
  static const int statusPreviewBytes = 512;
  static const int resultBytes = maxPersistedToolOutputBytes;
}

/// Input for creating a provisional detached-work record.
class const AgentBackgroundWorkCreateRequest({
  required final String id,
  required final String workspaceId,
  required final String conversationId,
  required final String toolCallId,
  required final String toolKind,
  final String? originatingMessageId,
});

/// Terminal state to persist after a detached invocation settles.
class const AgentBackgroundWorkCompletion({
  required final String conversationId,
  required final String workId,
  required final AgentBackgroundWorkStatus status,
  required final String? resultContent,
  required final int resultByteLength,
  final String? statusPreview,
  final String? errorCode,
});

/// Persistence contract used by local and cloud work coordinators.
abstract interface class AgentBackgroundWorkStore {
  Future<AgentBackgroundWork?> find({
    required String conversationId,
    required String workId,
  });

  Stream<List<AgentBackgroundWork>> watchConversation(String conversationId);

  Future<AgentBackgroundWork> create(AgentBackgroundWorkCreateRequest request);

  /// Removes a provisional running record when detachment loses a race.
  Future<void> discard({
    required String conversationId,
    required String workId,
  });

  Future<bool> requestStop({
    required String conversationId,
    required String workId,
  });

  Future<AgentBackgroundWork?> finish(AgentBackgroundWorkCompletion completion);
}
