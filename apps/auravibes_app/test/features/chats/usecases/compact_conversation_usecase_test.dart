// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution_runtime_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/compact_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_compaction_range_usecase.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockWorkspaceModelSelectionRepository extends Mock
    implements WorkspaceModelSelectionRepository {}

class MockChatbotService extends Mock implements ChatbotService {}

class FakeModelSelectionConnection extends Fake
    implements WorkspaceModelSelectionWithConnectionEntity {}

class FakeMessageToCreate extends Fake implements MessageToCreate {}

class FakeConversationPatch extends Fake implements ConversationPatch {}

class FakeMessagePatch extends Fake implements MessagePatch {}

class _CompactConversationFixture {
  MockMessageRepository? _mockMessageRepo;
  MockConversationRepository? _mockConversationRepo;
  MockWorkspaceModelSelectionRepository? _mockModelSelectionRepo;
  MockChatbotService? _mockChatbotService;
  ProviderContainer? _container;
  CompactConversationUsecase? _usecase;

  MockMessageRepository get mockMessageRepo =>
      _mockMessageRepo ?? fail('mockMessageRepo not initialized');

  MockConversationRepository get mockConversationRepo =>
      _mockConversationRepo ?? fail('mockConversationRepo not initialized');

  MockWorkspaceModelSelectionRepository get mockModelSelectionRepo =>
      _mockModelSelectionRepo ?? fail('mockModelSelectionRepo not initialized');

  MockChatbotService get mockChatbotService =>
      _mockChatbotService ?? fail('mockChatbotService not initialized');

  CompactConversationUsecase get usecase =>
      _usecase ?? fail('usecase not initialized');

