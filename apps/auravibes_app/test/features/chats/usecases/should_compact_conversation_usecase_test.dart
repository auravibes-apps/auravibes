// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/features/chats/usecases/should_compact_conversation_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

class MockWorkspaceCompactionSettingsRepository extends Mock
    implements WorkspaceCompactionSettingsRepository {}

void main() {
  late MockMessageRepository mockRepository;
  late MockWorkspaceCompactionSettingsRepository mockSettingsRepo;
  late ShouldCompactConversationUsecase usecase;

  setUp(() {
    mockRepository = MockMessageRepository();
    mockSettingsRepo = MockWorkspaceCompactionSettingsRepository();
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

  group('ShouldCompactConversationUsecase', () {
    test('returns disabled when auto compaction is disabled', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => const CompactionSettings(autoCompactionEnabled: false),
      );
      usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => []);

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      expect(decision.shouldCompact, isFalse);
      expect(decision.reason, CompactionDecisionReason.disabled);
    });

    test('returns unknownContextLimit when contextLimit is null', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => CompactionSettings.defaults,
      );
      usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => []);

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
      );

      expect(decision.shouldCompact, isFalse);
      expect(decision.reason, CompactionDecisionReason.unknownContextLimit);
    });

    test('returns unsafeState when pending tool calls exist', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => CompactionSettings.defaults,
      );
      usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tc-1',
                name: 'read_file',
                argumentsRaw: '{}',
              ),
            ],
          ),
        ),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      expect(decision.shouldCompact, isFalse);
      expect(decision.reason, CompactionDecisionReason.unsafeState);
    });

    test(
      'returns belowPercentageThreshold when usage is below threshold',
      () async {
        when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
          (_) async => CompactionSettings.defaults,
        );
        usecase = ShouldCompactConversationUsecase(
          messageRepository: mockRepository,
          settingsRepository: mockSettingsRepo,
        );

        final messages = [
          _makeMessage(),
          _makeMessage(
            id: 'msg-2',
            isUser: false,
            metadata: const MessageMetadataEntity(
              totalTokens: 50000,
            ),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'workspace-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
          contextLimit: 128000,
        );

        expect(decision.shouldCompact, isFalse);
        expect(
          decision.reason,
          CompactionDecisionReason.belowPercentageThreshold,
        );
      },
    );

    test(
      'returns eligible when usage threshold is met even if '
      'remaining tokens are high',
      () async {
        when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
          (_) async => CompactionSettings.defaults,
        );
        usecase = ShouldCompactConversationUsecase(
          messageRepository: mockRepository,
          settingsRepository: mockSettingsRepo,
        );

        final messages = [
          _makeMessage(),
          _makeMessage(
            id: 'msg-2',
            isUser: false,
            metadata: const MessageMetadataEntity(
              totalTokens: 110000,
            ),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'workspace-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
          contextLimit: 128000,
        );

        expect(decision.shouldCompact, isTrue);
        expect(decision.reason, CompactionDecisionReason.eligible);
      },
    );

    test(
      'returns eligible when remaining token threshold is met even if '
      'usage is below threshold',
      () async {
        when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
          (_) async => const CompactionSettings(
            remainingTokenThreshold: 60000,
          ),
        );
        usecase = ShouldCompactConversationUsecase(
          messageRepository: mockRepository,
          settingsRepository: mockSettingsRepo,
        );

        final messages = [
          _makeMessage(),
          _makeMessage(
            id: 'msg-2',
            isUser: false,
            metadata: const MessageMetadataEntity(
              totalTokens: 70000,
            ),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'workspace-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
          contextLimit: 128000,
        );

        expect(decision.shouldCompact, isTrue);
        expect(decision.reason, CompactionDecisionReason.eligible);
      },
    );

    test('returns eligible when both thresholds are met', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => CompactionSettings.defaults,
      );
      usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          metadata: const MessageMetadataEntity(
            totalTokens: 127000,
          ),
        ),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      expect(decision.shouldCompact, isTrue);
      expect(decision.reason, CompactionDecisionReason.eligible);
      expect(decision.estimate, isNotNull);
    });

    test(
      'returns eligible for manual trigger regardless of thresholds',
      () async {
        when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
          (_) async => CompactionSettings.defaults,
        );
        usecase = ShouldCompactConversationUsecase(
          messageRepository: mockRepository,
          settingsRepository: mockSettingsRepo,
        );

        final messages = [
          _makeMessage(),
          _makeMessage(id: 'msg-2', isUser: false),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'workspace-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
          contextLimit: 128000,
          trigger: CompactionTrigger.manual,
        );

        expect(decision.shouldCompact, isTrue);
        expect(decision.reason, CompactionDecisionReason.eligible);
        expect(decision.trigger, CompactionTrigger.manual);
      },
    );

    test('manual trigger returns eligible even when auto disabled', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => const CompactionSettings(autoCompactionEnabled: false),
      );
      usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      when(() => mockRepository.getMessagesByConversation('conv-1')).thenAnswer(
        (_) async => [_makeMessage(), _makeMessage(id: 'msg-2', isUser: false)],
      );

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
        trigger: CompactionTrigger.manual,
      );

      expect(decision.shouldCompact, isTrue);
      expect(decision.trigger, CompactionTrigger.manual);
    });

    test('loads settings from service at call time', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => CompactionSettings.defaults,
      );
      usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => []);

      final _ = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      verify(() => mockSettingsRepo.getEffectiveSettings(any())).called(1);
    });
  });

  group('Saved settings integration', () {
    late MockMessageRepository mockRepository;
    late MockWorkspaceCompactionSettingsRepository mockSettingsRepo;

    setUp(() {
      mockRepository = MockMessageRepository();
      mockSettingsRepo = MockWorkspaceCompactionSettingsRepository();
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

    test('saved low usage threshold triggers compaction earlier', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => const CompactionSettings(
          usagePercentageThreshold: 50,
          remainingTokenThreshold: 50000,
        ),
      );
      final usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      final messages = [
        _makeMessage(),
        _makeMessage(
          id: 'msg-2',
          isUser: false,
          metadata: const MessageMetadataEntity(totalTokens: 80000),
        ),
      ];

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => messages);

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      expect(decision.shouldCompact, isTrue);
      expect(decision.reason, CompactionDecisionReason.eligible);
      expect(decision.settings?.usagePercentageThreshold, 50);
    });

    test('saved disabled setting prevents auto compaction', () async {
      when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
        (_) async => const CompactionSettings(autoCompactionEnabled: false),
      );
      final usecase = ShouldCompactConversationUsecase(
        messageRepository: mockRepository,
        settingsRepository: mockSettingsRepo,
      );

      when(
        () => mockRepository.getMessagesByConversation('conv-1'),
      ).thenAnswer((_) async => []);

      final decision = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'workspace-1',
        selectedModelId: 'model-1',
        selectedProviderId: 'provider-1',
        maxOutputTokens: 4096,
        contextLimit: 128000,
      );

      expect(decision.shouldCompact, isFalse);
      expect(decision.reason, CompactionDecisionReason.disabled);
    });

    test(
      'saved high remaining threshold triggers compaction earlier',
      () async {
        when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
          (_) async => const CompactionSettings(
            usagePercentageThreshold: 10,
            remainingTokenThreshold: 60000,
          ),
        );
        final usecase = ShouldCompactConversationUsecase(
          messageRepository: mockRepository,
          settingsRepository: mockSettingsRepo,
        );

        final messages = [
          _makeMessage(),
          _makeMessage(
            id: 'msg-2',
            isUser: false,
            metadata: const MessageMetadataEntity(totalTokens: 70000),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'workspace-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
          contextLimit: 128000,
        );

        expect(decision.shouldCompact, isTrue);
        expect(
          decision.reason,
          CompactionDecisionReason.eligible,
        );
      },
    );

    test(
      'character estimation counts tool call arguments and responses',
      () async {
        final settings = CompactionSettings(
          usagePercentageThreshold: 1,
          updatedAt: DateTime(2026),
        );
        when(() => mockSettingsRepo.getEffectiveSettings(any())).thenAnswer(
          (_) async => settings,
        );
        usecase = ShouldCompactConversationUsecase(
          messageRepository: mockRepository,
          settingsRepository: mockSettingsRepo,
        );

        final messages = [
          _makeMessage(
            id: 'msg-tool',
            isUser: false,
            content: '',
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'tc-1',
                  name: 'test',
                  argumentsRaw: '0123456789',
                  responseRaw: 'ABCDEFGHIJ',
                  resultStatus: ToolCallResultStatus.success,
                ),
              ],
            ),
          ),
        ];

        when(
          () => mockRepository.getMessagesByConversation('conv-1'),
        ).thenAnswer((_) async => messages);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'workspace-1',
          selectedModelId: 'model-1',
          selectedProviderId: 'provider-1',
          maxOutputTokens: 4096,
          contextLimit: 128000,
        );

        // 10 args + 10 response + 0 content = 20 chars / 4 = 5 tokens
        // 5/128000 = 0.004% → way below 1% → char count fallback works
        expect(
          decision.reason,
          CompactionDecisionReason.belowPercentageThreshold,
        );
      },
    );
  });
}
