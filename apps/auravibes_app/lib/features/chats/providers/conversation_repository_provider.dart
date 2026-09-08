// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ConversationRepository conversationRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  final attachmentFileStore = ref.watch(attachmentFileStoreProvider);

  return ConversationRepository(
    appDatabase,
    attachmentFileStore: attachmentFileStore,
  );
}

@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  final attachmentFileStore = ref.watch(attachmentFileStoreProvider);

  return MessageRepository(
    appDatabase,
    attachmentFileStore: attachmentFileStore,
  );
}
