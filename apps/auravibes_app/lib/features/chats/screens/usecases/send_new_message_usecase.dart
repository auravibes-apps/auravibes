import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/screens/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/screens/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class SendNewMessageUsecase {
  const SendNewMessageUsecase({
    required this.conversationRepo,
    required this.sendMessageUsecase,

    required this.credentialsRepository,
    required this.generateTitleUsecase,
  });

  final ConversationRepository conversationRepo;
  final SendMessageUsecase sendMessageUsecase;
  final CredentialsModelsRepository credentialsRepository;
  final GenerateTitleUsecase generateTitleUsecase;
  Future<void> call({
    required String workspaceId,
    required String firstMessage,
    required String credentialsModelId,
  }) async {
    // create conversation
    final newConversation = await conversationRepo.createConversation(
      .new(title: '', workspaceId: workspaceId),
    );

    final credentialsModel = await credentialsRepository
        .getCredentialsModelById(credentialsModelId);

    if (credentialsModel == null) {
      throw Exception('Selected model not found');
    }

    // stream title
    generateTitleUsecase.call(
      conversationId: newConversation.id,
      firstMessage: firstMessage,
      credentialsModel: credentialsModel,
    );

    await sendMessageUsecase.call(
      conversationId: newConversation.id,
      content: firstMessage,
    );
  }
}

final sendNewMessageUsecaseProvider = Provider<SendNewMessageUsecase>(
  (ref) {
    return SendNewMessageUsecase(
      conversationRepo: ref.watch(conversationRepositoryProvider),
      sendMessageUsecase: ref.watch(sendMessageUsecaseProvider),
      credentialsRepository: ref.watch(credentialsModelsRepositoryProvider),
      generateTitleUsecase: ref.watch(generateTitleUsecaseProvider),
    );
  },
);
