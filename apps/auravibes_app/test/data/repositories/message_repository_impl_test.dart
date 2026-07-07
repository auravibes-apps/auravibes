import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageRepository with real database', () {
    final initialDatabase = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    var database = initialDatabase;
    var repository = MessageRepository(database);

    setUp(() {
      database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      repository = MessageRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    tearDownAll(() async {
      await initialDatabase.close();
    });

    test('getMessagesByConversation returns empty when no messages', () async {
      final messages = await repository.getMessagesByConversation('conv-1');
      expect(messages, isEmpty);
    });

    test('createMessage and retrieve it', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'hello world',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      expect(created.conversationId, 'conv-1');
      expect(created.content, 'hello world');
      expect(created.messageType, MessageType.text);
      expect(created.isUser, isTrue);

      final messages = await repository.getMessagesByConversation('conv-1');
      expect(messages, hasLength(1));
      expect(messages.firstOrNull?.id, created.id);
    });

    test(
      'watchMessagesByConversation streams messages with attachments',
      () async {
        final fileStore = _FakeAttachmentFileStore();
        repository = MessageRepository(
          database,
          attachmentFileStore: fileStore,
        );
        final stream = repository.watchMessagesByConversation('conv-1');

        final created = await repository.createMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: 'see attachment',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sent,
            attachments: [
              MessageAttachmentToCreate(
                localPath: '/tmp/image.png',
                fileName: 'image.png',
                displayName: 'image.png',
                mimeType: 'image/png',
                modality: MessageAttachmentModality.image,
                sizeBytes: 10,
              ),
            ],
          ),
        );

        final messages = await stream.firstWhere(
          (messages) => messages.isNotEmpty,
        );

        expect(messages, hasLength(1));
        expect(messages.single.id, created.id);
        expect(messages.single.attachments, hasLength(1));
        expect(messages.single.attachments.single.fileName, 'image.png');
      },
    );

    test('getMessageById returns null for non-existent', () async {
      final message = await repository.getMessageById('nonexistent');
      expect(message, isNull);
    });

    test('getMessageById returns created message', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'test',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      final found = await repository.getMessageById(created.id);
      expect(found, isNotNull);
      expect((found ?? fail('Expected found to be non-null')).content, 'test');
    });

    test('messageExists returns false for non-existent', () async {
      expect(await repository.messageExists('nonexistent'), isFalse);
    });

    test('messageExists returns true for existing', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'test',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      expect(await repository.messageExists(created.id), isTrue);
    });

    test('deleteMessage returns false for non-existent', () async {
      expect(await repository.deleteMessage('nonexistent'), isFalse);
    });

    test('deleteMessage returns true and removes message', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'to delete',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      expect(await repository.deleteMessage(created.id), isTrue);
      expect(await repository.getMessageById(created.id), isNull);
    });

    test('createMessage persists draft attachment path', () async {
      final fileStore = _FakeAttachmentFileStore(
        persistedPaths: {'/tmp/draft.png': '/support/draft.png'},
      );
      repository = MessageRepository(
        database,
        attachmentFileStore: fileStore,
      );

      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'see attachment',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          attachments: [
            MessageAttachmentToCreate(
              localPath: '/tmp/draft.png',
              fileName: 'draft.png',
              displayName: 'draft.png',
              mimeType: 'image/png',
              modality: MessageAttachmentModality.image,
              sizeBytes: 10,
            ),
          ],
        ),
      );

      expect(fileStore.persisted, ['/tmp/draft.png']);
      expect(created.attachments.single.localPath, '/support/draft.png');
      expect(fileStore.deleted, ['/tmp/draft.png']);
    });

    test('deleteMessage deletes persisted attachment files', () async {
      final fileStore = _FakeAttachmentFileStore(
        persistedPaths: {'/tmp/draft.png': '/support/image.png'},
      );
      repository = MessageRepository(
        database,
        attachmentFileStore: fileStore,
      );
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'see attachment',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          attachments: [
            MessageAttachmentToCreate(
              localPath: '/tmp/draft.png',
              fileName: 'image.png',
              displayName: 'image.png',
              mimeType: 'image/png',
              modality: MessageAttachmentModality.image,
              sizeBytes: 10,
            ),
          ],
        ),
      );

      expect(await repository.deleteMessage(created.id), isTrue);

      expect(fileStore.deleted, ['/tmp/draft.png', '/support/image.png']);
    });

    test('getMessageCountByConversation returns correct count', () async {
      expect(await repository.getMessageCountByConversation('conv-1'), 0);

      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'msg1',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'msg2',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sending,
        ),
      );

      expect(await repository.getMessageCountByConversation('conv-1'), 2);
    });

    test('patchMessage updates content', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'original',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      final patched = await repository.patchMessage(
        created.id,
        const MessagePatch(content: 'updated'),
      );
      expect(patched.content, 'updated');
    });

    test('patchMessage throws for non-existent', () {
      expect(
        () => repository.patchMessage(
          'nonexistent',
          const MessagePatch(content: 'x'),
        ),
        throwsA(isA<MessageNotFoundException>()),
      );
    });

    test('getMessagesByConversationPaginated limits results', () async {
      for (var i = 0; i < 5; i++) {
        final _ = await repository.createMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: 'msg0',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
          ),
        );
      }

      final page = await repository.getMessagesByConversationPaginated(
        'conv-1',
        2,
        0,
      );
      expect(page, hasLength(2));
    });

    test('getMessagesByType filters correctly', () async {
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'text msg',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      final textMessages = await repository.getMessagesByType(
        'conv-1',
        MessageType.text,
      );
      expect(textMessages, hasLength(1));

      final systemMessages = await repository.getMessagesByType(
        'conv-1',
        MessageType.system,
      );
      expect(systemMessages, isEmpty);
    });

    test('getMessagesByStatus filters correctly', () async {
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'sent msg',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      final sentMessages = await repository.getMessagesByStatus(
        'conv-1',
        MessageStatus.sent,
      );
      expect(sentMessages, isEmpty);

      final sendingMessages = await repository.getMessagesByStatus(
        'conv-1',
        MessageStatus.sending,
      );
      expect(sendingMessages, hasLength(1));
    });

    test('validateMessage returns true for valid message', () async {
      final valid = await repository.validateMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );
      expect(valid, isTrue);
    });

    test('validateMessage accepts sent message with content', () async {
      final valid = await repository.validateMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
        ),
      );
      expect(valid, isTrue);
    });

    test('validateMessage rejects sent message without content', () async {
      await expectLater(
        repository.validateMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: '',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.sent,
            metadata: '{}',
          ),
        ),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test('validateMessage rejects sent message with blank content', () async {
      await expectLater(
        repository.validateMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: '   ',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.sent,
            metadata: '{}',
          ),
        ),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test('validateMessage throws for invalid message', () async {
      await expectLater(
        repository.validateMessage(
          const MessageToCreate(
            conversationId: '',
            content: '',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
          ),
        ),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test('getUserMessages returns only user messages', () async {
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'user msg',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'ai msg',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sending,
        ),
      );

      final userMessages = await repository.getUserMessages('conv-1');
      expect(userMessages, hasLength(1));
      expect(userMessages.firstOrNull?.isUser, isTrue);
    });

    test('getSystemMessages returns only non-user messages', () async {
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'user msg',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'ai msg',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sending,
        ),
      );

      final systemMessages = await repository.getSystemMessages('conv-1');
      expect(systemMessages, hasLength(1));
      expect(systemMessages.firstOrNull?.isUser, isFalse);
    });

    test('patchMessage with status updates status', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'test',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      final patched = await repository.patchMessage(
        created.id,
        const MessagePatch(status: MessageStatus.sent),
      );
      expect(patched.status, MessageStatus.sent);
    });

    test(
      'patchMessage allows sent status for empty tool-call content',
      () async {
        const metadata = MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{"input":"2+2"}',
            ),
          ],
        );

        final created = await repository.createMessage(
          MessageToCreate(
            conversationId: 'conv-1',
            content: '',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.unfinished,
            metadata: jsonEncode(metadata.toJson()),
          ),
        );

        final patched = await repository.patchMessage(
          created.id,
          const MessagePatch(status: MessageStatus.sent),
        );

        expect(patched.status, MessageStatus.sent);
        expect(patched.content, isEmpty);
        expect(patched.metadata?.toolCalls, hasLength(1));
      },
    );

    test('patchMessage rejects sent status for empty content', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: '',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.unfinished,
          metadata: '{}',
        ),
      );

      await expectLater(
        repository.patchMessage(
          created.id,
          const MessagePatch(status: MessageStatus.sent),
        ),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test('patchMessage rejects sent status for blank content', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: '   ',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.unfinished,
          metadata: '{}',
        ),
      );

      await expectLater(
        repository.patchMessage(
          created.id,
          const MessagePatch(status: MessageStatus.sent),
        ),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test('createMessage with metadata stores it', () async {
      final created = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'test',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sending,
          metadata: '{"promptTokens":10}',
        ),
      );

      final found = await repository.getMessageById(created.id);
      expect(found, isNotNull);
      expect(
        (found ?? fail('Expected found to be non-null')).metadata,
        isNotNull,
      );
      expect(
        (found.metadata ?? fail('Expected found.metadata to be non-null'))
            .promptTokens,
        10,
      );
    });

    test(
      'createMessage allows empty assistant content with metadata',
      () async {
        const metadata = MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(
              id: 'tool-1',
              name: 'calculator',
              argumentsRaw: '{"input":"2+2"}',
            ),
          ],
        );

        final created = await repository.createMessage(
          MessageToCreate(
            conversationId: 'conv-1',
            content: '',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.unfinished,
            metadata: jsonEncode(metadata.toJson()),
          ),
        );

        final found = await repository.getMessageById(created.id);
        expect(found, isNotNull);
        final foundMessage = found ?? fail('Expected created message');
        expect(foundMessage.content, isEmpty);
        expect(foundMessage.metadata?.toolCalls, hasLength(1));
        expect(foundMessage.metadata?.toolCalls.single.id, 'tool-1');
      },
    );

    test('createMessage rejects empty user content with metadata', () {
      expect(
        () => repository.createMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: '',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
            metadata: '{"promptTokens":10}',
          ),
        ),
        throwsA(isA<MessageValidationException>()),
      );
    });

    test(
      'createMessage rejects empty assistant content with invalid metadata',
      () {
        expect(
          () => repository.createMessage(
            const MessageToCreate(
              conversationId: 'conv-1',
              content: '',
              messageType: MessageType.text,
              isUser: false,
              status: MessageStatus.unfinished,
              metadata: 'not json',
            ),
          ),
          throwsA(isA<MessageValidationException>()),
        );
      },
    );

    test(
      'createMessage rejects empty assistant content with blank metadata',
      () {
        expect(
          () => repository.createMessage(
            const MessageToCreate(
              conversationId: 'conv-1',
              content: '',
              messageType: MessageType.text,
              isUser: false,
              status: MessageStatus.unfinished,
              metadata: '   ',
            ),
          ),
          throwsA(isA<MessageValidationException>()),
        );
      },
    );

    test('getLatestCompactionSummary returns null when no summaries', () async {
      final _ = await repository.createMessage(
        const MessageToCreate(
          conversationId: 'conv-1',
          content: 'regular msg',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sending,
        ),
      );

      final summary = await repository.getLatestCompactionSummary('conv-1');
      expect(summary, isNull);
    });

    test(
      'getLatestCompactionSummary returns latest compaction summary',
      () async {
        final _ = await repository.createMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: 'user msg',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sending,
          ),
        );

        final compactionMetadata = const MessageMetadataEntity(
          metadataVersion: 2,
          isCompactionSummary: true,
          compactionKind: CompactionKind.auto,
          compactedFromMessageId: 'msg-1',
          compactedThroughMessageId: 'msg-2',
          compactedMessageIds: ['msg-1', 'msg-2'],
        ).toJson();

        final created = await repository.createMessage(
          MessageToCreate(
            conversationId: 'conv-1',
            content: 'Compaction summary content',
            messageType: MessageType.system,
            isUser: false,
            status: MessageStatus.sending,
            metadata: jsonEncode(compactionMetadata),
          ),
        );
        final _ = await repository.patchMessage(
          created.id,
          const MessagePatch(status: MessageStatus.sent),
        );

        final summary = await repository.getLatestCompactionSummary('conv-1');
        expect(summary, isNotNull);
        expect(
          (summary ?? fail('Expected summary to be non-null')).content,
          'Compaction summary content',
        );
        expect(summary.messageType, MessageType.system);
        expect(summary.metadata, isNotNull);
        expect(
          (summary.metadata ?? fail('Expected summary.metadata to be non-null'))
              .isCompactionSummary,
          isTrue,
        );
        expect(
          (summary.metadata ?? fail('Expected summary.metadata to be non-null'))
              .compactionKind,
          CompactionKind.auto,
        );
      },
    );

    test(
      'getLatestCompactionSummary skips non-summary system messages',
      () async {
        final _ = await repository.createMessage(
          const MessageToCreate(
            conversationId: 'conv-1',
            content: 'system note',
            messageType: MessageType.system,
            isUser: false,
            status: MessageStatus.sending,
          ),
        );

        final summary = await repository.getLatestCompactionSummary('conv-1');
        expect(summary, isNull);
      },
    );
  });
}

class _FakeAttachmentFileStore extends AttachmentFileStore {
  _FakeAttachmentFileStore({Map<String, String>? persistedPaths})
    : _persistedPaths = persistedPaths ?? const {};

  final Map<String, String> _persistedPaths;
  final persisted = <String>[];
  final deleted = <String>[];

  @override
  Future<String> persistDraftFile(String localPath) async {
    persisted.add(localPath);

    return _persistedPaths[localPath] ?? localPath;
  }

  @override
  Future<void> deleteFile(String localPath) async {
    deleted.add(localPath);
  }
}
