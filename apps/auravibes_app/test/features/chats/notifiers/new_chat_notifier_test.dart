import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_new_message_usecase.dart';
import 'package:auravibes_app/services/monitoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('NewChatState', () {
    test('default state has null modelId', () {
      const state = NewChatState();
      expect(state.modelId, isNull);
    });

    test('default state has null providerId', () {
      const state = NewChatState();
      expect(state.providerId, isNull);
    });

    test('default state has isLoading false', () {
      const state = NewChatState();
      expect(state.isLoading, isFalse);
    });

    test('copyWith modelId works', () {
      const state = NewChatState();
      final updated = state.copyWith(modelId: 'model-1');
      expect(updated.modelId, 'model-1');
    });

    test('copyWith providerId works', () {
      const state = NewChatState();
      final updated = state.copyWith(providerId: 'openai');
      expect(updated.providerId, 'openai');
    });

    test('copyWith isLoading works', () {
      const state = NewChatState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
    });

    test('equality works', () {
      const a = NewChatState();
      const b = NewChatState();
      expect(a, b);
    });

    test('inequality works', () {
      const a = NewChatState();
      const b = NewChatState(modelId: 'm1');
      expect(a, isNot(b));
    });

    test('hashCode matches for equal states', () {
      const a = NewChatState();
      const b = NewChatState();
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains relevant info', () {
      const state = NewChatState(modelId: 'm1', isLoading: true);
      expect(state.toString(), contains('NewChatState'));
    });
  });

  group('NewChatNotifier', () {
    var container = ProviderContainer();

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is default', () {
      final state = container.read(newChatProvider('ws-1'));
      expect(state.modelId, isNull);
      expect(state.providerId, isNull);
      expect(state.isLoading, isFalse);
    });

    test('setModelId updates modelId', () {
      container.read(newChatProvider('ws-1').notifier).setModelId('model-1');
      expect(
        container.read(newChatProvider('ws-1')).modelId,
        'model-1',
      );
    });

    test('setModelId can set to null', () {
      container.read(newChatProvider('ws-1').notifier).setModelId('model-1');
      container.read(newChatProvider('ws-1').notifier).setModelId(null);
      expect(container.read(newChatProvider('ws-1')).modelId, isNull);
    });

    test('setProvider updates providerId and resets modelId', () {
      container.read(newChatProvider('ws-1').notifier).setModelId('model-1');
      container.read(newChatProvider('ws-1').notifier).setProvider('openai');
      final state = container.read(newChatProvider('ws-1'));
      expect(state.providerId, 'openai');
      expect(state.modelId, isNull);
    });

    test('setProvider can set to null', () {
      container.read(newChatProvider('ws-1').notifier).setProvider('openai');
      container.read(newChatProvider('ws-1').notifier).setProvider(null);
      expect(
        container.read(newChatProvider('ws-1')).providerId,
        isNull,
      );
    });

    test('startConversation throws when no model selected', () {
      final notifier = container.read(newChatProvider('ws-1').notifier);
      expect(
        () => notifier.startConversation('hello'),
        throwsA(isA<Exception>()),
      );
    });

    test('different workspace IDs create independent notifiers', () {
      container.read(newChatProvider('ws-1').notifier).setModelId('m1');
      container.read(newChatProvider('ws-2').notifier).setModelId('m2');
      expect(container.read(newChatProvider('ws-1')).modelId, 'm1');
      expect(container.read(newChatProvider('ws-2')).modelId, 'm2');
    });

    test('startConversation sets isLoading and returns conversation', () async {
      final sendContainer = ProviderContainer(
        overrides: [
          sendNewMessageUsecaseProvider.overrideWithValue(
            _FakeSendNewMessageUsecase(),
          ),
        ],
      );
      addTearDown(sendContainer.dispose);

      sendContainer.read(newChatProvider('ws-1').notifier).setModelId('m1');
      final result = await sendContainer
          .read(newChatProvider('ws-1').notifier)
          .startConversation('hello');

      expect(result, isA<ConversationEntity>());
      expect(result.id, 'new-conv');
      expect(
        sendContainer.read(newChatProvider('ws-1')).isLoading,
        isFalse,
      );
    });

    test('startConversation resets isLoading on error', () async {
      final sendContainer = ProviderContainer(
        overrides: [
          sendNewMessageUsecaseProvider.overrideWithValue(
            _ErrorSendNewMessageUsecase(),
          ),
        ],
      );
      addTearDown(sendContainer.dispose);

      sendContainer.read(newChatProvider('ws-1').notifier).setModelId('m1');

      try {
        final _ = await sendContainer
            .read(newChatProvider('ws-1').notifier)
            .startConversation('hello');
      } on Object catch (_) {}

      expect(
        sendContainer.read(newChatProvider('ws-1')).isLoading,
        isFalse,
      );
    });
  });
}

class _FakeSendNewMessageUsecase implements SendNewMessageUsecase {
  @override
  ConversationRepository get conversationRepo => throw UnimplementedError();

  @override
  SendMessageUsecase get sendMessageUsecase => throw UnimplementedError();

  @override
  WorkspaceModelSelectionRepository get workspaceModelSelectionRepository =>
      throw UnimplementedError();

  @override
  GenerateTitleUsecase get generateTitleUsecase => throw UnimplementedError();

  @override
  MonitoringService get monitoringService => throw UnimplementedError();

  @override
  Future<ConversationEntity> call({
    required String workspaceId,
    required String firstMessage,
    required String workspaceModelSelectionId,
  }) async {
    return ConversationEntity(
      id: 'new-conv',
      title: 'New',
      workspaceId: workspaceId,
      isPinned: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }
}

class _ErrorSendNewMessageUsecase implements SendNewMessageUsecase {
  @override
  ConversationRepository get conversationRepo => throw UnimplementedError();

  @override
  SendMessageUsecase get sendMessageUsecase => throw UnimplementedError();

  @override
  WorkspaceModelSelectionRepository get workspaceModelSelectionRepository =>
      throw UnimplementedError();

  @override
  GenerateTitleUsecase get generateTitleUsecase => throw UnimplementedError();

  @override
  MonitoringService get monitoringService => throw UnimplementedError();

  @override
  Future<ConversationEntity> call({
    required String workspaceId,
    required String firstMessage,
    required String workspaceModelSelectionId,
  }) async {
    throw Exception('send failed');
  }
}
