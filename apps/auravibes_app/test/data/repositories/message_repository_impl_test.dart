// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/message_dao.dart';
import 'package:auravibes_app/data/repositories/message_repository_impl.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageRepositoryImpl.watchMessagesByConversation', () {
    late _TestAppDatabase database;
    late MessageRepositoryImpl repository;

    tearDown(() async {
      await database.close();
    });

    test('maps streamed message rows into message entities', () async {
      database = _TestAppDatabase(
        (_) => Stream.value([
          _messageRow(id: 'message-1', content: 'hello', isUser: true),
          _messageRow(id: 'message-2', content: 'hi', isUser: false),
        ]),
      );
      repository = MessageRepositoryImpl(database);

      final messages = await repository
          .watchMessagesByConversation('conversation-1')
          .first;

      expect(messages, hasLength(2));
      expect(messages.firstOrNull?.id, 'message-1');
      expect(messages.firstOrNull?.content, 'hello');
      expect(messages.firstOrNull?.messageType, MessageType.text);
      expect(messages.lastOrNull?.id, 'message-2');
      expect(messages.lastOrNull?.content, 'hi');
      expect(messages.lastOrNull?.isUser, isFalse);
    });

    test('wraps stream Exceptions in MessageException', () async {
      const failure = FormatException('broken stream');
      database = _TestAppDatabase(
        (_) => Stream<List<MessagesTable>>.error(failure),
      );
      repository = MessageRepositoryImpl(database);

      await expectLater(
        repository.watchMessagesByConversation('conversation-1'),
        emitsError(
          isA<MessageException>()
              .having(
                (error) => error.message,
                'message',
                'Failed to watch messages for conversation conversation-1',
              )
              .having((error) => error.cause, 'cause', failure),
        ),
      );
    });

    test('passes through non-Exception stream errors unchanged', () async {
      final failure = _TestError();
      database = _TestAppDatabase(
        (_) => Stream<List<MessagesTable>>.error(failure),
      );
      repository = MessageRepositoryImpl(database);

      await expectLater(
        repository.watchMessagesByConversation('conversation-1'),
        emitsError(same(failure)),
      );
    });

    test(
      'preserves stack trace when mapping streamed messages fails',
      () async {
        database = _TestAppDatabase(
          (_) => Stream.value(_ThrowingMessagesList()),
        );
        repository = MessageRepositoryImpl(database);

        final errorCompleter = Completer<Object>();
        final stackTraceCompleter = Completer<StackTrace>();

        final subscription = repository
            .watchMessagesByConversation('conversation-1')
            .listen(
              (_) {},
              onError: (Object error, StackTrace stackTrace) {
                errorCompleter.complete(error);
                stackTraceCompleter.complete(stackTrace);
              },
            );

        addTearDown(subscription.cancel);

        final error = await errorCompleter.future;
        final stackTrace = await stackTraceCompleter.future;

        expect(error, isA<MessageException>());
        expect(
          (error as MessageException).message,
          'Failed to watch messages for conversation conversation-1',
        );
        expect(error.cause, isA<FormatException>());
        expect(stackTrace.toString(), contains('_ThrowingMessagesList'));
      },
    );
  });

  group('MessageRepositoryImpl with real database', () {
    late AppDatabase database;
    late MessageRepositoryImpl repository;

    setUp(() {
      database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      repository = MessageRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
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
      expect(found!.content, 'test');
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

    test('patchMessage throws for non-existent', () async {
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

    test('validateMessage throws for invalid message', () async {
      expect(
        () => repository.validateMessage(
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
      expect(found!.metadata, isNotNull);
      expect(found.metadata!.promptTokens, 10);
    });

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
        expect(summary!.content, 'Compaction summary content');
        expect(summary.messageType, MessageType.system);
        expect(summary.metadata, isNotNull);
        expect(summary.metadata!.isCompactionSummary, isTrue);
        expect(summary.metadata!.compactionKind, CompactionKind.auto);
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

MessagesTable _messageRow({
  required String id,
  required String content,
  required bool isUser,
}) {
  final now = DateTime(2026);

  return MessagesTable(
    id: id,
    createdAt: now,
    updatedAt: now,
    conversationId: 'conversation-1',
    content: content,
    messageType: .text,
    isUser: isUser,
    status: .sent,
  );
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(this._watchMessages)
    : super(connection: DatabaseConnection(NativeDatabase.memory()));

  final Stream<List<MessagesTable>> Function(String conversationId)
  _watchMessages;

  late final MessageDao _testMessageDao = _TestMessageDao(this, _watchMessages);

  @override
  MessageDao get messageDao => _testMessageDao;
}

class _TestMessageDao extends MessageDao {
  _TestMessageDao(super.attachedDatabase, this._watchMessages);

  final Stream<List<MessagesTable>> Function(String conversationId)
  _watchMessages;

  @override
  Stream<List<MessagesTable>> watchMessagesByConversation(
    String conversationId,
  ) {
    return _watchMessages(conversationId);
  }
}

class _TestError extends Error {}

class _ThrowingMessagesList extends ListBase<MessagesTable> {
  @override
  int get length => 1;

  @override
  set length(int value) {
    throw UnsupportedError('length mutation is not supported');
  }

  @override
  MessagesTable operator [](int index) {
    throw const FormatException('bad message row');
  }

  @override
  void operator []=(int index, MessagesTable value) {
    throw UnsupportedError('item mutation is not supported');
  }
}
