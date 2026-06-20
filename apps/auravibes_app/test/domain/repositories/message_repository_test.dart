// ignore_for_file: cascade_invocations
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubMessageRepository implements MessageRepository {
  List<MessageEntity> messagesByConversation = [];
  List<MessageEntity> messagesPaginated = [];
  List<MessageEntity> messagesByType = [];
  List<MessageEntity> userMessages = [];
  List<MessageEntity> systemMessages = [];
  MessageEntity? messageById;
  List<MessageEntity> created = [];
  List<MessageEntity> patched = [];
  bool deleteResult = true;
  bool existsResult = false;
  List<MessageEntity> messagesByStatus = [];
  int countResult = 0;
  bool validateResult = true;

  @override
  Future<List<MessageEntity>> getMessagesByConversation(
    String conversationId,
  ) async {
    return messagesByConversation;
  }

  @override
  Stream<List<MessageEntity>> watchMessagesByConversation(
    String conversationId,
  ) {
    return Stream.value(messagesByConversation);
  }

  @override
  Future<List<MessageEntity>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) async {
    return messagesPaginated;
  }

  @override
  Future<List<MessageEntity>> getMessagesByType(
    String conversationId,
    MessageType messageType,
  ) async {
    return messagesByType;
  }

  @override
  Future<List<MessageEntity>> getUserMessages(
    String conversationId,
  ) async {
    return userMessages;
  }

  @override
  Future<List<MessageEntity>> getSystemMessages(
    String conversationId,
  ) async {
    return systemMessages;
  }

  @override
  Future<MessageEntity?> getMessageById(String id) async {
    return messageById;
  }

  @override
  Future<MessageEntity> createMessage(MessageToCreate message) async {
    final entity = MessageEntity(
      id: 'm-${created.length}',
      conversationId: message.conversationId,
      content: message.content,
      messageType: message.messageType,
      isUser: message.isUser,
      status: message.status,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    created.add(entity);

    return entity;
  }

  @override
  Future<MessageEntity> patchMessage(
    String id,
    MessagePatch message,
  ) async {
    final entity = MessageEntity(
      id: id,
      conversationId: 'conv-1',
      content: message.content ?? 'patched',
      messageType: MessageType.text,
      isUser: true,
      status: message.status ?? MessageStatus.sent,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    patched.add(entity);

    return entity;
  }

  @override
  Future<bool> deleteMessage(String id) async {
    return deleteResult;
  }

  @override
  Future<bool> messageExists(String id) async {
    return existsResult;
  }

  @override
  Future<List<MessageEntity>> getMessagesByStatus(
    String conversationId,
    MessageStatus status,
  ) async {
    return messagesByStatus;
  }

  @override
  Future<int> getMessageCountByConversation(
    String conversationId,
  ) async {
    return countResult;
  }

  @override
  Future<bool> validateMessage(MessageToCreate message) async {
    return validateResult;
  }

  @override
  Future<MessageEntity?> getLatestCompactionSummary(String conversationId) {
    throw UnimplementedError();
  }
}

void main() {
  group('MessageRepository', () {
    test('getMessagesByConversation returns list', () async {
      final repo = _StubMessageRepository();
      repo.messagesByConversation = [
        MessageEntity(
          id: 'm-1',
          conversationId: 'c-1',
          content: 'hello',
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      final result = await repo.getMessagesByConversation('c-1');

      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'm-1');
    });

    test('watchMessagesByConversation emits list', () async {
      final repo = _StubMessageRepository();

      final result = await repo.watchMessagesByConversation('c-1').first;

      expect(result, isEmpty);
    });

    test('getMessagesByConversationPaginated returns list', () async {
      final repo = _StubMessageRepository();

      final result = await repo.getMessagesByConversationPaginated(
        'c-1',
        10,
        0,
      );

      expect(result, isEmpty);
    });

    test('getMessagesByType returns filtered list', () async {
      final repo = _StubMessageRepository();

      final result = await repo.getMessagesByType(
        'c-1',
        MessageType.system,
      );

      expect(result, isEmpty);
    });

    test('getUserMessages returns list', () async {
      final repo = _StubMessageRepository();

      final result = await repo.getUserMessages('c-1');

      expect(result, isEmpty);
    });

    test('getSystemMessages returns list', () async {
      final repo = _StubMessageRepository();

      final result = await repo.getSystemMessages('c-1');

      expect(result, isEmpty);
    });

    test('getMessageById returns null when not found', () async {
      final repo = _StubMessageRepository();

      final result = await repo.getMessageById('missing');

      expect(result, isNull);
    });

    test('createMessage returns entity', () async {
      final repo = _StubMessageRepository();
      const toCreate = MessageToCreate(
        conversationId: 'c-1',
        content: 'hi',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
      );

      final result = await repo.createMessage(toCreate);

      expect(result.content, 'hi');
      expect(result.conversationId, 'c-1');
      expect(repo.created, hasLength(1));
    });

    test('patchMessage returns patched entity', () async {
      final repo = _StubMessageRepository();
      const patch = MessagePatch(content: 'updated');

      final result = await repo.patchMessage('m-1', patch);

      expect(result.content, 'updated');
      expect(result.id, 'm-1');
      expect(repo.patched, hasLength(1));
    });

    test('deleteMessage returns bool', () async {
      final repo = _StubMessageRepository();

      expect(await repo.deleteMessage('m-1'), true);

      repo.deleteResult = false;
      expect(await repo.deleteMessage('m-2'), false);
    });

    test('messageExists returns bool', () async {
      final repo = _StubMessageRepository();
      repo.existsResult = true;

      expect(await repo.messageExists('m-1'), true);
    });

    test('getMessagesByStatus returns list', () async {
      final repo = _StubMessageRepository();

      final result = await repo.getMessagesByStatus(
        'c-1',
        MessageStatus.error,
      );

      expect(result, isEmpty);
    });

    test('getMessageCountByConversation returns count', () async {
      final repo = _StubMessageRepository();
      repo.countResult = 42;

      final result = await repo.getMessageCountByConversation('c-1');

      expect(result, 42);
    });

    test('validateMessage returns bool', () async {
      final repo = _StubMessageRepository();
      const toCreate = MessageToCreate(
        conversationId: 'c-1',
        content: 'valid',
        messageType: MessageType.text,
        isUser: true,
        status: MessageStatus.sent,
      );

      expect(await repo.validateMessage(toCreate), true);
    });
  });

  group('MessageException', () {
    test('contains message', () {
      const ex = MessageException('test error');
      expect(ex.message, 'test error');
      expect(ex.cause, isNull);
    });

    test('toString without cause', () {
      const ex = MessageException('oops');
      expect(
        ex.toString(),
        'MessageException: oops',
      );
    });

    test('toString includes cause when provided', () {
      final cause = Exception('inner');
      final ex = MessageException('test', cause);
      expect(ex.toString(), contains('Caused by:'));
    });
  });

  group('MessageValidationException', () {
    test('is a MessageException', () {
      const ex = MessageValidationException('bad');
      expect(ex, isA<MessageException>());
      expect(ex.message, 'bad');
    });
  });

  group('MessageNotFoundException', () {
    test('contains id in message', () {
      const ex = MessageNotFoundException('m-42');
      expect(ex, isA<MessageException>());
      expect(ex.messageId, 'm-42');
      expect(ex.toString(), contains('m-42'));
      expect(ex.toString(), contains('not found'));
    });

    test('includes cause when provided', () {
      final cause = Exception('db error');
      final ex = MessageNotFoundException('m-1', cause);
      expect(ex.cause, cause);
    });
  });
}
