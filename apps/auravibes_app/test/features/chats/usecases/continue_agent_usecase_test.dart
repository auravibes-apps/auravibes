import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/streaming_runtime_provider.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'continue_agent_usecase_test.mocks.dart';

@GenerateMocks([
  ChatbotService,
  MessageRepository,
  WorkspaceModelSelectionRepository,
  ConversationRepository,
  LoadConversationToolSpecsUsecase,
  MonitoringService,
])
void main() {
  group('ContinueAgentUsecase', () {
    late MockChatbotService chatbotService;
    late MockMessageRepository messageRepository;
    late MockWorkspaceModelSelectionRepository
    workspaceModelSelectionsRepository;
    late MockConversationRepository conversationRepository;
    late MockLoadConversationToolSpecsUsecase loadConversationToolSpecsUsecase;
    late MockMonitoringService monitoringService;
    late ContinueAgentUsecase usecase;
    late List<String> removedMessageIds;
    late List<String> startedConversationIds;
    late List<String> removedConversationIds;
    late List<String> updatedMessageIds;
    late List<ChatResult<ChatMessage>> updatedResults;
    late List<String> startedSubscriptionMessageIds;
    late AgentCancellationRuntime agentCancellationRuntime;

    setUp(() {
      chatbotService = MockChatbotService();
      messageRepository = MockMessageRepository();
      workspaceModelSelectionsRepository =
          MockWorkspaceModelSelectionRepository();
      conversationRepository = MockConversationRepository();
      loadConversationToolSpecsUsecase = MockLoadConversationToolSpecsUsecase();
      monitoringService = MockMonitoringService();
      removedMessageIds = [];
      startedConversationIds = [];
      removedConversationIds = [];
      updatedMessageIds = [];
      updatedResults = [];
      startedSubscriptionMessageIds = [];
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = ContinueAgentUsecase(
        chatbotService: chatbotService,
        messageRepository: messageRepository,
        workspaceModelSelectionsRepository: workspaceModelSelectionsRepository,
        conversationRepository: conversationRepository,
        loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
        messagesStreamingRuntime: MessagesStreamingRuntime(
          startSubscription: (_, messageId) {
            startedSubscriptionMessageIds.add(messageId);
          },
          updateResult: (result, messageId) {
            updatedResults.add(result);
            updatedMessageIds.add(messageId);
          },
          remove: (messageId) async {
            removedMessageIds.add(messageId);
          },
        ),
        conversationStreamingRuntime: ConversationStreamingRuntime(
          start: startedConversationIds.add,
          isStreaming: (_) => false,
          remove: removedConversationIds.add,
        ),
        agentCancellationRuntime: agentCancellationRuntime,
        monitoringService: monitoringService,
      );

      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer((_) async => _conversation);
      when(
        messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer((_) async => [_userMessage]);
      when(
        workspaceModelSelectionsRepository.getWorkspaceModelSelectionById(
          'model-1',
        ),
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
        messageRepository.patchMessage(any, any),
      ).thenAnswer((_) async => _unfinishedAssistantMessage);
    });

    test(
      'uses the accumulated model stream as lastResult '
      'instead of persistence output',
      () async {
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            ChatResult<ChatMessage>(
              output: ChatMessage.model('Working'),
              usage: const LanguageModelUsage(
                promptTokens: 10,
                responseTokens: 5,
              ),
            ),
            ChatResult<ChatMessage>(
              output: ChatMessage.model(
                '',
                parts: const [
                  ToolPart.call(
                    callId: 'tool-1',
                    toolName: 'calculator',
                    arguments: {'input': '2+2'},
                  ),
                ],
              ),
              finishReason: FinishReason.toolCalls,
              usage: const LanguageModelUsage(
                responseTokens: 7,
              ),
            ),
          ]),
        );

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result.messageId, 'assistant-1');
        expect(result.hasToolCalls, isTrue);

        expect(startedConversationIds, ['conversation-1']);
        expect(startedSubscriptionMessageIds, ['assistant-1']);
        expect(updatedMessageIds, isNotEmpty);
        expect(removedMessageIds, ['assistant-1']);
        expect(removedConversationIds, ['conversation-1']);

        final updates = verify(
          messageRepository.patchMessage(
            'assistant-1',
            captureAny,
          ),
        ).captured;

        final streamingUpdate = updates.cast<MessagePatch>().firstWhere(
          (update) => update.metadata?.toolCalls.isNotEmpty ?? false,
        );

        expect(streamingUpdate.metadata?.toolCalls, hasLength(1));
        expect(streamingUpdate.metadata?.toolCalls.single.id, 'tool-1');
        expect(streamingUpdate.metadata?.promptTokens, 10);
        expect(streamingUpdate.metadata?.completionTokens, 12);
        expect(streamingUpdate.metadata?.totalTokens, isNull);
        expect(streamingUpdate.metadata?.usedTokens, 22);
      },
    );

    test(
      'marks the pending user message as sent on first model chunk',
      () async {
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            ChatResult<ChatMessage>(
              output: ChatMessage.model('Working'),
              finishReason: FinishReason.stop,
              usage: const LanguageModelUsage(),
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
          messageRepository.patchMessage(
            'user-1',
            const MessagePatch(status: MessageStatus.sent),
          ),
        ).called(1);

        expect(startedConversationIds, ['conversation-1']);
        expect(startedSubscriptionMessageIds, ['assistant-1']);
        expect(removedMessageIds, ['assistant-1']);
        expect(removedConversationIds, ['conversation-1']);
      },
    );

    test(
      'marks all pending user messages as sent on first model chunk',
      () async {
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            ChatResult<ChatMessage>(
              output: ChatMessage.model('Working'),
              finishReason: FinishReason.stop,
              usage: const LanguageModelUsage(),
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
          messageRepository.patchMessage(
            'user-1',
            const MessagePatch(status: MessageStatus.sent),
          ),
        ).called(1);
        verify(
          messageRepository.patchMessage(
            'user-2',
            const MessagePatch(status: MessageStatus.sent),
          ),
        ).called(1);

        expect(startedConversationIds, ['conversation-1']);
        expect(startedSubscriptionMessageIds, ['assistant-1']);
        expect(removedMessageIds, ['assistant-1']);
        expect(removedConversationIds, ['conversation-1']);
      },
    );

    test(
      'stops before the first chunk without creating an assistant error',
      () async {
        final controller = StreamController<ChatResult<ChatMessage>>();
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer((_) => controller.stream);

        final future = usecase.call(
          conversationId: 'conversation-1',
          context: const AgentIterationContext(
            origin: AgentIterationOrigin.userMessage,
            ackMessageIds: ['user-1'],
          ),
        );
        await Future<void>.delayed(Duration.zero);

        agentCancellationRuntime.requestStop('conversation-1');

        final result = await future;
        await controller.close();

        expect(result.hasToolCalls, isFalse);
        verifyNever(messageRepository.createMessage(any));
        verify(
          messageRepository.patchMessage(
            'user-1',
            const MessagePatch(status: MessageStatus.sent),
          ),
        ).called(1);
        verifyNever(
          messageRepository.patchMessage(
            'assistant-1',
            const MessagePatch(status: MessageStatus.error),
          ),
        );
      },
    );

    test(
      'preserves partial assistant text as sent when stopped during stream',
      () async {
        final controller = StreamController<ChatResult<ChatMessage>>();
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer((_) => controller.stream);

        final future = usecase.call(conversationId: 'conversation-1');
        controller.add(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Partial answer'),
            finishReason: FinishReason.stop,
            usage: const LanguageModelUsage(),
          ),
        );

        while (startedSubscriptionMessageIds.isEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
        agentCancellationRuntime.requestStop('conversation-1');

        final result = await future;
        await controller.close();

        expect(result.messageId, 'assistant-1');
        expect(result.hasToolCalls, isFalse);
        final patches = verify(
          messageRepository.patchMessage('assistant-1', captureAny),
        ).captured.cast<MessagePatch>();
        expect(
          patches.any(
            (patch) =>
                patch.content == 'Partial answer' &&
                patch.status == MessageStatus.sent,
          ),
          isTrue,
        );
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

final _model = WorkspaceModelSelectionWithConnectionEntity(
  workspaceModelSelection: WorkspaceModelSelectionEntity(
    id: 'model-1',
    modelId: 'gpt-4',
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
    modelConnectionId: 'credential-1',
  ),
  modelConnection: ModelConnectionEntity(
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
