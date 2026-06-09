

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/agent_iteration_context.dart';
import 'package:auravibes_app/features/chats/usecases/continue_agent_result.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_context_messages_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' hide FinishReason;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'continue_agent_usecase_test.mocks.dart';

@GenerateMocks([
  ChatbotService,
  MessageRepository,
  WorkspaceModelSelectionRepository,
  ConversationRepository,
  LoadConversationToolSpecsUsecase,
  MonitoringService,
  SelectPromptMessagesUsecase,
])
void main() {
  group('ContinueAgentUsecase', () {
    var chatbotService = MockChatbotService();
    var messageRepository = MockMessageRepository();
    var workspaceModelSelectionsRepository =
        MockWorkspaceModelSelectionRepository();
    var conversationRepository = MockConversationRepository();
    var loadConversationToolSpecsUsecase =
        MockLoadConversationToolSpecsUsecase();
    var monitoringService = MockMonitoringService();
    var selectPromptMessagesUsecase = MockSelectPromptMessagesUsecase();
    var removedMessageIds = <String>[];
    var startedConversationIds = <String>[];
    var removedConversationIds = <String>[];
    var updatedMessageIds = <String>[];
    var updatedResults = <ChatResult<ChatMessage>>[];
    var startedSubscriptionMessageIds = <String>[];
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    var usecase = ContinueAgentUsecase(
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
        remove: (messageId) {
          removedMessageIds.add(messageId);

          return Future<void>.value();
        },
      ),
      conversationStreamingRuntime: ConversationStreamingRuntime(
        start: startedConversationIds.add,
        isStreaming: (_) => false,
        remove: removedConversationIds.add,
      ),
      agentCancellationRuntime: agentCancellationRuntime,
      monitoringService: monitoringService,
      selectPromptMessagesUsecase: selectPromptMessagesUsecase,
      buildSkillContextMessagesUsecase:
          const _FakeBuildSkillContextMessagesUsecase([]),
    );

    setUp(() {
      chatbotService = MockChatbotService();
      messageRepository = MockMessageRepository();
      workspaceModelSelectionsRepository =
          MockWorkspaceModelSelectionRepository();
      conversationRepository = MockConversationRepository();
      loadConversationToolSpecsUsecase = MockLoadConversationToolSpecsUsecase();
      monitoringService = MockMonitoringService();
      selectPromptMessagesUsecase = MockSelectPromptMessagesUsecase();
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
          remove: (messageId) {
            removedMessageIds.add(messageId);

            return Future<void>.value();
          },
        ),
        conversationStreamingRuntime: ConversationStreamingRuntime(
          start: startedConversationIds.add,
          isStreaming: (_) => false,
          remove: removedConversationIds.add,
        ),
        agentCancellationRuntime: agentCancellationRuntime,
        monitoringService: monitoringService,
        selectPromptMessagesUsecase: selectPromptMessagesUsecase,
        buildSkillContextMessagesUsecase:
            const _FakeBuildSkillContextMessagesUsecase([]),
      );

      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer((_) async => _conversation);
      when(
        messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer((_) async => [_userMessage]);
      when(
        selectPromptMessagesUsecase.call('conversation-1'),
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
                parts: [
                  ToolRequestPart(
                    toolRequest: ToolRequest(
                      ref: 'tool-1',
                      name: 'calculator',
                      input: const {'input': '2+2'},
                    ),
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
      'sends loaded skill context as user XML before prompt messages',
      () async {
        usecase = ContinueAgentUsecase(
          chatbotService: chatbotService,
          messageRepository: messageRepository,
          workspaceModelSelectionsRepository:
              workspaceModelSelectionsRepository,
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
            remove: (messageId) {
              removedMessageIds.add(messageId);

              return Future<void>.value();
            },
          ),
          conversationStreamingRuntime: ConversationStreamingRuntime(
            start: startedConversationIds.add,
            isStreaming: (_) => false,
            remove: removedConversationIds.add,
          ),
          agentCancellationRuntime: agentCancellationRuntime,
          monitoringService: monitoringService,
          selectPromptMessagesUsecase: selectPromptMessagesUsecase,
          buildSkillContextMessagesUsecase:
              const _FakeBuildSkillContextMessagesUsecase([
                ChatMessage(
                  role: ChatMessageRole.user,
                  content: _skillContextXml,
                  metadata: {'kind': skillContextMetadataKind},
                ),
              ]),
        );
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer((invocation) {
          final history =
              invocation.positionalArguments[1] as List<ChatMessage>;
          expect(history.firstOrNull?.role, ChatMessageRole.user);
          expect(
            history.firstOrNull?.metadata['kind'],
            skillContextMetadataKind,
          );
          expect(history.firstOrNull?.text, contains('<skill>'));
          expect(history.firstOrNull?.toolResults, isEmpty);

          return Stream.fromIterable([
            ChatResult<ChatMessage>(
              output: ChatMessage.model('Done'),
              finishReason: FinishReason.stop,
              usage: const LanguageModelUsage(),
            ),
          ]);
        });

        final result = await usecase.call(conversationId: 'conversation-1');

        expect(result.hasToolCalls, isFalse);
      },
    );

    test('ignores empty chunks until text is available', () async {
      when(
        chatbotService.sendMessage(
          _model,
          any,
          tools: const [],
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          ChatResult<ChatMessage>(
            output: ChatMessage.model(''),
            usage: const LanguageModelUsage(),
          ),
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Done'),
            finishReason: FinishReason.stop,
            usage: const LanguageModelUsage(),
          ),
        ]),
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.messageId, 'assistant-1');
      expect(result.hasToolCalls, isFalse);
      expect(startedSubscriptionMessageIds, ['assistant-1']);
      expect(updatedResults, hasLength(1));
      expect(updatedResults.single.entityText, 'Done');

      final created =
          verify(
                messageRepository.createMessage(captureAny),
              ).captured.single
              as MessageToCreate;
      expect(created.content, 'Done');
      expect(created.metadata, isNull);
    });

    test('persists metadata-only tool call as assistant message', () async {
      when(
        chatbotService.sendMessage(
          _model,
          any,
          tools: const [],
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          ChatResult<ChatMessage>(
            output: ChatMessage.model(
              '',
              parts: [
                ToolRequestPart(
                  toolRequest: ToolRequest(
                    ref: 'tool-1',
                    name: 'calculator',
                    input: const {'input': '2+2'},
                  ),
                ),
              ],
            ),
            finishReason: FinishReason.toolCalls,
            usage: const LanguageModelUsage(),
          ),
        ]),
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.messageId, 'assistant-1');
      expect(result.hasToolCalls, isTrue);

      final created =
          verify(
                messageRepository.createMessage(captureAny),
              ).captured.single
              as MessageToCreate;
      expect(created.content, isEmpty);
      expect(created.metadata, isNotNull);

      final rawMetadata = created.metadata;
      final metadata =
          jsonDecode(
                rawMetadata ?? fail('Expected tool call metadata'),
              )
              as Map<String, dynamic>;
      final toolCalls = metadata['toolCalls'] as List<dynamic>;
      expect(toolCalls, hasLength(1));
      expect(toolCalls.single, containsPair('id', 'tool-1'));
      expect(toolCalls.single, containsPair('name', 'calculator'));
    });

    test('skips empty chunks with non-encodable metadata', () async {
      when(
        chatbotService.sendMessage(
          _model,
          any,
          tools: const [],
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          ChatResult<ChatMessage>(
            output: ChatMessage.model(
              '',
              metadata: {'bad': Object()},
            ),
            usage: const LanguageModelUsage(),
          ),
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Done'),
            finishReason: FinishReason.stop,
            usage: const LanguageModelUsage(),
          ),
        ]),
      );

      final result = await usecase.call(conversationId: 'conversation-1');

      expect(result.messageId, 'assistant-1');
      expect(startedSubscriptionMessageIds, ['assistant-1']);
      expect(updatedResults, hasLength(1));
      expect(updatedResults.single.entityText, 'Done');

      final created =
          verify(
                messageRepository.createMessage(captureAny),
              ).captured.single
              as MessageToCreate;
      expect(created.content, 'Done');
      expect(created.metadata, isNull);
    });

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

        final _ = await usecase.call(
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

        final _ = await usecase.call(
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
        final _ = await controller.close();

        expect(result.hasToolCalls, isFalse);
        final _ = verifyNever(messageRepository.createMessage(any));
        verify(
          messageRepository.patchMessage(
            'user-1',
            const MessagePatch(status: MessageStatus.sent),
          ),
        ).called(1);
        final _ = verifyNever(
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
        final _ = await controller.close();

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

    test(
      'marks streamed pending tool calls as stopped when stopped',
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
            output: ChatMessage.model(
              '',
              parts: [
                ToolRequestPart(
                  toolRequest: ToolRequest(
                    ref: 'tool-1',
                    name: 'calculator',
                    input: const {'input': '2+2'},
                  ),
                ),
              ],
            ),
            finishReason: FinishReason.toolCalls,
            usage: const LanguageModelUsage(),
          ),
        );

        while (startedSubscriptionMessageIds.isEmpty) {
          await Future<void>.delayed(Duration.zero);
        }
        agentCancellationRuntime.requestStop('conversation-1');

        final result = await future;
        final _ = await controller.close();

        expect(result.hasToolCalls, isFalse);
        final patches = verify(
          messageRepository.patchMessage('assistant-1', captureAny),
        ).captured.cast<MessagePatch>();
        final stoppedPatch = patches.lastWhere(
          (patch) => patch.status == MessageStatus.sent,
        );
        expect(
          stoppedPatch.metadata?.toolCalls.single.resultStatus,
          ToolCallResultStatus.stoppedByUser,
        );
      },
    );

    test(
      'waits for in-flight chunk persistence before completing stop',
      () async {
        final controller = StreamController<ChatResult<ChatMessage>>();
        final createStarted = Completer<void>();
        final createCompleter = Completer<MessageEntity>();
        when(
          chatbotService.sendMessage(
            _model,
            any,
            tools: const [],
          ),
        ).thenAnswer((_) => controller.stream);
        when(messageRepository.createMessage(any)).thenAnswer((_) {
          if (!createStarted.isCompleted) {
            createStarted.complete();
          }

          return createCompleter.future;
        });

        final future = usecase.call(conversationId: 'conversation-1');
        controller.add(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Partial answer'),
            finishReason: FinishReason.stop,
            usage: const LanguageModelUsage(),
          ),
        );
        await createStarted.future;

        var didComplete = false;
        Future<void> markComplete() async {
          final _ = await future;
          didComplete = true;
        }

        unawaited(markComplete());
        agentCancellationRuntime.requestStop('conversation-1');
        await Future<void>.delayed(Duration.zero);

        expect(didComplete, isFalse);

        createCompleter.complete(_unfinishedAssistantMessage);
        final result = await future;
        final _ = await controller.close();

        expect(result.messageId, 'assistant-1');
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

  group('ContinueAgentUsecase error paths', () {
    var chatbotService = MockChatbotService();
    var messageRepository = MockMessageRepository();
    var workspaceModelSelectionsRepository =
        MockWorkspaceModelSelectionRepository();
    var conversationRepository = MockConversationRepository();
    var loadConversationToolSpecsUsecase =
        MockLoadConversationToolSpecsUsecase();
    var monitoringService = MockMonitoringService();
    var selectPromptMessagesUsecase = MockSelectPromptMessagesUsecase();
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    var usecase = ContinueAgentUsecase(
      chatbotService: chatbotService,
      messageRepository: messageRepository,
      workspaceModelSelectionsRepository: workspaceModelSelectionsRepository,
      conversationRepository: conversationRepository,
      loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
      messagesStreamingRuntime: MessagesStreamingRuntime(
        startSubscription: (_, _) {
          final _ = Object();
        },
        updateResult: (_, _) {
          final _ = Object();
        },
        remove: (_) {
          return Future<void>.value();
        },
      ),
      conversationStreamingRuntime: ConversationStreamingRuntime(
        start: (_) {
          final _ = Object();
        },
        isStreaming: (_) => false,
        remove: (_) {
          final _ = Object();
        },
      ),
      agentCancellationRuntime: agentCancellationRuntime,
      monitoringService: monitoringService,
      selectPromptMessagesUsecase: selectPromptMessagesUsecase,
    );

    setUp(() {
      chatbotService = MockChatbotService();
      messageRepository = MockMessageRepository();
      workspaceModelSelectionsRepository =
          MockWorkspaceModelSelectionRepository();
      conversationRepository = MockConversationRepository();
      loadConversationToolSpecsUsecase = MockLoadConversationToolSpecsUsecase();
      monitoringService = MockMonitoringService();
      selectPromptMessagesUsecase = MockSelectPromptMessagesUsecase();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = ContinueAgentUsecase(
        chatbotService: chatbotService,
        messageRepository: messageRepository,
        workspaceModelSelectionsRepository: workspaceModelSelectionsRepository,
        conversationRepository: conversationRepository,
        loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
        messagesStreamingRuntime: MessagesStreamingRuntime(
          startSubscription: (_, _) {
            final _ = Object();
          },
          updateResult: (_, _) {
            final _ = Object();
          },
          remove: (_) {
            return Future<void>.value();
          },
        ),
        conversationStreamingRuntime: ConversationStreamingRuntime(
          start: (_) {
            final _ = Object();
          },
          isStreaming: (_) => false,
          remove: (_) {
            final _ = Object();
          },
        ),
        agentCancellationRuntime: agentCancellationRuntime,
        monitoringService: monitoringService,
        selectPromptMessagesUsecase: selectPromptMessagesUsecase,
      );

      when(
        selectPromptMessagesUsecase.call('conversation-1'),
      ).thenAnswer((_) async => [_userMessage]);
    });

    test('throws when conversation not found', () {
      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer((_) async => null);

      expect(
        usecase.call(conversationId: 'conversation-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when conversation has no model id', () {
      final noModelConversation = ConversationEntity(
        id: 'conversation-1',
        title: 'No Model',
        workspaceId: 'workspace-1',
        isPinned: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer((_) async => noModelConversation);
      when(
        messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer((_) async => []);

      expect(
        usecase.call(conversationId: 'conversation-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when model not found', () {
      when(
        conversationRepository.getConversationById('conversation-1'),
      ).thenAnswer((_) async => _conversation);
      when(
        messageRepository.getMessagesByConversation('conversation-1'),
      ).thenAnswer((_) async => []);
      when(
        workspaceModelSelectionsRepository.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => null);

      expect(
        usecase.call(conversationId: 'conversation-1'),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'rethrows when stream errors before any chunk',
      () async {
        when(
          conversationRepository.getConversationById('conversation-1'),
        ).thenAnswer((_) async => _conversation);
        when(
          messageRepository.getMessagesByConversation('conversation-1'),
        ).thenAnswer((_) async => []);
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
        when(messageRepository.createMessage(any)).thenAnswer(
          (_) async => _unfinishedAssistantMessage,
        );
        when(messageRepository.patchMessage(any, any)).thenAnswer(
          (_) async => _unfinishedAssistantMessage,
        );
        when(
          chatbotService.sendMessage(_model, any, tools: const []),
        ).thenAnswer(
          (_) => Stream.error(StateError('model error')),
        );

        try {
          final _ = await usecase.call(conversationId: 'conversation-1');
          fail('Should have thrown');
          // ignore: avoid_catching_errors - Required to assert propagated StateError.
        } on StateError {
          final _ = verifyNever(
            messageRepository.patchMessage(any, any),
          );
        }
      },
    );
    test(
      'throws StateError when stream completes empty without cancellation',
      () async {
        when(
          conversationRepository.getConversationById('conversation-1'),
        ).thenAnswer((_) async => _conversation);
        when(
          workspaceModelSelectionsRepository.getWorkspaceModelSelectionById(
            'model-1',
          ),
        ).thenAnswer((_) async => _model);
        when(
          loadConversationToolSpecsUsecase(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
          ),
        ).thenAnswer((_) async => []);
        when(messageRepository.createMessage(any)).thenAnswer(
          (_) async => _unfinishedAssistantMessage,
        );
        when(messageRepository.patchMessage(any, any)).thenAnswer(
          (_) async => _unfinishedAssistantMessage,
        );
        when(
          chatbotService.sendMessage(_model, any, tools: const []),
        ).thenAnswer((_) => const Stream.empty());

        await expectLater(
          usecase.call(conversationId: 'conversation-1'),
          throwsA(
            predicate<StateError>((e) => '$e'.contains('without any result')),
          ),
        );
      },
    );
  });

  group('ContinueAgentUsecase prompt selection', () {
    var chatbotService = MockChatbotService();
    var messageRepository = MockMessageRepository();
    var workspaceModelSelectionsRepository =
        MockWorkspaceModelSelectionRepository();
    var conversationRepository = MockConversationRepository();
    var loadConversationToolSpecsUsecase =
        MockLoadConversationToolSpecsUsecase();
    var monitoringService = MockMonitoringService();
    var selectPromptMessagesUsecase = MockSelectPromptMessagesUsecase();
    var agentCancellationRuntime = AgentCancellationRuntime()
      ..start('conversation-1');
    var usecase = ContinueAgentUsecase(
      chatbotService: chatbotService,
      messageRepository: messageRepository,
      workspaceModelSelectionsRepository: workspaceModelSelectionsRepository,
      conversationRepository: conversationRepository,
      loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
      messagesStreamingRuntime: MessagesStreamingRuntime(
        startSubscription: (_, _) {
          final _ = Object();
        },
        updateResult: (_, _) {
          final _ = Object();
        },
        remove: (_) {
          return Future<void>.value();
        },
      ),
      conversationStreamingRuntime: ConversationStreamingRuntime(
        start: (_) {
          final _ = Object();
        },
        isStreaming: (_) => false,
        remove: (_) {
          final _ = Object();
        },
      ),
      agentCancellationRuntime: agentCancellationRuntime,
      monitoringService: monitoringService,
      selectPromptMessagesUsecase: selectPromptMessagesUsecase,
    );

    setUp(() {
      chatbotService = MockChatbotService();
      messageRepository = MockMessageRepository();
      workspaceModelSelectionsRepository =
          MockWorkspaceModelSelectionRepository();
      conversationRepository = MockConversationRepository();
      loadConversationToolSpecsUsecase = MockLoadConversationToolSpecsUsecase();
      monitoringService = MockMonitoringService();
      selectPromptMessagesUsecase = MockSelectPromptMessagesUsecase();
      agentCancellationRuntime = AgentCancellationRuntime()
        ..start('conversation-1');

      usecase = ContinueAgentUsecase(
        chatbotService: chatbotService,
        messageRepository: messageRepository,
        workspaceModelSelectionsRepository: workspaceModelSelectionsRepository,
        conversationRepository: conversationRepository,
        loadConversationToolSpecsUsecase: loadConversationToolSpecsUsecase,
        messagesStreamingRuntime: MessagesStreamingRuntime(
          startSubscription: (_, _) {
            final _ = Object();
          },
          updateResult: (_, _) {
            final _ = Object();
          },
          remove: (_) {
            return Future<void>.value();
          },
        ),
        conversationStreamingRuntime: ConversationStreamingRuntime(
          start: (_) {
            final _ = Object();
          },
          isStreaming: (_) => false,
          remove: (_) {
            final _ = Object();
          },
        ),
        agentCancellationRuntime: agentCancellationRuntime,
        monitoringService: monitoringService,
        selectPromptMessagesUsecase: selectPromptMessagesUsecase,
      );

      when(
        conversationRepository.getConversationById(any),
      ).thenAnswer((_) async => _conversation);
      when(
        workspaceModelSelectionsRepository.getWorkspaceModelSelectionById(any),
      ).thenAnswer((_) async => _model);
      when(
        loadConversationToolSpecsUsecase.call(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
        ),
      ).thenAnswer((_) async => const []);
      when(
        selectPromptMessagesUsecase.call(any),
      ).thenAnswer((_) async => [_userMessage]);
      when(
        messageRepository.createMessage(any),
      ).thenAnswer((_) async => _unfinishedAssistantMessage);
      when(
        messageRepository.patchMessage(any, any),
      ).thenAnswer((_) async => _unfinishedAssistantMessage);
      when(
        messageRepository.getMessagesByConversation(any),
      ).thenAnswer((_) async => [_userMessage]);
    });

    test('uses selectPromptMessages for prompt construction', () async {
      when(selectPromptMessagesUsecase.call(any)).thenAnswer(
        (_) async => [
          _userMessage,
        ],
      );
      when(
        chatbotService.sendMessage(_model, any, tools: const []),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Done'),
            finishReason: FinishReason.stop,
            usage: const LanguageModelUsage(),
          ),
        ]),
      );

      final _ = await usecase.call(conversationId: 'conversation-1');

      expect(
        () => verify(
          selectPromptMessagesUsecase.call('conversation-1'),
        ).called(1),
        returnsNormally,
      );
      expect(
        () => verifyNever(
          messageRepository.getMessagesByConversation('conversation-1'),
        ),
        returnsNormally,
      );
    });

    test('provider returns usecase with selectPromptMessages wired', () {
      final container = ProviderContainer(
        overrides: [
          selectPromptMessagesUsecaseProvider.overrideWith(
            (ref) => MockSelectPromptMessagesUsecase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final usecase = container.read(continueAgentUsecaseProvider);

      expect(usecase, isA<ContinueAgentUsecase>());
    });
  });
}

final _conversation = ConversationEntity(
  id: 'conversation-1',
  title: 'Conversation 1',
  workspaceId: 'workspace-1',
  isPinned: false,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
  modelId: 'model-1',
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

const _skillContextXml =
    '<skill><name>Skills Manager</name><content>Manage skills.</content></skill>';

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
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
    workspaceId: 'workspace-1',
  ),
  modelsProvider: const ApiModelProviderEntity(
    id: 'provider-1',
    name: 'OpenAI',
    type: ModelProvidersType.openai,
  ),
);

class _FakeBuildSkillContextMessagesUsecase
    implements BuildSkillContextMessagesUsecase {
  const _FakeBuildSkillContextMessagesUsecase(this.messages);

  final List<ChatMessage> messages;

  @override
  Future<List<ChatMessage>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    return messages;
  }
}
