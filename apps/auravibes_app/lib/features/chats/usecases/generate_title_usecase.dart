// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:auravibes_app/utils/coalescing_save_extension.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

class const GenerateTitleUsecase({
  required final ConversationRepository conversationRepo,
  required final ChatbotService chatbotService,
  required final TitlesStreamingRuntime titlesStreamingRuntime,
  required final MonitoringService monitoringService,
}) {
  void call({
    required String conversationId,
    required String firstMessage,
    required WorkspaceModelSelectionWithConnectionEntity
    workspaceModelSelection,
  }) => _startTitleStreaming((
    conversationId: conversationId,
    firstMessage: firstMessage,
    workspaceModelSelection: workspaceModelSelection,
    conversationRepo: conversationRepo,
    chatbotService: chatbotService,
    titlesStreamingRuntime: titlesStreamingRuntime,
    monitoringService: monitoringService,
  ));
}

typedef _TitleStreamingRequest = ({
  String conversationId,
  String firstMessage,
  WorkspaceModelSelectionWithConnectionEntity workspaceModelSelection,
  ConversationRepository conversationRepo,
  ChatbotService chatbotService,
  TitlesStreamingRuntime titlesStreamingRuntime,
  MonitoringService monitoringService,
});

void _startTitleStreaming(_TitleStreamingRequest request) {
  final sharedStream = _sharedTitleStream(request);
  _listenForTitleUpdates(sharedStream, request);
  _persistTitleUpdates(sharedStream, request);
}

Stream<String> _sharedTitleStream(_TitleStreamingRequest request) => request
    .chatbotService
    .streamTitle(request.workspaceModelSelection, request.firstMessage)
    .doOnError((error, stackTrace) {
      request.monitoringService.trackError(
        'Error streaming title',
        error: error,
        stackTrace: stackTrace,
      );
      request.titlesStreamingRuntime.removeTitle(request.conversationId);
    })
    .share();

void _listenForTitleUpdates(
  Stream<String> sharedStream,
  _TitleStreamingRequest request,
) {
  final _ = sharedStream
      .doOnDone(
        () =>
            request.titlesStreamingRuntime.removeTitle(request.conversationId),
      )
      .listen((title) {
        request.titlesStreamingRuntime.updateTitle(
          request.conversationId,
          title,
        );
      });
}

void _persistTitleUpdates(
  Stream<String> sharedStream,
  _TitleStreamingRequest request,
) {
  final _ = sharedStream
      .coalescingSave(
        store: (title) async {
          final _ = await request.conversationRepo.patchConversation(
            request.conversationId,
            .new(title: title),
          );
        },
      )
      .listen(null);
}

final generateTitleUsecaseProvider = Provider<GenerateTitleUsecase>((ref) {
  return GenerateTitleUsecase(
    conversationRepo: ref.watch(conversationRepositoryProvider),
    chatbotService: ref.watch(chatbotServiceProvider),
    titlesStreamingRuntime: ref.watch(titlesStreamingRuntimeProvider),
    monitoringService: ref.watch(monitoringServiceProvider),
  );
});
