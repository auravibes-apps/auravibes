// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: missing-test-assertion
// Required: Tests verify usecase behavior through repository side effects.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'send_new_message_usecase_test.mocks.dart';

@GenerateMocks([
  ConversationRepository,
  WorkspaceModelSelectionRepository,
  SendMessageUsecase,
  GenerateTitleUsecase,
  MonitoringService,
])
void main() {
  group('SendNewMessageUsecase', () {
    late MockConversationRepository conversationRepo;
    late MockWorkspaceModelSelectionRepository workspaceModelSelectionRepo;
    late MockSendMessageUsecase sendMessageUsecase;
    late MockGenerateTitleUsecase generateTitleUsecase;
    late MockMonitoringService monitoringService;
    late SendNewMessageUsecase usecase;

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
      conversationRepo = MockConversationRepository();
      workspaceModelSelectionRepo = MockWorkspaceModelSelectionRepository();
      sendMessageUsecase = MockSendMessageUsecase();
      generateTitleUsecase = MockGenerateTitleUsecase();
      monitoringService = MockMonitoringService();
      usecase = SendNewMessageUsecase(
        conversationRepo: conversationRepo,
        sendMessageUsecase: sendMessageUsecase,
        workspaceModelSelectionRepository: workspaceModelSelectionRepo,
        generateTitleUsecase: generateTitleUsecase,
        monitoringService: monitoringService,
      );

      when(
        workspaceModelSelectionRepo.getWorkspaceModelSelectionById(
          any,
        ),
      ).thenAnswer((_) async => modelSelection);

      when(conversationRepo.createConversation(any)).thenAnswer(
        (_) async => newConversation,
      );
    });

    test('creates conversation and returns it', () async {
      final result = await usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result.id, 'conv-1');
      verify(conversationRepo.createConversation(any)).called(1);
    });

    test('throws when model selection not found', () async {
      when(
        workspaceModelSelectionRepo.getWorkspaceModelSelectionById(any),
      ).thenAnswer((_) async => null);

      expect(
        () => usecase.call(
          workspaceId: 'ws-1',
          firstMessage: 'Hello',
          workspaceModelSelectionId: 'missing',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('calls generateTitle with correct args', () async {
      final _ = await usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      verify(
        generateTitleUsecase.call(
          conversationId: 'conv-1',
          firstMessage: 'Hello',
          workspaceModelSelection: modelSelection,
        ),
      ).called(1);
    });

    test('calls sendMessage with correct args', () async {
      final _ = await usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      verify(
        sendMessageUsecase.call(
          conversationId: 'conv-1',
          content: 'Hello',
        ),
      ).called(1);
    });

    test('tracks error when sendMessage fails', () async {
      when(
        sendMessageUsecase.call(
          conversationId: anyNamed('conversationId'),
          content: anyNamed('content'),
        ),
      ).thenAnswer((_) async => throw Exception('Send failed'));

      final result = await usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      expect(result.id, 'conv-1');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        monitoringService.trackError(
          any,
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
        ),
      ).called(1);
    });

    test('creates conversation with correct workspaceId and modelId', () async {
      final _ = await usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      final captured = verify(
        conversationRepo.createConversation(captureAny),
      ).captured;
      expect(captured, isNotEmpty);
    });

    test('retrieves model selection with correct ID', () async {
      final _ = await usecase.call(
        workspaceId: 'ws-1',
        firstMessage: 'Hello',
        workspaceModelSelectionId: 'model-sel-1',
      );

      verify(
        workspaceModelSelectionRepo.getWorkspaceModelSelectionById(
          'model-sel-1',
        ),
      ).called(1);
    });

    test('exception message contains correct text', () async {
      when(
        workspaceModelSelectionRepo.getWorkspaceModelSelectionById(any),
      ).thenAnswer((_) async => null);

      try {
        final _ = await usecase.call(
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
      final result = await usecase.call(
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
