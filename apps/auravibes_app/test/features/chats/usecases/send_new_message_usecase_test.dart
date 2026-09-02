import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

class _SendNewMessageUsecaseFixture {
  MockConversationRepository? _conversationRepo;
  MockWorkspaceModelSelectionRepository? _workspaceModelSelectionRepo;
  MockSendMessageUsecase? _sendMessageUsecase;
  MockGenerateTitleUsecase? _generateTitleUsecase;
  MockMonitoringService? _monitoringService;
  SendNewMessageUsecase? _usecase;

  MockConversationRepository get conversationRepo =>
      _conversationRepo ??
      fail('Conversation repository fixture not initialized.');

  MockWorkspaceModelSelectionRepository get workspaceModelSelectionRepo =>
      _workspaceModelSelectionRepo ??
      fail('Workspace model selection repository fixture not initialized.');

  MockSendMessageUsecase get sendMessageUsecase =>
      _sendMessageUsecase ?? fail('Send message usecase not initialized.');

  MockGenerateTitleUsecase get generateTitleUsecase =>
      _generateTitleUsecase ?? fail('Generate title usecase not initialized.');

  MockMonitoringService get monitoringService =>
      _monitoringService ?? fail('Monitoring service fixture not initialized.');

  SendNewMessageUsecase get usecase =>
      _usecase ?? fail('Usecase fixture not initialized.');

