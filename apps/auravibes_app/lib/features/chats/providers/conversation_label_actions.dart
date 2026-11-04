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
  }) => _withWorkspace(
    workspaceId,
    local: (repository) =>
        repository.createLabel(workspaceId: workspaceId, name: name),
    cloud: (workspace) => _createCloudLabel(workspace, workspaceId, name),
  );

  Future<ConversationLabelEntity> rename({
    required String workspaceId,
    required String labelId,
    required String name,
  }) => _withWorkspace(
    workspaceId,
    local: (repository) => repository.renameLabel(
      workspaceId: workspaceId,
      labelId: labelId,
      name: name,
    ),
    cloud: (workspace) =>
        _renameCloudLabel(workspace, workspaceId, labelId, name),
  );

  Future<void> delete({
    required String workspaceId,
    required String labelId,
  }) => _withWorkspace(
    workspaceId,
    local: (repository) =>
        repository.deleteLabel(workspaceId: workspaceId, labelId: labelId),
    cloud: (workspace) => _deleteCloudLabel(workspace, labelId),
  );

  Future<void> assign({
    required String workspaceId,
    required String conversationId,
    required Set<String> labelIds,
  }) => _withWorkspace(
    workspaceId,
    local: (repository) => repository.setConversationLabels(
      workspaceId: workspaceId,
      conversationId: conversationId,
      labelIds: labelIds,
    ),
    cloud: (workspace) => _assignCloudLabels(
      workspace,
      conversationId,
      labelIds,
    ),
  );

  Future<ConversationLabelEntity> _createCloudLabel(
    ({CloudWorkspaceRef workspace, CloudWorkspaceStateGateway gateway}) cloud,
    String workspaceId,
    String name,
  ) async {
    final labelId = const UuidV7().generate();
    final label = await cloud.gateway.client.conversation.createLabel(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        labelId: labelId,
        name: name,
      ),
    );

    return ConversationLabelMapper.fromCloud(label, workspaceId);
  }

  Future<ConversationLabelEntity> _renameCloudLabel(
    ({CloudWorkspaceRef workspace, CloudWorkspaceStateGateway gateway}) cloud,
    String workspaceId,
    String labelId,
    String name,
  ) async {
    final label = await cloud.gateway.client.conversation.renameLabel(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        labelId: labelId,
        name: name,
      ),
    );

    return ConversationLabelMapper.fromCloud(label, workspaceId);
  }

  Future<void> _deleteCloudLabel(
    ({CloudWorkspaceRef workspace, CloudWorkspaceStateGateway gateway}) cloud,
    String labelId,
  ) async {
    await cloud.gateway.client.conversation.deleteLabel(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        labelId: labelId,
      ),
    );
  }

  Future<void> _assignCloudLabels(
    ({CloudWorkspaceRef workspace, CloudWorkspaceStateGateway gateway}) cloud,
    String conversationId,
    Set<String> labelIds,
  ) async {
    await cloud.gateway.client.conversation.setConversationLabels(
      .new(
        workspaceId: cloud.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        conversationId: conversationId,
        labelIds: labelIds.toList()..sort(),
      ),
    );
  }

  Future<T> _withWorkspace<T>(
    String workspaceId, {
    required Future<T> Function(ConversationLabelsRepository) local,
    required Future<T> Function(
      ({CloudWorkspaceRef workspace, CloudWorkspaceStateGateway gateway}),
    ) cloud,
  }) async {
    final workspace = await _cloudWorkspace(workspaceId);
    if (workspace == null) {
      return await local(_ref.read(conversationLabelsRepositoryProvider));
    }

    return await cloud(workspace);
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

abstract final class ConversationLabelMapper {
  static ConversationLabelEntity fromCloud(
    ConversationLabelSummary label,
    String localWorkspaceId,
  ) => ConversationLabelEntity(
    id: label.id,
    workspaceId: localWorkspaceId,
    name: label.name,
    createdAt: label.createdAt,
    updatedAt: label.updatedAt,
  );
}
