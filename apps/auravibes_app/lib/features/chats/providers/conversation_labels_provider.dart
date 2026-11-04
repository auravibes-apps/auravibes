import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_label_actions.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_labels_provider.g.dart';

@riverpod
Stream<List<ConversationLabelEntity>> conversationLabelsStream(
  Ref ref,
  String workspaceId,
) => _conversationLabelsForWorkspace(ref, workspaceId);

Stream<List<ConversationLabelEntity>> _conversationLabelsForWorkspace(
  Ref ref,
  String workspaceId,
) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) return;
  if (session.cloud case final cloud?) {
    yield* _cloudConversationLabels(ref, workspaceId, cloud);

    return;
  }

  yield* ref
      .watch(conversationLabelsRepositoryProvider)
      .watchLabelsByWorkspace(workspaceId);
}

Stream<List<ConversationLabelEntity>> _cloudConversationLabels(
  Ref ref,
  String workspaceId,
  CloudWorkspaceRef cloud,
) async* {
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
  );
  if (gateway == null) return;

  yield* _watchCloudConversationLabels(gateway, workspaceId, cloud);
}

Stream<List<ConversationLabelEntity>> _watchCloudConversationLabels(
  CloudWorkspaceStateGateway gateway,
  String workspaceId,
  CloudWorkspaceRef cloud,
) {
  Future<({List<ConversationLabelEntity> value, int currentSequence})> read() =>
      _readCloudConversationLabels(gateway, workspaceId, cloud);

  return gateway.watch(const {'conversation'}, read);
}

Future<({List<ConversationLabelEntity> value, int currentSequence})>
_readCloudConversationLabels(
  CloudWorkspaceStateGateway gateway,
  String workspaceId,
  CloudWorkspaceRef cloud,
) async {
  final state = await gateway.read(pages: const [], eventLimit: 0);
  final labels = await gateway.client.conversation.listLabels(
    .new(workspaceId: cloud.cloudWorkspaceId),
  );

  return (
    value: labels
        .map((label) => ConversationLabelMapper.fromCloud(label, workspaceId))
        .toList(),
    currentSequence: state.currentSequence,
  );
}

@Riverpod(keepAlive: true)
ConversationLabelActions conversationLabelActions(Ref ref) =>
    ConversationLabelActions(ref);
