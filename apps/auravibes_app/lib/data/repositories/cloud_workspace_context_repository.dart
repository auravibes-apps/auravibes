import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show Client;

class const CloudWorkspaceContextRepository(
  final Client client,
  final int workspaceId,
) implements WorkspaceConversationContextRepository {
  @override
  Future<WorkspaceConversationContext> read(String conversationId) async =>
      _decode(
        await client.workspaceContext.read(workspaceId, conversationId),
        conversationId,
      );
  @override
  Future<WorkspaceConversationContext> save(
    String conversationId,
    String requestId,
    WorkspaceContextSelection? selection,
  ) async => _decode(
    await client.workspaceContext.save(
      workspaceId,
      conversationId,
      requestId,
      selection == null ? null : jsonEncode(selection.toJson()),
    ),
    conversationId,
  );
  WorkspaceConversationContext _decode(String value, String conversationId) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    return WorkspaceConversationContext(
      id: data['id'] as String?,
      selection: WorkspaceContextSelection.decode(
        data['selection'],
        '$workspaceId',
        conversationId,
      ),
    );
  }
}
