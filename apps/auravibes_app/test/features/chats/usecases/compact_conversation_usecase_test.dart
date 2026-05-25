import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockWorkspaceModelSelectionRepository extends Mock
    implements WorkspaceModelSelectionRepository {}

class MockChatbotService extends Mock implements ChatbotService {}

class FakeWorkspaceModelSelectionWithConnectionEntity extends Fake
    implements WorkspaceModelSelectionWithConnectionEntity {}

class FakeMessageToCreate extends Fake implements MessageToCreate {}

class FakeConversationPatch extends Fake implements ConversationPatch {}

class FakeMessagePatch extends Fake implements MessagePatch {}

void main() {
  late MockMessageRepository mockMessageRepo;
  late MockConversationRepository mockConversationRepo;
  late MockWorkspaceModelSelectionRepository mockModelSelectionRepo;
  late MockChatbotService mockChatbotService;
  late ProviderContainer container;
  late CompactionExecution compactionExecution;
  late CompactConversationUsecase usecase;

  setUpAll(() {
    registerFallbackValue(FakeWorkspaceModelSelectionWithConnectionEntity());
    registerFallbackValue(FakeMessageToCreate());
    registerFallbackValue(FakeConversationPatch());
    registerFallbackValue(FakeMessagePatch());
  });

  setUp(() {
    mockMessageRepo = MockMessageRepository();
    mockConversationRepo = MockConversationRepository();
    mockModelSelectionRepo = MockWorkspaceModelSelectionRepository();
    mockChatbotService = MockChatbotService();
    container = ProviderContainer();
    compactionExecution = container.read(compactionExecutionProvider.notifier);
    usecase = CompactConversationUsecase(
      messageRepository: mockMessageRepo,
      conversationRepository: mockConversationRepo,
      workspaceModelSelectionsRepository: mockModelSelectionRepo,
      chatbotService: mockChatbotService,
      selectCompactionRangeUsecase: const SelectCompactionRangeUsecase(),
      compactionExecution: compactionExecution,
    );

    when(() => mockMessageRepo.createMessage(any())).thenAnswer(
      (invocation) async {
        final msg = invocation.positionalArguments.first as MessageToCreate;
        return MessageEntity(
          id: 'created-${DateTime.now().microsecondsSinceEpoch}',
          conversationId: msg.conversationId,
          content: msg.content,
          messageType: msg.messageType,
          isUser: msg.isUser,
          status: MessageStatus.sending,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          metadata: MessageMetadataEntity.fromJsonString(msg.metadata),
        );
      },
    );
    when(() => mockMessageRepo.patchMessage(any(), any())).thenAnswer(
      (invocation) async {
        final id = invocation.positionalArguments.first as String;
        return MessageEntity(
          id: id,
          conversationId: 'conv-1',
          content: '',
          messageType: MessageType.system,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
      },
    );
  });

  tearDown(() {
    container.dispose();
  });

  MessageEntity _makeMessage({
    String id = 'msg-1',
    String conversationId = 'conv-1',
    String content = 'Hello',
    bool isUser = true,
    MessageType messageType = MessageType.text,
    MessageStatus status = MessageStatus.sent,
    MessageMetadataEntity? metadata,
  }) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      content: content,
      messageType: messageType,
      isUser: isUser,
      status: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      metadata: metadata,
    );
  }

  group('CompactConversationUsecase manual', () {
    test('manual trigger succeeds below auto thresholds', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(() => mockChatbotService.sendMessage(any(), any())).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Manual summary'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
      );

      expect(result.status, CompactionExecutionStatus.success);
      expect(result.trigger, CompactionTrigger.manual);

      final captured =
          verify(
                () => mockMessageRepo.createMessage(captureAny()),
              ).captured.single
              as MessageToCreate;
      final meta = MessageMetadataEntity.fromJsonString(captured.metadata);
      expect(meta?.isCompactionSummary, true);
      expect(meta?.compactionKind, CompactionKind.manual);
    });

    test('manual throws CompactionUnsafeException for busy/unsafe state', () {
      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer(
        (_) async => [
          _makeMessage(),
          _makeMessage(id: 'msg-2', isUser: false),
        ],
      );

      expect(
        () => usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
        throwsA(isA<CompactionUnsafeException>()),
      );
    });

    test('manual failure does not persist failure message', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      try {
        await usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        );
      } on CompactionFailedException {
        // expected
      }

      verifyNever(() => mockMessageRepo.createMessage(any()));
    });

    test('manual failure leaves state unchanged', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      expect(
        () => usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
        throwsA(isA<CompactionFailedException>()),
      );
    });

    test('manual does not trigger auto-continue after success', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(() => mockChatbotService.sendMessage(any(), any())).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Summary'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
      );

      verify(() => mockMessageRepo.createMessage(any())).called(1);
      verifyNever(() => mockConversationRepo.patchConversation(any(), any()));
      expect(result.status, CompactionExecutionStatus.success);
    });
  });

  group('CompactConversationUsecase', () {
    test(
      'throws CompactionUnavailableException when conversation not found',
      () async {
        when(
          () => mockConversationRepo.getConversationById('conv-1'),
        ).thenAnswer((_) async => null);

        expect(
          () => usecase(
            conversationId: 'conv-1',
            trigger: CompactionTrigger.auto,
          ),
          throwsA(isA<CompactionUnavailableException>()),
        );
      },
    );

    test(
      'throws CompactionUnavailableException when no model selected',
      () async {
        when(
          () => mockConversationRepo.getConversationById('conv-1'),
        ).thenAnswer((_) async => _makeConversation(modelId: null));

        expect(
          () => usecase(
            conversationId: 'conv-1',
            trigger: CompactionTrigger.auto,
          ),
          throwsA(isA<CompactionUnavailableException>()),
        );
      },
    );

    test('throws CompactionUnsafeException when no safe range', () async {
      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer(
        (_) async => [_makeMessage(), _makeMessage(id: 'msg-2', isUser: false)],
      );

      expect(
        () => usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
        throwsA(isA<CompactionUnsafeException>()),
      );
    });

    test('persists summary with correct metadata on success', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(() => mockChatbotService.sendMessage(any(), any())).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Summary text'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      );

      expect(result.status, CompactionExecutionStatus.success);
      verify(() => mockMessageRepo.createMessage(any())).called(1);
    });

    test('throws CompactionFailedException on AI service failure', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      expect(
        () => usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
        ),
        throwsA(isA<CompactionFailedException>()),
      );
    });

    test('no boundary change on failure', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      try {
        await usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
        );
      } on CompactionFailedException {
        // expected
      }

      final captured =
          verify(
                () => mockMessageRepo.createMessage(captureAny()),
              ).captured.single
              as MessageToCreate;
      final meta = MessageMetadataEntity.fromJsonString(captured.metadata);
      expect(meta?.isCompactionSummary, isNot(equals(true)));
    });

    test('uses active conversation provider and model', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(() => mockChatbotService.sendMessage(any(), any())).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Summary'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      await usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
      );

      verify(() => mockChatbotService.sendMessage(any(), any())).called(1);
    });

    test(
      'preserves tool calls and resolved tool results in compaction prompt',
      () async {
        final messages = [
          _makeMessage(content: 'Need weather for Bogota'),
          _makeMessage(
            id: 'msg-2',
            isUser: false,
            content: '',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'tool-1',
                  name: 'weather_lookup',
                  argumentsRaw: '{"city":"Bogota"}',
                  responseRaw: '{"temperature":"18C"}',
                  resultStatus: ToolCallResultStatus.success,
                ),
              ],
            ),
          ),
          _makeMessage(id: 'msg-3', content: 'Summarize it'),
          _makeMessage(id: 'msg-4', isUser: false, content: 'Done'),
        ];

        when(
          () => mockConversationRepo.getConversationById('conv-1'),
        ).thenAnswer((_) async => _makeConversation());
        when(
          () =>
              mockModelSelectionRepo.getWorkspaceModelSelectionById('model-1'),
        ).thenAnswer((_) async => _makeModelSelection());
        when(
          () => mockMessageRepo.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);
        when(() => mockChatbotService.sendMessage(any(), any())).thenAnswer(
          (_) => Stream.value(
            ChatResult<ChatMessage>(
              output: ChatMessage.model('Summary'),
              usage: const LanguageModelUsage(),
            ),
          ),
        );

        await usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        );

        final captured =
            verify(
                  () => mockChatbotService.sendMessage(any(), captureAny()),
                ).captured.single
                as List<ChatMessage>;

        expect(captured, hasLength(5));
        expect(captured[1].role.name, 'user');
        expect(captured[1].text, 'Need weather for Bogota');
        expect(captured[2].role.name, 'model');
        expect(captured[2].toolCalls, hasLength(1));
        expect(captured[2].toolCalls.single.toolName, 'weather_lookup');
        expect(captured[3].role.name, 'user');
        expect(captured[3].toolResults, hasLength(1));
        expect(captured[3].toolResults.single.result, '{"temperature":"18C"}');
      },
    );
  });
}

ConversationEntity _makeConversation({String? modelId = 'model-1'}) {
  return ConversationEntity(
    id: 'conv-1',
    title: 'Test',
    workspaceId: 'ws-1',
    isPinned: false,
    modelId: modelId,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

WorkspaceModelSelectionWithConnectionEntity _makeModelSelection() {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: 'model-1',
      modelId: 'gpt-4',
      modelConnectionId: 'conn-1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    modelConnection: ModelConnectionEntity(
      id: 'conn-1',
      name: 'OpenAI',
      key: 'encrypted-key',
      modelId: 'gpt-4',
      workspaceId: 'ws-1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    modelsProvider: const ApiModelProviderEntity(
      id: 'openai',
      name: 'OpenAI',
      type: ModelProvidersType.openai,
    ),
  );
}
