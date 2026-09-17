import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_send_queue_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/delete_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/stop_conversation_usecase.dart';
import 'package:riverpod/riverpod.dart';

final deleteConversationUsecaseProvider = Provider<DeleteConversationUsecase>((
  ref,
) {
  final stop = StopConversationUsecase(
    conversationRepository: ref.watch(conversationRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    cancellationRuntime: ref.watch(agentCancellationRuntimeProvider),
    sendQueueRuntime: ref.watch(conversationSendQueueRuntimeProvider),
    streamingRuntime: ref.watch(conversationStreamingRuntimeProvider),
    retryRuntime: ref.watch(conversationRateLimitRetryRuntimeProvider),
    activeSubAgents: ref.watch(activeSubAgentRuntimeProvider.notifier),
  );

  return DeleteConversationUsecase(
    ref.watch(conversationRepositoryProvider),
    stop.call,
    (id) => ref.watch(conversationRepositoryProvider).captureForkBoundaries(id),
  );
});