  void setUp({
    required ConversationEntity newConversation,
    required WorkspaceModelSelectionWithConnectionEntity modelSelection,
  }) {
    final conversationRepo = MockConversationRepository();
    final workspaceModelSelectionRepo = MockWorkspaceModelSelectionRepository();
    final sendMessageUsecase = MockSendMessageUsecase();
    final generateTitleUsecase = MockGenerateTitleUsecase();
    final monitoringService = MockMonitoringService();

    _conversationRepo = conversationRepo;
    _workspaceModelSelectionRepo = workspaceModelSelectionRepo;
    _sendMessageUsecase = sendMessageUsecase;
    _generateTitleUsecase = generateTitleUsecase;
    _monitoringService = monitoringService;
    _usecase = SendNewMessageUsecase(
      conversationRepo: conversationRepo,
      sendMessageUsecase: sendMessageUsecase,
      modelSelectionStore: (_) async => workspaceModelSelectionRepo,
      generateTitleUsecase: generateTitleUsecase,
      monitoringService: monitoringService,
    );

    when(
      () => workspaceModelSelectionRepo.getWorkspaceModelSelectionById(any()),
    ).thenAnswer((_) async => modelSelection);

    when(() => conversationRepo.createConversation(any()))
        .thenAnswer((_) async => newConversation);
    when(
      () => sendMessageUsecase.call(
        conversationId: any(named: 'conversationId'),
        draft: any<ChatDraft>(named: 'draft'),
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => sendMessageUsecase.createUserMessage(
        conversationId: any(named: 'conversationId'),
        draft: any<ChatDraft>(named: 'draft'),
      ),
    ).thenAnswer(
      (_) async => MessageEntity(
        id: 'message-1',
        conversationId: 'conv-1',
        content: 'Hello',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sending,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    when(
      () => sendMessageUsecase.continueFromUserMessage(
        conversationId: any(named: 'conversationId'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(
      () => generateTitleUsecase.call(
        conversationId: any(named: 'conversationId'),
        firstMessage: any(named: 'firstMessage'),
        workspaceModelSelection: any(named: 'workspaceModelSelection'),
      ),
    ).thenAnswer((_) => Future<void>.value());
  }
}

void main() {
  setUpAll(registerTestFallbackValues);

  group('SendNewMessageUsecase', () {
    final fixture = _SendNewMessageUsecaseFixture();

    final newConversation = ConversationEntity(
      id: 'conv-1',
      title: 'New Conversation',
      workspaceId: 'ws-1',
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelId: 'model-sel-1',
    );

    final modelSelection = WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: WorkspaceModelSelectionEntity(
        id: 'model-sel-1',
        modelId: 'gpt-4',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        modelConnectionId: 'conn-1',
      ),
      modelConnection: ModelConnectionEntity(
        id: 'conn-1',
        name: 'OpenAI',
        modelId: 'gpt-4',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        workspaceId: 'ws-1',
        hasKey: true,
      ),
      modelsProvider: const ApiModelProviderEntity(
        id: 'provider-1',
        name: 'OpenAI',
        type: null,
      ),
    );

    setUp(() {
      fixture.setUp(
        newConversation: newConversation,
        modelSelection: modelSelection,
      );
    });

    test('creates conversation and returns it', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result.id, 'conv-1');
      expect(
        () =>
            verify(() => fixture.conversationRepo.createConversation(any()))
                .called(1),
        returnsNormally,
      );
    });

    test('throws when model selection not found', () {
      when(
        () => fixture.workspaceModelSelectionRepo
            .getWorkspaceModelSelectionById(any()),
      ).thenAnswer((_) async => null);

      expect(
        () => fixture.usecase.call(
          workspaceId: 'ws-1',
          draft: const ChatDraft(text: 'Hello'),
          workspaceModelSelectionId: 'missing',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('calls generateTitle with correct args', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      expect(
        () => verify(
          () => fixture.generateTitleUsecase.call(
            conversationId: 'conv-1',
            firstMessage: 'Hello',
            workspaceModelSelection: modelSelection,
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test('does not stream a local title for cloud conversations', () async {
      final cloudUsecase = SendNewMessageUsecase(
        conversationRepo: fixture.conversationRepo,
        sendMessageUsecase: fixture.sendMessageUsecase,
        modelSelectionStore: (_) async => fixture.workspaceModelSelectionRepo,
        generateTitleUsecase: fixture.generateTitleUsecase,
        monitoringService: fixture.monitoringService,
        cloudCreate: (_) async => newConversation,
      );

      final result = await cloudUsecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      expect(
        () => verifyNever(
          () => fixture.generateTitleUsecase.call(
            conversationId: any(named: 'conversationId'),
            firstMessage: any(named: 'firstMessage'),
            workspaceModelSelection: any(named: 'workspaceModelSelection'),
          ),
        ),
        returnsNormally,
      );
    });

    test('creates first message with correct args', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      expect(
        () => verify(
          () => fixture.sendMessageUsecase.createUserMessage(
            conversationId: 'conv-1',
            draft: const ChatDraft(text: 'Hello'),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test('tracks and rethrows when message creation fails', () async {
      final exception = Exception('Send failed');
      when(
        () => fixture.sendMessageUsecase.createUserMessage(
          conversationId: any(named: 'conversationId'),
          draft: any<ChatDraft>(named: 'draft'),
        ),
      ).thenThrow(exception);

      await expectLater(
        fixture.usecase.call(
          workspaceId: 'ws-1',
          draft: const ChatDraft(text: 'Hello'),
          workspaceModelSelectionId: 'model-sel-1',
        ),
        throwsA(same(exception)),
      );

      expect(
        () => verify(
          () => fixture.monitoringService.trackError(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test('creates conversation with correct workspaceId and modelId', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      final captured = verify(
        () => fixture.conversationRepo.createConversation(captureAny()),
      ).captured;
      expect(captured, isNotEmpty);
    });

    test('retrieves model selection with correct ID', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      expect(
        () => verify(
          () => fixture.workspaceModelSelectionRepo
              .getWorkspaceModelSelectionById('model-sel-1'),
        ).called(1),
        returnsNormally,
      );
    });

    test('exception message contains correct text', () async {
      when(
        () => fixture.workspaceModelSelectionRepo
            .getWorkspaceModelSelectionById(any()),
      ).thenAnswer((_) async => null);

      try {
        final result = await fixture.usecase.call(
          workspaceId: 'ws-1',
          draft: const ChatDraft(text: 'Hello'),
          workspaceModelSelectionId: 'missing',
        );
        fail('Expected exception, got $result');
      } on Exception catch (e) {
        expect(e.toString(), contains('Selected model not found'));
      }
    });

    test('returns same conversation from repo', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        draft: const ChatDraft(text: 'Hello'),
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      expect(result.workspaceId, 'ws-1');
      expect(result.modelId, 'model-sel-1');
    });
  });
}
