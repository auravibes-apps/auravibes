import 'package:auravibes_engine/auravibes_engine.dart';

class const WorkspaceConversationContext({
  required final String? id,
  required final WorkspaceContextSelection? selection,
});

abstract interface class WorkspaceConversationContextRepository {
  Future<WorkspaceConversationContext> read(String conversationId);
  Future<WorkspaceConversationContext> save(
    String conversationId,
    String requestId,
    WorkspaceContextSelection? selection,
  );
}
