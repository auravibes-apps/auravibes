import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_label_actions.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_labels_provider.g.dart';

@riverpod
Stream<List<ConversationLabelEntity>> conversationLabelsStream(
  Ref ref,
  String workspaceId,
) async* {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (!ref.mounted) return;
  if (session.cloud case final cloud?) {
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayForWorkspaceProvider(workspaceId).future,
    );
    if (gateway == null) return;
    Future<({List<ConversationLabelEntity> value, int currentSequence})>
    read() async {
      final state = await gateway.read(pages: const [], eventLimit: 0);
      final labels = await gateway.client.conversation.listLabels(
        .new(workspaceId: cloud.cloudWorkspaceId),
      );

      return (
        value: labels
            .map((label) => conversationLabelFromCloud(label, workspaceId))
            .toList(),
        currentSequence: state.currentSequence,
      );
    }

    yield* gateway.watch(const {'conversation'}, read);

    return;
  }

  yield* ref
      .watch(conversationLabelsRepositoryProvider)
      .watchLabelsByWorkspace(workspaceId);
}

@Riverpod(keepAlive: true)
ConversationLabelActions conversationLabelActions(Ref ref) =>
    ConversationLabelActions(ref);
