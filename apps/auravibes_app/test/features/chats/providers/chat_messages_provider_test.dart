import 'dart:async';

import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_model_selection_repository.dart';
import 'package:auravibes_app/features/chats/notifiers/messages_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain/langchain.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

List<String> _messageIds(ProviderContainer container) =>
    container.read(chatMessagesProvider).value?.map((m) => m.id).toList() ??
    const [];

void main() {
  group('chatMessagesProvider', () {
    late _FakeMessageRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeMessageRepository();
      container = ProviderContainer(
        overrides: [
          conversationSelectedProvider.overrideWithValue('conversation-1'),
          messageRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    test('updates from repository stream without one-shot refetches', () async {
      final secondEmission = Completer<void>();
      container.listen(chatMessagesProvider, (_, next) {
        if (next.value?.length == 2 && !secondEmission.isCompleted) {
          secondEmission.complete();
        }
      }, fireImmediately: true);

      repository.emit([
        _message(id: 'message-1', content: 'hello', isUser: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchedConversationIds, ['conversation-1']);
      expect(repository.getMessagesByConversationCallCount, 0);
      expect(
        container.read(chatMessagesProvider).value,
        [
          _message(id: 'message-1', content: 'hello', isUser: true),
        ],
      );
      expect(_messageIds(container), ['message-1']);

      repository.emit([
        _message(id: 'message-1', content: 'hello', isUser: true),
        _message(id: 'message-2', content: 'hi there', isUser: false),
      ]);
      await secondEmission.future;

      expect(
        container.read(chatMessagesProvider).value,
        [
          _message(id: 'message-1', content: 'hello', isUser: true),
          _message(id: 'message-2', content: 'hi there', isUser: false),
        ],
      );
      expect(_messageIds(container), ['message-1', 'message-2']);
    });

    test('applies streaming overlay only in message provider', () async {
      container
        ..listen(chatMessagesProvider, (_, _) {}, fireImmediately: true)
        ..listen(
          messageConversationByIdProvider('message-1'),
          (_, _) {},
          fireImmediately: true,
        );

      repository.emit([
        _message(id: 'message-1', content: 'persisted', isUser: false),
      ]);
      await Future<void>.delayed(Duration.zero);

      container.read(messagesStreamingProvider.notifier)
        ..startSubscription(CompositeSubscription(), 'message-1')
        ..updateResult(
          const ChatResult(
            id: 'chunk-1',
            output: AIChatMessage(content: 'streaming'),
            finishReason: FinishReason.unspecified,
            metadata: {},
            usage: LanguageModelUsage(),
            streaming: true,
          ),
          'message-1',
        );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(chatMessagesProvider).value,
        [_message(id: 'message-1', content: 'persisted', isUser: false)],
      );
      expect(
        container.read(messageConversationByIdProvider('message-1'))?.content,
        'streaming',
      );
    });

    test(
      'uses latest assistant usage and replaces with streaming value',
      () async {
        container
          ..listen(
            chatMessagesProvider,
            (_, _) {},
            fireImmediately: true,
          )
          ..listen(
            conversationUsedTokensProvider,
            (_, _) {},
            fireImmediately: true,
          );

        repository.emit([
          _message(
            id: 'message-1',
            content: 'first',
            isUser: true,
            metadata: const MessageMetadataEntity(totalTokens: 1000),
          ),
          _message(
            id: 'message-2',
            content: 'second',
            isUser: false,
            metadata: const MessageMetadataEntity(totalTokens: 500),
          ),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(conversationUsedTokensProvider), 500);

        container.read(messagesStreamingProvider.notifier)
          ..startSubscription(CompositeSubscription(), 'message-2')
          ..updateResult(
            const ChatResult(
              id: 'chunk-2',
              output: AIChatMessage(content: 'streaming'),
              finishReason: FinishReason.unspecified,
              metadata: {},
              usage: LanguageModelUsage(totalTokens: 900),
              streaming: true,
            ),
            'message-2',
          );
        await Future<void>.delayed(Duration.zero);

        expect(container.read(conversationUsedTokensProvider), 900);
      },
    );
  });

  group('modelContextLimitProvider', () {
    test('prefers provider-specific model when IDs collide', () async {
      final fakeCredentialsRepo = _FakeWorkspaceModelSelectionRepository(
        selectedModel: _workspaceModelSelectionWithProvider(
          credentialModelId: 'cm-1',
          modelId: 'shared-model',
          providerId: 'provider-b',
        ),
      );
      final fakeApiRepo = _FakeApiModelRepository(
        models: [
          _apiModel(id: 'shared-model', providerId: 'provider-a', limit: 1000),
          _apiModel(id: 'shared-model', providerId: 'provider-b', limit: 2500),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            fakeCredentialsRepo,
          ),
          apiModelRepositoryProvider.overrideWithValue(fakeApiRepo),
        ],
      );
      addTearDown(container.dispose);

      final limit = await container.read(
        modelContextLimitProvider('cm-1').future,
      );

      expect(limit, 2500);
    });

    test('does not normalize model IDs when resolving context limit', () async {
      final fakeCredentialsRepo = _FakeWorkspaceModelSelectionRepository(
        selectedModel: _workspaceModelSelectionWithProvider(
          credentialModelId: 'cm-2',
          modelId: 'openrouter/gpt-5.3-chat-latest',
          providerId: 'openrouter',
        ),
      );
      final fakeApiRepo = _FakeApiModelRepository(
        models: [
          _apiModel(
            id: 'gpt-5.3-chat',
            providerId: 'openrouter',
            limit: 272000,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          workspaceModelSelectionRepositoryProvider.overrideWithValue(
            fakeCredentialsRepo,
          ),
          apiModelRepositoryProvider.overrideWithValue(fakeApiRepo),
        ],
      );
      addTearDown(container.dispose);

      final limit = await container.read(
        modelContextLimitProvider('cm-2').future,
      );

      expect(limit, isNull);
    });
  });
}

MessageEntity _message({
  required String id,
  required String content,
  required bool isUser,
  MessageMetadataEntity? metadata,
}) {
  final now = DateTime(2026);

  return MessageEntity(
    id: id,
    conversationId: 'conversation-1',
    content: content,
    messageType: MessageType.text,
    isUser: isUser,
    status: MessageStatus.sent,
    createdAt: now,
    updatedAt: now,
    metadata: metadata,
  );
}

ApiModelEntity _apiModel({
  required String id,
  required String providerId,
  required int limit,
}) {
  return ApiModelEntity(
    id: id,
    name: id,
    modelProvider: providerId,
    limitContext: limit,
    limitOutput: 4096,
    modalitiesInput: const ['text'],
    modalitiesOuput: const ['text'],
  );
}

WorkspaceModelSelectionWithConnectionEntity
_workspaceModelSelectionWithProvider({
  required String credentialModelId,
  required String modelId,
  required String providerId,
}) {
  final now = DateTime(2026);
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: credentialModelId,
      modelId: modelId,
      modelConnectionId: 'cred-1',
      createdAt: now,
      updatedAt: now,
    ),
    modelConnection: ModelConnectionEntity(
      id: 'cred-1',
      name: 'Test Provider',
      key: 'encrypted',
      workspaceId: 'workspace-1',
      modelId: providerId,
      createdAt: now,
      updatedAt: now,
    ),
    modelsProvider: ApiModelProviderEntity(
      id: providerId,
      name: providerId,
      type: ModelProvidersType.openai,
    ),
  );
}

class _FakeMessageRepository implements MessageRepository {
  final StreamController<List<MessageEntity>> _controller =
      StreamController<List<MessageEntity>>.broadcast();

  final List<String> watchedConversationIds = [];
  int getMessagesByConversationCallCount = 0;

  void emit(List<MessageEntity> messages) {
    _controller.add(messages);
  }

  Future<void> dispose() {
    return _controller.close();
  }

  @override
  Future<MessageEntity> createMessage(MessageToCreate message) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteMessage(String id) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity?> getMessageById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<int> getMessageCountByConversation(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async {
    getMessagesByConversationCallCount++;
    return const [];
  }

  @override
  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getSystemMessages(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<List<MessageEntity>> getUserMessages(String conversationId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> messageExists(String id) {
    throw UnimplementedError();
  }

  @override
  Future<MessageEntity> patchMessage(String id, MessagePatch message) {
    throw UnimplementedError();
  }

  @override
  Future<bool> validateMessage(MessageToCreate message) {
    throw UnimplementedError();
  }

  @override
  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) {
    watchedConversationIds.add(conversationId);
    return _controller.stream;
  }
}

class _FakeWorkspaceModelSelectionRepository
    implements WorkspaceModelSelectionRepository {
  _FakeWorkspaceModelSelectionRepository({this.selectedModel});

  final WorkspaceModelSelectionWithConnectionEntity? selectedModel;

  @override
  Future<void> createWorkspaceModelSelections(
    List<WorkspaceModelSelectionToCreate> workspaceModelSelections,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<WorkspaceModelSelectionWithConnectionEntity?>
  getWorkspaceModelSelectionById(
    String id,
  ) async {
    return selectedModel;
  }

  @override
  Future<List<WorkspaceModelSelectionWithConnectionEntity>>
  getWorkspaceModelSelections(
    WorkspaceModelSelectionFilter filter,
  ) {
    throw UnimplementedError();
  }
}

class _FakeApiModelRepository implements ApiModelRepository {
  _FakeApiModelRepository({required this.models});

  final List<ApiModelEntity> models;

  @override
  Future<List<ApiModelEntity>> getAllModels() async => models;

  @override
  Future<ApiModelEntity?> getModelByProviderAndModelId(
    String providerId,
    String modelId,
  ) async {
    return models
        .where(
          (model) => model.modelProvider == providerId && model.id == modelId,
        )
        .firstOrNull;
  }

  @override
  Future<List<ApiModelEntity>> getModelsByProvider(String providerId) async {
    return [
      for (final model in models)
        if (model.modelProvider == providerId) model,
    ];
  }

  @override
  Future<List<ApiModelProviderEntity>> getAllProviders() {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelProviderEntity>> getProvidersByType(String type) {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelProviderEntity>> batchUpsertProviders(
    List<ApiModelProviderEntity> providers,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ApiModelEntity>> batchUpsertModels(List<ApiModelEntity> models) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteAllData() {
    throw UnimplementedError();
  }
}
