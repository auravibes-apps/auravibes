import 'package:auravibes_app/data/repositories/conversation_archive_state_repository.dart';
import 'package:auravibes_app/features/chats/usecases/set_conversation_archived_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final conversationArchiveStateRepositoryProvider =
    Provider<ConversationArchiveStateRepository>((ref) {
      return ConversationArchiveStateRepository(ref.watch(appDatabaseProvider));
    });

final StreamProviderFamily<Set<String>, String>
conversationArchiveStateIdsProvider =
    StreamProvider.family<Set<String>, String>(
      (ref, workspaceId) => ref
          .watch(conversationArchiveStateRepositoryProvider)
          .watchArchivedConversationIds(workspaceId),
    );

final setConversationArchivedUsecaseProvider =
    Provider<SetConversationArchivedUsecase>((ref) {
      return SetConversationArchivedUsecase(
        repository: ref.watch(conversationArchiveStateRepositoryProvider),
      );
    });
