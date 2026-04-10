import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/streaming_runtime_provider.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

class GenerateTitleUsecase {
  const GenerateTitleUsecase({
    required this.conversationRepo,
    required this.chatbotService,
    required this.titlesStreamingRuntime,
    required this.monitoringService,
  });

  final ConversationRepository conversationRepo;
  final ChatbotService chatbotService;
  final TitlesStreamingRuntime titlesStreamingRuntime;
  final MonitoringService monitoringService;
  void call({
    required String conversationId,
    required String firstMessage,
    required CredentialsModelWithProviderEntity credentialsModel,
  }) {
    // stream title
    final stream = chatbotService.streamTitle(
      credentialsModel,
      firstMessage,
    );

    final sharedStream = stream.doOnError((error, stackTrace) {
      monitoringService.trackError(
        'Error streaming title',
        error: error,
        stackTrace: stackTrace,
      );
      titlesStreamingRuntime.removeTitle(conversationId);
    }).share();

    sharedStream
        .doOnDone(() => titlesStreamingRuntime.removeTitle(conversationId))
        .listen((title) {
          titlesStreamingRuntime.updateTitle(conversationId, title);
        });

    sharedStream
        .coalescingSave(
          store: (t) async {
            await conversationRepo.updateConversation(
              conversationId,
              .new(
                title: t,
              ),
            );
          },
        )
        .listen(null);
  }
}

final generateTitleUsecaseProvider = Provider<GenerateTitleUsecase>(
  (ref) {
    return GenerateTitleUsecase(
      conversationRepo: ref.watch(conversationRepositoryProvider),
      chatbotService: ref.watch(chatbotServiceProvider),
      titlesStreamingRuntime: ref.watch(titlesStreamingRuntimeProvider),
      monitoringService: ref.watch(monitoringServiceProvider),
    );
  },
);
