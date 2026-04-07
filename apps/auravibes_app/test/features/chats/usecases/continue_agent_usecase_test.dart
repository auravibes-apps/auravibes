import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/credentials_entities.dart';
import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'continue_agent_usecase_test.mocks.dart';

@GenerateMocks([
  ChatbotService,
  MessageRepository,
  CredentialsModelsRepository,
  ConversationRepository,
  LoadConversationToolSpecsUsecase,
  MessagesStreamingNotifier,
  ConversationStreamingNotifier,
  MonitoringService,
])
void main() {
  group('ContinueAgentUsecase', () {
    late MockChatbotService chatbotService;
    late MockMessageRepository messageRepository;
    late MockCredentialsModelsRepository credentialsModelsRepository;
    late MockConversationRepository conversationRepository;
    late MockLoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;
    late MockMessagesStreamingNotifier messagesStreamingNotifier;
    late MockConversationStreamingNotifier conversationStreamingNotifier;
    late MockMonitoringService monitoringService;
    late ContinueAgentUsecase usecase;

    setUp(() {
      chatbotService = MockChatbotService();
      messageRepository = MockMessageRepository();
      credentialsModelsRepository = MockCredentialsModelsRepository();
      conversationRepository = MockConversationRepository();
      loadConversationToolSpecsUsecase = MockLoadConversationToolSpecsUsecase();
      messagesStreamingNotifier = MockMessagesStreamingNotifier();
      conversationStreamingNotifier = MockConversationStreamingNotifier();
      monitoringService = MockMonitoringService();

      usecase = ContinueAgentUsecase(
        chatbotService: chatbotService,
        messageRepository: messageRepository,
        credentialsModelsRepository: credentialsModelsRepository,
        conversationRepository: conversationRepository,
        loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
        messagesStreamingNotifier: messagesStreamingNotifier,
        conversationStreamingNotifier: conversationStreamingNotifier,
        monitoringService: monitoringService,
      );

      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer((_) async => _conversation);
      when(
        messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer((_) async => [_userMessage]);
      when(
        credentialsModelsRepository.getCredentialsModelById('model-1'),
      ).thenAnswer((_) async => _model);
      when(
        loadConversationToolSpecsUsecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        ),
      ).thenAnswer((_) async => const []);
      when(
        messageRepository.createMessage(any),
      ).thenAnswer((_) async => _unfinishedAssistantMessage);
      when(
        messageRepository.updateMessage(any, any),
      ).thenAnswer((_) async => _unfinishedAssistantMessage);
      when(
        messagesStreamingNotifier.remove(any),
      ).thenAnswer((_) async {});
    });

    test(
      'uses the accumulated model stream as lastResult '
      'instead of persistence output',
      () async {
        when(
          chatbotService.sendMessage(
            _model,
            [_userMessage],
            tools: const [],
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const ChatResult(
              id: 'chunk-1',
              output: AIChatMessage(content: 'Working'),
              finishReason: FinishReason.unspecified,
              metadata: {},
              usage: LanguageModelUsage(),
              streaming: true,
            ),
            const ChatResult(
              id: 'chunk-2',
              output: AIChatMessage(
                content: '',
                toolCalls: [
                  AIChatMessageToolCall(
                    id: 'tool-1',
                    name: 'calculator',
                    argumentsRaw: '{"input":"2+2"}',
                    arguments: {'input': '2+2'},
                  ),
                ],
              ),
              finishReason: FinishReason.toolCalls,
              metadata: {},
              usage: LanguageModelUsage(),
              streaming: true,
            ),
          ]),
        );

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result.messageId, 'assistant-1');
        expect(result.hasToolCalls, isTrue);

        final updates = verify(
          messageRepository.updateMessage(
            'assistant-1',
            captureAny,
          ),
        ).captured;

        final streamingUpdate = updates.cast<MessageToUpdate>().firstWhere(
          (update) => update.metadata != null,
        );

        expect(streamingUpdate.metadata?.toolCalls, hasLength(1));
        expect(streamingUpdate.metadata?.toolCalls.single.id, 'tool-1');
      },
    );

    test(
      'marks the pending user message as sent on first model chunk',
      () async {
        when(
          chatbotService.sendMessage(
            _model,
            [_userMessage],
            tools: const [],
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const ChatResult(
              id: 'chunk-1',
              output: AIChatMessage(content: 'Working'),
              finishReason: FinishReason.stop,
              metadata: {},
              usage: LanguageModelUsage(),
              streaming: true,
            ),
          ]),
        );

        await usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );

        verify(
          messageRepository.updateMessage(
            'user-1',
            const MessageToUpdate(status: MessageStatus.sent),
          ),
        ).called(1);
      },
    );

    test(
      'marks all pending user messages as sent on first model chunk',
      () async {
        when(
          chatbotService.sendMessage(
            _model,
            [_userMessage],
            tools: const [],
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const ChatResult(
              id: 'chunk-1',
              output: AIChatMessage(content: 'Working'),
              finishReason: FinishReason.stop,
              metadata: {},
              usage: LanguageModelUsage(),
              streaming: true,
            ),
          ]),
        );

        await usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1', 'user-2'],
          ),
        );

        verify(
          messageRepository.updateMessage(
            'user-1',
            const MessageToUpdate(status: MessageStatus.sent),
          ),
        ).called(1);
        verify(
          messageRepository.updateMessage(
            'user-2',
            const MessageToUpdate(status: MessageStatus.sent),
          ),
        ).called(1);
      },
    );
  });
}

final _conversation = ConversationEntity(
  id: 'conversation-1',
  title: 'Conversation 1',
  workspaceId: 'workspace-1',
  isPinned: false,
  modelId: 'model-1',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _userMessage = MessageEntity(
  id: 'user-1',
  conversationId: 'conversation-1',
  content: 'What is 2 + 2?',
  messageType: MessageType.text,
  isUser: true,
  status: MessageStatus.sent,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _unfinishedAssistantMessage = MessageEntity(
  id: 'assistant-1',
  conversationId: 'conversation-1',
  content: 'Working',
  messageType: MessageType.text,
  isUser: false,
  status: MessageStatus.unfinished,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _model = CredentialsModelWithProviderEntity(
  credentialsModel: CredentialsModelEntity(
    id: 'model-1',
    modelId: 'gpt-4',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
    credentialsId: 'credential-1',
  ),
  credentials: CredentialsEntity(
    id: 'credential-1',
    name: 'Main credential',
    key: 'secret',
    modelId: 'model-1',
    workspaceId: 'workspace-1',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  ),
  modelsProvider: const ApiModelProviderEntity(
    id: 'provider-1',
    name: 'OpenAI',
    type: ModelProvidersType.openai,
  ),
);
