import 'package:auravibes_app/data/repositories/background_work_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/background_work_coordinator.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/riverpod.dart';

final backgroundWorkRepositoryProvider = Provider<BackgroundWorkRepository>(
  (ref) => BackgroundWorkRepository(ref.watch(appDatabaseProvider)),
);

final backgroundWorkCoordinatorProvider = Provider<BackgroundWorkCoordinator>((
  ref,
) {
  final conversationRepository = ref.watch(conversationRepositoryProvider);
  return BackgroundWorkCoordinator(
    ref.watch(backgroundWorkRepositoryProvider),
    ref.watch(agentCancellationRuntimeProvider),
    (conversationId) async =>
        (await conversationRepository.getConversationById(conversationId))
            ?.workspaceId,
  );
});