  void reset() {
    _mockMessageRepo = MockMessageRepository();
    _mockConversationRepo = MockConversationRepository();
    _mockModelSelectionRepo = MockWorkspaceModelSelectionRepository();
    _mockChatbotService = MockChatbotService();
    final container = ProviderContainer();
    _container = container;
    final compactionExecution = container.read(
      compactionExecutionRuntimeProvider,
    );
    _usecase = CompactConversationUsecase(
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
  }

  void dispose() {
    _container?.dispose();
    _container = null;
    _mockMessageRepo = null;
    _mockConversationRepo = null;
    _mockModelSelectionRepo = null;
    _mockChatbotService = null;
    _usecase = null;
  }
}

void main() {
  final fixture = _CompactConversationFixture();

  setUpAll(() {
    registerFallbackValue(FakeModelSelectionConnection());
    registerFallbackValue(FakeMessageToCreate());
    registerFallbackValue(FakeConversationPatch());
    registerFallbackValue(FakeMessagePatch());
  });

  setUp(fixture.reset);

  tearDown(fixture.dispose);

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
    test('provider wires runtime adapter dependency', () {
      final container = ProviderContainer(
        overrides: [
          messageRepositoryProvider.overrideWithValue(fixture.mockMessageRepo),
          conversationRepositoryProvider.overrideWithValue(
            fixture.mockConversationRepo,
          ),
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            fixture.mockModelSelectionRepo,
          ),
          chatbotServiceProvider.overrideWithValue(fixture.mockChatbotService),
          selectCompactionRangeUsecaseProvider.overrideWithValue(
            const SelectCompactionRangeUsecase(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final usecase = container.read(compactConversationUsecaseProvider);

      expect(usecase.compactionExecution, isA<CompactionExecutionRuntime>());
    });

    test('manual trigger succeeds below auto thresholds', () async {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Manual summary'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final result = await fixture.usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
      );

      expect(result.status, CompactionExecutionStatus.success);
      expect(result.trigger, CompactionTrigger.manual);

      final captured =
          verify(
                () => fixture.mockMessageRepo.createMessage(captureAny()),
              ).captured.single
              as MessageToCreate;
      final meta = MessageMetadataEntity.fromJsonString(captured.metadata);
      expect(meta?.isCompactionSummary, true);
      expect(meta?.compactionKind, CompactionKind.manual);
    });

    test('manual throws CompactionUnsafeException for busy/unsafe state', () {
      when(
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer(
        (_) async => [
          _makeMessage(),
          _makeMessage(id: 'msg-2', isUser: false),
        ],
      );

      expect(
        () => fixture.usecase(
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
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      await expectLater(
        fixture.usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        ),
        throwsA(isA<CompactionFailedException>()),
      );

      expect(
        () => verifyNever(() => fixture.mockMessageRepo.createMessage(any())),
        returnsNormally,
      );
    });

    test('manual failure leaves state unchanged', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      expect(
        () => fixture.usecase(
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
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Summary'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final result = await fixture.usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
      );

      verify(() => fixture.mockMessageRepo.createMessage(any())).called(1);
      final _ = verifyNever(
        () => fixture.mockConversationRepo.patchConversation(any(), any()),
      );
      expect(result.status, CompactionExecutionStatus.success);
    });
  });

  group('CompactConversationUsecase', () {
    test(
      'throws CompactionUnavailableException when conversation not found',
      () {
        when(
          () => fixture.mockConversationRepo.getConversationById('conv-1'),
        ).thenAnswer((_) async => null);

        expect(
          () => fixture.usecase(
            conversationId: 'conv-1',
            trigger: CompactionTrigger.auto,
          ),
          throwsA(isA<CompactionUnavailableException>()),
        );
      },
    );

    test(
      'throws CompactionUnavailableException when no model selected',
      () {
        when(
          () => fixture.mockConversationRepo.getConversationById('conv-1'),
        ).thenAnswer((_) async => _makeConversation(modelId: null));

        expect(
          () => fixture.usecase(
            conversationId: 'conv-1',
            trigger: CompactionTrigger.auto,
          ),
          throwsA(isA<CompactionUnavailableException>()),
        );
      },
    );

    test('throws CompactionUnsafeException when no safe range', () {
      when(
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer(
        (_) async => [_makeMessage(), _makeMessage(id: 'msg-2', isUser: false)],
      );

      expect(
        () => fixture.usecase(
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
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Summary text'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final result = await fixture.usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.auto,
      );

      expect(result.status, CompactionExecutionStatus.success);
      verify(() => fixture.mockMessageRepo.createMessage(any())).called(1);
    });

    test('throws CompactionFailedException on AI service failure', () {
      final messages = [
        _makeMessage(),
        _makeMessage(id: 'msg-2', isUser: false),
        _makeMessage(id: 'msg-3'),
        _makeMessage(id: 'msg-4', isUser: false),
      ];

      when(
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      expect(
        () => fixture.usecase(
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
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenThrow(Exception('API error'));

      try {
        final _ = await fixture.usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
        );
      } on CompactionFailedException {
        // Expected.
      }

      final captured =
          verify(
                () => fixture.mockMessageRepo.createMessage(captureAny()),
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
        () => fixture.mockConversationRepo.getConversationById('conv-1'),
      ).thenAnswer((_) async => _makeConversation());
      when(
        () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-1',
        ),
      ).thenAnswer((_) async => _makeModelSelection());
      when(
        () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);
      when(
        () => fixture.mockChatbotService.sendMessage(any(), any()),
      ).thenAnswer(
        (_) => Stream.value(
          ChatResult<ChatMessage>(
            output: ChatMessage.model('Summary'),
            usage: const LanguageModelUsage(),
          ),
        ),
      );

      final _ = await fixture.usecase(
        conversationId: 'conv-1',
        trigger: CompactionTrigger.manual,
      );

      expect(
        () => verify(
          () => fixture.mockChatbotService.sendMessage(any(), any()),
        ).called(1),
        returnsNormally,
      );
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
          () => fixture.mockConversationRepo.getConversationById('conv-1'),
        ).thenAnswer((_) async => _makeConversation());
        when(
          () => fixture.mockModelSelectionRepo.getWorkspaceModelSelectionById(
            'model-1',
          ),
        ).thenAnswer((_) async => _makeModelSelection());
        when(
          () => fixture.mockMessageRepo.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);
        when(
          () => fixture.mockChatbotService.sendMessage(any(), any()),
        ).thenAnswer(
          (_) => Stream.value(
            ChatResult<ChatMessage>(
              output: ChatMessage.model('Summary'),
              usage: const LanguageModelUsage(),
            ),
          ),
        );

        final _ = await fixture.usecase(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
        );

        final captured =
            verify(
                  () => fixture.mockChatbotService.sendMessage(
                    any(),
                    captureAny(),
                  ),
                ).captured.single
                as List<ChatMessage>;

        final userMessage = captured
            .where((message) => message.text == 'Need weather for Bogota')
            .firstOrNull;
        final toolCallMessage = captured
            .where(
              (message) => message.toolCalls.any(
                (toolCall) => toolCall.toolName == 'weather_lookup',
              ),
            )
            .firstOrNull;
        final toolResultMessage = captured
            .where(
              (message) => message.parts.whereType<ToolResponsePart>().any(
                (part) => part.toolResponse.output == '{"temperature":"18C"}',
              ),
            )
            .firstOrNull;

        expect(userMessage?.role, ChatMessageRole.user);
        expect(toolCallMessage?.role, ChatMessageRole.model);
        expect(toolCallMessage?.toolCalls, hasLength(1));
        expect(
          toolCallMessage?.toolCalls.firstOrNull?.toolName,
          'weather_lookup',
        );
        expect(toolResultMessage?.role, ChatMessageRole.tool);
        expect(
          toolResultMessage?.parts.whereType<ToolResponsePart>(),
          hasLength(1),
        );
        expect(
          toolResultMessage?.parts
              .whereType<ToolResponsePart>()
              .firstOrNull
              ?.toolResponse
              .output,
          '{"temperature":"18C"}',
        );
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
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    modelId: modelId,
  );
}

WorkspaceModelSelectionWithConnectionEntity _makeModelSelection() {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: 'model-1',
      modelId: 'gpt-4',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelConnectionId: 'conn-1',
    ),
    modelConnection: ModelConnectionEntity(
      id: 'conn-1',
      name: 'OpenAI',
      key: 'encrypted-key',
      modelId: 'gpt-4',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workspaceId: 'ws-1',
    ),
    modelsProvider: const ApiModelProviderEntity(
      id: 'openai',
      name: 'OpenAI',
      type: ModelProvidersType.openai,
    ),
  );
}
