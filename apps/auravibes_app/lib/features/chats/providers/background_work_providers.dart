import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final StreamProviderFamily<List<AgentBackgroundWork>, String>
conversationBackgroundWorksProvider = StreamProvider.autoDispose
    .family<List<AgentBackgroundWork>, String>(
      (ref, conversationId) => ref
          .watch(backgroundWorkRepositoryProvider)
          .watchConversation(conversationId),
    );

final FutureProviderFamily<
  List<AgentBackgroundWork>,
  ({String workspaceId, String conversationId})
>
cloudConversationBackgroundWorksProvider = FutureProvider.autoDispose
    .family<
      List<AgentBackgroundWork>,
      ({String workspaceId, String conversationId})
    >((ref, request) async {
      final _ = ref.watch(
        cloudConversationStateProvider((
          workspaceId: request.workspaceId,
          conversationId: request.conversationId,
        )).select((state) => state.value?.sequence),
      );
      final gateway = await ref.watch(
        cloudWorkspaceStateGatewayForWorkspaceProvider(request.workspaceId)
            .future,
      );
      if (gateway == null) return const [];

      final works = await CloudChatGateway(gateway)
          .listBackgroundWorks(request.conversationId);

      return [for (final work in works) _backgroundWorkFromView(work, request)];
    });

final StreamProviderFamily<bool, ({String conversationId, String toolCallId})>
toolBackgroundEligibilityProvider = StreamProvider.autoDispose
    .family<bool, ({String conversationId, String toolCallId})>(
      (ref, request) => ref
          .watch(agentCancellationRuntimeProvider)
          .watchCanRunToolInBackground(
            conversationId: request.conversationId,
            toolCallId: request.toolCallId,
          ),
    );

AgentBackgroundWork _backgroundWorkFromView(
  BackgroundWorkView view,
  ({String workspaceId, String conversationId}) request,
) => AgentBackgroundWork(
  identity: .new(
    id: view.id,
    workspaceId: request.workspaceId,
    conversationId: view.conversationId,
    toolCallId: view.toolCallId,
    toolKind: view.toolKind,
    originatingMessageId: view.originatingMessageId,
  ),
  state: .new(
    status: .values.byName(view.status),
    createdAt: view.createdAt,
    updatedAt: view.updatedAt,
    statusPreview: view.statusPreview,
    resultContent: view.resultContent,
    resultByteLength: view.resultByteLength,
    errorCode: view.errorCode,
  ),
);
