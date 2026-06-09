import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_streaming_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'generate_title_usecase_test.mocks.dart';

@GenerateMocks([
  ConversationRepository,
  ChatbotService,
  MonitoringService,
])
void main() {
  group('GenerateTitleUsecase', () {
    var conversationRepo = MockConversationRepository();
    var chatbotService = MockChatbotService();
    var titlesStreamingRuntime = TitlesStreamingRuntime(
      updateTitle: (_, _) {
        final _ = Object();
      },
      removeTitle: (_) {
        final _ = Object();
      },
    );
    var monitoringService = MockMonitoringService();
    var usecase = GenerateTitleUsecase(
      conversationRepo: conversationRepo,
      chatbotService: chatbotService,
      titlesStreamingRuntime: titlesStreamingRuntime,
      monitoringService: monitoringService,
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
      chatbotService = MockChatbotService();
      titlesStreamingRuntime = TitlesStreamingRuntime(
        updateTitle: (_, _) {
          final _ = Object();
        },
        removeTitle: (_) {
          final _ = Object();
        },
      );
      monitoringService = MockMonitoringService();
      usecase = GenerateTitleUsecase(
        conversationRepo: conversationRepo,
        chatbotService: chatbotService,
        titlesStreamingRuntime: titlesStreamingRuntime,
        monitoringService: monitoringService,
      );

      when(conversationRepo.patchConversation(any, any)).thenAnswer(
        (_) async => ConversationEntity(
          id: 'conv-1',
          title: 'Patched',
          workspaceId: 'ws-1',
          isPinned: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      monitoringService = MockMonitoringService();
      usecase = GenerateTitleUsecase(
        conversationRepo: conversationRepo,
        chatbotService: chatbotService,
        titlesStreamingRuntime: titlesStreamingRuntime,
        monitoringService: monitoringService,
      );
    });

    test('calls chatbotService.streamTitle with correct args', () async {
      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      usecase.call(
        conversationId: 'conv-1',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      expect(
        () => verify(
          chatbotService.streamTitle(modelSelection, 'Hello'),
        ).called(1),
        returnsNormally,
      );

      final _ = await controller.close();
    });

    test(
      'removeTitle is called on stream done',
      () async {
        final removedIds = <String>[];
        final runtime = TitlesStreamingRuntime(
          updateTitle: (_, _) {
            final _ = Object();
          },
          removeTitle: removedIds.add,
        );

        final localUsecase = GenerateTitleUsecase(
          conversationRepo: conversationRepo,
          chatbotService: chatbotService,
          titlesStreamingRuntime: runtime,
          monitoringService: monitoringService,
        );

        final controller = StreamController<String>();
        when(chatbotService.streamTitle(any, any)).thenAnswer(
          (_) => controller.stream,
        );

        localUsecase.call(
          conversationId: 'conv-1',
          firstMessage: 'Hello',
          workspaceModelSelection: modelSelection,
        );

        final _ = await controller.close();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(removedIds, contains('conv-1'));
      },
    );

    test('updateTitle is called for each emitted title', () async {
      final updatedTitles = <String>[];
      final runtime = TitlesStreamingRuntime(
        updateTitle: (_, title) => updatedTitles.add(title),
        removeTitle: (_) {
          final _ = Object();
        },
      );

      final localUsecase = GenerateTitleUsecase(
        conversationRepo: conversationRepo,
        chatbotService: chatbotService,
        titlesStreamingRuntime: runtime,
        monitoringService: monitoringService,
      );

      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      localUsecase.call(
        conversationId: 'conv-1',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      controller.add('Title 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.add('Title 2');
      final _ = await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(updatedTitles, containsAll(['Title 1', 'Title 2']));
    });

    test('patches conversation with streamed titles', () async {
      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      usecase.call(
        conversationId: 'conv-1',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      controller.add('New Title');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final _ = await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        () => verify(conversationRepo.patchConversation(any, any)).called(1),
        returnsNormally,
      );
    });

    test('patches with latest title when multiple titles emitted', () async {
      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      usecase.call(
        conversationId: 'conv-1',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      controller.add('Title A');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.add('Title B');
      final _ = await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        () => verify(
          conversationRepo.patchConversation(any, any),
        ).called(greaterThanOrEqualTo(1)),
        returnsNormally,
      );
    });

    test('works with empty first message', () async {
      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      usecase.call(
        conversationId: 'conv-empty',
        firstMessage: '',
        workspaceModelSelection: modelSelection,
      );

      expect(
        () => verify(chatbotService.streamTitle(modelSelection, '')).called(1),
        returnsNormally,
      );
      final _ = await controller.close();
    });

    test('tracks error via monitoringService when stream fails', () async {
      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      usecase.call(
        conversationId: 'conv-err',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      controller.add('Partial');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final _ = await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        () => verifyNever(
          monitoringService.trackError(
            any,
            error: anyNamed('error'),
            stackTrace: anyNamed('stackTrace'),
          ),
        ),
        returnsNormally,
      );
    });

    test('removeTitle called when stream completes without error', () async {
      final removedIds = <String>[];
      final runtime = TitlesStreamingRuntime(
        updateTitle: (_, _) {
          final _ = Object();
        },
        removeTitle: removedIds.add,
      );
      final localUsecase = GenerateTitleUsecase(
        conversationRepo: conversationRepo,
        chatbotService: chatbotService,
        titlesStreamingRuntime: runtime,
        monitoringService: monitoringService,
      );

      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      localUsecase.call(
        conversationId: 'conv-done',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      final _ = await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(removedIds, contains('conv-done'));
    });

    test('coalescing save patches final title to repo', () async {
      final controller = StreamController<String>();
      when(chatbotService.streamTitle(any, any)).thenAnswer(
        (_) => controller.stream,
      );

      usecase.call(
        conversationId: 'conv-final',
        firstMessage: 'Hello',
        workspaceModelSelection: modelSelection,
      );

      controller.add('Final Title');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final _ = await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        () => verify(
          conversationRepo.patchConversation(
            'conv-final',
            argThat(
              isA<ConversationPatch>().having(
                (p) => p.title,
                'title',
                'Final Title',
              ),
            ),
          ),
        ).called(greaterThanOrEqualTo(1)),
        returnsNormally,
      );
    });
  });
}
