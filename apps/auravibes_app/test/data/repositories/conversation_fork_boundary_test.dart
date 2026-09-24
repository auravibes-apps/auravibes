import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppDatabase createDatabase() =>
      AppDatabase(connection: DatabaseConnection(NativeDatabase.memory()));

  var database = createDatabase();
  var repository = ConversationRepository(database);

  setUp(() async {
    await database.close();
    database = createDatabase();
    repository = ConversationRepository(database);
  });

  tearDown(() => database.close());

  Future<void> insertSource({String? reasoningConfigJson}) async {
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Test Workspace', type: .local),
    );
    final _ = await database.conversationDao.insertConversation(
      .new(
        id: const .new('source'),
        workspaceId: .new(workspace.id),
        title: const .new('Source'),
        reasoningConfigJson: .new(reasoningConfigJson),
      ),
    );
  }

  Future<MessagesTable> insertMessage({
    required String id,
    required DateTime createdAt,
    required bool isUser,
    required MessageTableStatus status,
    String? metadata,
  }) => database.messageDao.insertMessage(
    .new(
      id: .new(id),
      createdAt: .new(createdAt),
      updatedAt: .new(createdAt),
      conversationId: const .new('source'),
      content: .new(id),
      messageType: const .new(.text),
      isUser: .new(isUser),
      status: .new(status),
      metadata: .new(metadata),
    ),
  );

  test('fork copies conversation reasoning configuration', () async {
    const configuration = ReasoningConfiguration(effort: 'high');
    await insertSource(reasoningConfigJson: configuration.encode());
    final now = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: now,
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-1',
      createdAt: now.add(const Duration(seconds: 1)),
      isUser: false,
      status: .sent,
    );

    final fork = await repository.forkConversation('source');

    expect(fork.reasoningConfiguration?.encode(), configuration.encode());
  });

  test('sidebar fork stops before an active approval turn', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: base.subtract(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final completedAssistant = await insertMessage(
      id: 'assistant-1',
      createdAt: base,
      isUser: false,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'user-2',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final pendingMetadata = jsonEncode(
      const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'tool-1',
            name: 'calculator',
            argumentsRaw: '{}',
          ),
        ],
      ).toJson(),
    );
    final pendingAssistant = await insertMessage(
      id: 'assistant-2',
      createdAt: base.add(const Duration(seconds: 2)),
      isUser: false,
      status: .unfinished,
      metadata: pendingMetadata,
    );

    final fork = await repository.forkConversation('source');
    final messages = await MessageRepository(database)
        .getMessagesByConversation(fork.id);

    expect(fork.forkThroughMessageId, completedAssistant.id);
    expect(messages.map((message) => message.id), ['user-1', 'assistant-1']);
    expect(messages.every((message) => message.isForkReference), isTrue);
    final messageRepository = MessageRepository(database);
    await expectLater(
      messageRepository.patchMessage(
        pendingAssistant.id,
        const .new(content: 'fork mutation'),
        conversationId: fork.id,
      ),
      throwsA(isA<MessageValidationException>()),
    );
    final sourceMessage = await messageRepository.getMessageById(
      pendingAssistant.id,
    );
    final sourceMetadata = sourceMessage?.metadata;
    if (sourceMetadata == null) {
      throw StateError('Expected source tool-call metadata');
    }
    expect(sourceMetadata.toolCalls.single.isAwaitingApproval, isTrue);
    final approved = await messageRepository.patchMessage(
      pendingAssistant.id,
      .new(
        metadata: .new(
          toolCalls: [
            sourceMetadata.toolCalls.single.copyWith(resultStatus: .success),
          ],
        ),
        status: .sent,
      ),
      conversationId: 'source',
    );
    expect(approved.metadata?.toolCalls.single.isResolved, isTrue);
  });

  test('legacy sent approval rows are treated as active', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final completedAssistant = await insertMessage(
      id: 'assistant-1',
      createdAt: base,
      isUser: false,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'user-2',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-2',
      createdAt: base.add(const Duration(seconds: 2)),
      isUser: false,
      status: .sent,
      metadata: jsonEncode(
        const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{}',
            ),
          ],
        ).toJson(),
      ),
    );

    final fork = await repository.forkConversation('source');

    expect(fork.forkThroughMessageId, completedAssistant.id);
    await expectLater(
      repository.forkConversation('source', throughMessageId: 'assistant-2'),
      throwsA(isA<ConversationValidationException>()),
    );
  });

  test('nested forks do not inherit a later active turn', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: base.subtract(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );
    final completedAssistant = await insertMessage(
      id: 'assistant-1',
      createdAt: base,
      isUser: false,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'user-2',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: true,
      status: .sent,
    );

    final firstFork = await repository.forkConversation('source');
    final messageRepository = MessageRepository(database);
    final _ = await messageRepository.createMessage(
      .new(
        conversationId: firstFork.id,
        content: 'new prompt',
        messageType: .text,
        isUser: true,
        status: .sent,
      ),
    );
    final _ = await messageRepository.createMessage(
      .new(
        conversationId: firstFork.id,
        content: 'pending response',
        messageType: .text,
        isUser: false,
        status: .unfinished,
        metadata: jsonEncode(
          const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-2',
                name: 'calculator',
                argumentsRaw: '{}',
              ),
            ],
          ).toJson(),
        ),
      ),
    );

    final secondFork = await repository.forkConversation(firstFork.id);
    final messages = await messageRepository.getMessagesByConversation(
      secondFork.id,
    );

    expect(secondFork.forkThroughMessageId, completedAssistant.id);
    expect(messages.map((message) => message.id), ['user-1', 'assistant-1']);
  });

  test('no completed response before an active turn is rejected', () async {
    final _ = await insertSource();
    final base = DateTime.utc(2026);
    final _ = await insertMessage(
      id: 'user-1',
      createdAt: base,
      isUser: true,
      status: .sent,
    );
    final _ = await insertMessage(
      id: 'assistant-1',
      createdAt: base.add(const Duration(seconds: 1)),
      isUser: false,
      status: .unfinished,
      metadata: jsonEncode(
        const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{}',
            ),
          ],
        ).toJson(),
      ),
    );

    await expectLater(
      repository.forkConversation('source'),
      throwsA(isA<ConversationValidationException>()),
    );
  });

  test(
    'deleting source materializes fork and keeps shared attachments',
    () async {
      final _ = await insertSource();
      final base = DateTime.utc(2026);
      final sourceMessage = await insertMessage(
        id: 'assistant-1',
        createdAt: base,
        isUser: false,
        status: .sent,
      );
      final _ = await database
          .into(database.messageAttachments)
          .insert(
            MessageAttachmentsCompanion(
              messageId: .new(sourceMessage.id),
              localPath: const Value('/shared/image.png'),
              fileName: const Value('image.png'),
              displayName: const Value('image.png'),
              mimeType: const Value('image/png'),
              modality: const Value('image'),
              sizeBytes: const Value(10),
            ),
          );

      final fork = await repository.forkConversation(
        'source',
        throughMessageId: sourceMessage.id,
      );
      final boundaries = await repository.captureForkBoundaries('source');
      expect(boundaries[fork.id], sourceMessage.id);

      expect(
        await repository.deleteConversationWithFrozenForkBoundaries(
          'source',
          frozenForkBoundaries: boundaries,
        ),
        isTrue,
      );
      expect(await repository.getConversationById('source'), isNull);

      final materialized = await repository.getConversationById(fork.id);
      expect(materialized?.isForkMaterialized, isTrue);
      final messages = await MessageRepository(database)
          .getMessagesByConversation(fork.id);
      expect(messages, hasLength(1));
      expect(messages.single.id, isNot(sourceMessage.id));
      expect(messages.single.isForkReference, isFalse);
      expect(messages.single.attachments.single.localPath, '/shared/image.png');
    },
  );
}
