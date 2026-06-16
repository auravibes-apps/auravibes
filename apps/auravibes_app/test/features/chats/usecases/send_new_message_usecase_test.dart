import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
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
      workspaceModelSelectionRepository: workspaceModelSelectionRepo,
      generateTitleUsecase: generateTitleUsecase,
      monitoringService: monitoringService,
    );

    when(
      () => workspaceModelSelectionRepo.getWorkspaceModelSelectionById(
        any(),
      ),
    ).thenAnswer((_) async => modelSelection);

    when(() => conversationRepo.createConversation(any())).thenAnswer(
      (_) async => newConversation,
    );
    when(
      () => sendMessageUsecase.call(
        conversationId: any(named: 'conversationId'),
        content: any(named: 'content'),
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
        key: 'test-key',
        modelId: 'gpt-4',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        workspaceId: 'ws-1',
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
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result.id, 'conv-1');
      verify(
        () => fixture.conversationRepo.createConversation(any()),
      ).called(1);
    });

    test('throws when model selection not found', () {
      when(
        () => fixture.workspaceModelSelectionRepo
            .getWorkspaceModelSelectionById(any()),
      ).thenAnswer((_) async => null);

      expect(
        () => fixture.usecase.call(
          workspaceId: 'ws-1',
          firstMessage: 'Hello',
          workspaceModelSelectionId: 'missing',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('calls generateTitle with correct args', () async {
      final _ = await fixture.usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

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

    test('calls sendMessage with correct args', () async {
      final _ = await fixture.usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(
        () => verify(
          () => fixture.sendMessageUsecase.call(
            conversationId: 'conv-1',
            content: 'Hello',
          ),
        ).called(1),
        returnsNormally,
      );
    });

    test('tracks error when sendMessage fails', () async {
      when(
        () => fixture.sendMessageUsecase.call(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async => throw Exception('Send failed'));

      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result.id, 'conv-1');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => fixture.monitoringService.trackError(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(1);
    });

    test('creates conversation with correct workspaceId and modelId', () async {
      final _ = await fixture.usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      final captured = verify(
        () => fixture.conversationRepo.createConversation(captureAny()),
      ).captured;
      expect(captured, isNotEmpty);
    });

    test('retrieves model selection with correct ID', () async {
      final _ = await fixture.usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(
        () => verify(
          () => fixture.workspaceModelSelectionRepo
              .getWorkspaceModelSelectionById(
                'model-sel-1',
              ),
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
        final _ = await fixture.usecase.call(
          workspaceId: 'ws-1',
          firstMessage: 'Hello',
          workspaceModelSelectionId: 'missing',
        );
        fail('Expected exception');
      } on Exception catch (e) {
        expect(e.toString(), contains('Selected model not found'));
      }
    });

    test('returns same conversation from repo', () async {
      final result = await fixture.usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result, equals(newConversation));
      expect(result.workspaceId, 'ws-1');
      expect(result.modelId, 'model-sel-1');
    });
  });
}
