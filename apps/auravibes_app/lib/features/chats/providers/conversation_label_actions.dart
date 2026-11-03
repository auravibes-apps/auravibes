import 'package:auravibes_app/data/repositories/conversation_labels_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/v7.dart';

class ConversationLabelActions(final Ref _ref) {
  Future<ConversationLabelEntity> create({
    required String workspaceId,
    required String name,
  }) async {
    final cloud = await _cloudWorkspace(workspaceId);
    if (cloud == null) {
      return await _ref
          .read(conversationLabelsRepositoryProvider)
          .createLabel(workspaceId: workspaceId, name: name);
    }
    final labelId = const UuidV7().generate();
    final label = await cloud.gateway.client.conversation.createLabel(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        labelId: labelId,
        name: name,
      ),
    );

    return conversationLabelFromCloud(label, workspaceId);
  }

  Future<ConversationLabelEntity> rename({
    required String workspaceId,
    required String labelId,
    required String name,
  }) async {
    final cloud = await _cloudWorkspace(workspaceId);
    if (cloud == null) {
      return await _ref
          .read(conversationLabelsRepositoryProvider)
          .renameLabel(workspaceId: workspaceId, labelId: labelId, name: name);
    }
    final label = await cloud.gateway.client.conversation.renameLabel(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        labelId: labelId,
        name: name,
      ),
    );

    return conversationLabelFromCloud(label, workspaceId);
  }

  Future<void> delete({
    required String workspaceId,
    required String labelId,
  }) async {
    final cloud = await _cloudWorkspace(workspaceId);
    if (cloud == null) {
      return await _ref
          .read(conversationLabelsRepositoryProvider)
          .deleteLabel(workspaceId: workspaceId, labelId: labelId);
    }
    await cloud.gateway.client.conversation.deleteLabel(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        labelId: labelId,
      ),
    );
  }

  Future<void> assign({
    required String workspaceId,
    required String conversationId,
    required Set<String> labelIds,
  }) async {
    final cloud = await _cloudWorkspace(workspaceId);
    if (cloud == null) {
      return await _ref
          .read(conversationLabelsRepositoryProvider)
          .setConversationLabels(
            workspaceId: workspaceId,
            conversationId: conversationId,
            labelIds: labelIds,
          );
    }
    await cloud.gateway.client.conversation.setConversationLabels(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        conversationId: conversationId,
        labelIds: labelIds.toList()..sort(),
      ),
    );
  }

  Future<({CloudWorkspaceRef workspace, CloudWorkspaceStateGateway gateway})?>
  _cloudWorkspace(String workspaceId) async {
    final session = await _ref.read(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    final workspace = session.cloud;
    if (workspace == null) {
      return null;
    }

    final gateway = await _ref.read(
      cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
    );
    if (gateway == null) {
      throw StateError('Cloud workspace is unavailable');
    }

    return (workspace: workspace, gateway: gateway);
  }
}

ConversationLabelEntity conversationLabelFromCloud(
  ConversationLabelSummary label,
  String localWorkspaceId,
) => ConversationLabelEntity(
  id: label.id,
  workspaceId: localWorkspaceId,
  name: label.name,
  createdAt: label.createdAt,
  updatedAt: label.updatedAt,
);
