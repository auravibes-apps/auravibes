import 'package:auravibes_app/features/chats/models/background_work_continuation_preview.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_stream.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

typedef BackgroundWorkContinuationKey = ({
  String workspaceId,
  String conversationId,
});

typedef BackgroundWorkDetachCommand = Future<BackgroundWorkView> Function({
  required String requestId,
  required String toolCallId,
});

final ProviderFamily<
  List<ConversationToolCallView>,
  BackgroundWorkContinuationKey
>
backgroundDetachableToolCallsProvider = Provider.autoDispose
    .family<List<ConversationToolCallView>, BackgroundWorkContinuationKey>((
      ref,
      key,
    ) {
      final conversation = ref.watch(
        cloudConversationStateProvider((
          workspaceId: key.workspaceId,
          conversationId: key.conversationId,
        )),
      );

      return conversation.value?.toolCalls
              .where(
                (call) =>
                    call.backgroundEligible &&
                    call.status == 'running' &&
                    call.backgroundWorkStableId == null,
              )
              .toList(growable: false) ??
          const [];
    });

final ProviderFamily<BackgroundWorkDetachCommand, BackgroundWorkContinuationKey>
backgroundWorkDetachCommandProvider = Provider.autoDispose
    .family<BackgroundWorkDetachCommand, BackgroundWorkContinuationKey>((
      ref,
      key,
    ) {
      return ({required requestId, required toolCallId}) async {
        final session = await ref.read(
          workspaceSessionForRouteProvider(key.workspaceId).future,
        );
        if (session.cloud == null) {
          throw StateError('Background detachment requires a cloud workspace.');
        }
        final gateway = await ref.read(
          cloudWorkspaceStateGatewayProvider(session).future,
        );
        if (gateway == null) {
          throw StateError('The cloud workspace connection is unavailable.');
        }

        return await CloudChatGateway(gateway).detachToolCall(
          requestId: requestId,
          conversationId: key.conversationId,
          toolCallId: toolCallId,
        );
      };
    });

final FutureProviderFamily<
  List<BackgroundWorkView>,
  BackgroundWorkContinuationKey
>
backgroundWorkContinuationsProvider = FutureProvider.autoDispose
    .family<List<BackgroundWorkView>, BackgroundWorkContinuationKey>((
      ref,
      key,
    ) async {
      final _ = ref.watch(
        cloudConversationStateProvider((
          workspaceId: key.workspaceId,
          conversationId: key.conversationId,
        )),
      );
      final session = await ref.watch(
        workspaceSessionForRouteProvider(key.workspaceId).future,
      );
      if (session.cloud == null) return const [];
      final gateway = await ref.watch(
        cloudWorkspaceStateGatewayProvider(session).future,
      );
      if (gateway == null) return const [];

      final works = await CloudChatGateway(gateway)
          .listBackgroundWorks(key.conversationId);

      return works
          .where(
            (work) =>
                _inspectableContinuationPreviews.contains(work.statusPreview),
          )
          .toList(growable: false);
    });

const Set<String> _inspectableContinuationPreviews = {
  BackgroundWorkContinuationPreview.queued,
  BackgroundWorkContinuationPreview.inProgress,
  BackgroundWorkContinuationPreview.failed,
};
