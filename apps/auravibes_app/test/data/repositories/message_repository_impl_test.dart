import 'dart:async';
import 'dart:collection';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/message_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/messages_table.dart';
import 'package:auravibes_app/data/repositories/message_repository_impl.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:drift/drift.dart';
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
      expect(messages.first.id, 'message-1');
      expect(messages.first.content, 'hello');
      expect(messages.first.messageType, MessageType.text);
      expect(messages.last.id, 'message-2');
      expect(messages.last.content, 'hi');
      expect(messages.last.isUser, isFalse);
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
        expect(stackTrace.toString(), contains('_ThrowingMessagesList.[]'));
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
    messageType: MessagesTableType.text,
    isUser: isUser,
    status: MessageTableStatus.sent,
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
