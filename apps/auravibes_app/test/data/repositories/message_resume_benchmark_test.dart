import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final messageCount in [40, 2000]) {
    test('resume baseline: $messageCount messages', () async {
      final conversationId = 'resume-$messageCount';
      final attachmentCount = messageCount ~/ 4;
      final streamDatabase = await _seedDatabase(messageCount);
      addTearDown(streamDatabase.close);
      final streamRepository = MessageRepository(streamDatabase);
      final firstValue = Completer<List<MessageEntity>>();
      final streamTimer = Stopwatch()..start();
      final subscription = streamRepository
          .watchMessagesByConversation(conversationId)
          .listen((value) {
            if (!firstValue.isCompleted && value.isNotEmpty) {
              streamTimer.stop();
              firstValue.complete(value);
            }
          }, onError: firstValue.completeError);
      addTearDown(subscription.cancel);
      final streamed = await firstValue.future.timeout(
        const Duration(seconds: 30),
      );
      _expectRows(streamed, messageCount, attachmentCount);
      await subscription.cancel();
      await streamDatabase.close();

      final readDatabase = await _seedDatabase(messageCount);
      addTearDown(readDatabase.close);
      final readRepository = MessageRepository(readDatabase);
      final readTimer = Stopwatch()..start();
      final hydrated = await readRepository.getMessagesByConversation(
        conversationId,
      );
      readTimer.stop();
      _expectRows(hydrated, messageCount, attachmentCount);
      await readDatabase.close();

      final gate = _AttachmentQueryGate();
      addTearDown(gate.release);
      final cancelDatabase = await _seedDatabase(
        messageCount,
        interceptor: gate,
      );
      addTearDown(cancelDatabase.close);
      final cancelRepository = MessageRepository(cancelDatabase);
      gate.armed = true;
      var canceledEmissions = 0;
      final pendingSubscription = cancelRepository
          .watchMessagesByConversation(conversationId)
          .listen((_) => canceledEmissions++);
      addTearDown(pendingSubscription.cancel);
      await gate.started.future.timeout(const Duration(seconds: 30));
      final cancelTimer = Stopwatch()..start();
      await pendingSubscription.cancel();
      cancelTimer.stop();
      expect(canceledEmissions, 0);
      expect(gate.completed.isCompleted, isFalse);
      final continuedTimer = Stopwatch()..start();
      gate.release();
      await gate.completed.future.timeout(const Duration(seconds: 30));
      continuedTimer.stop();
      expect(canceledEmissions, 0);
      await cancelDatabase.close();

      debugPrint(
        'resume baseline messages=$messageCount attachments=$attachmentCount '
        'firstUsefulStreamUs=${streamTimer.elapsedMicroseconds} '
        'fullHydrationUs=${readTimer.elapsedMicroseconds} '
        'cancelPendingWatchUs=${cancelTimer.elapsedMicroseconds} '
        'attachmentQueryAfterCancelUs=${continuedTimer.elapsedMicroseconds}',
      );
    });
  }
}

void _expectRows(
  List<MessageEntity> rows,
  int messageCount,
  int attachmentCount,
) {
  expect(rows, hasLength(messageCount));
  expect(
    rows.fold<int>(0, (total, message) => total + message.attachments.length),
    attachmentCount,
  );
}

Future<AppDatabase> _seedDatabase(
  int messageCount, {
  QueryInterceptor? interceptor,
}) async {
  final connection = DatabaseConnection(NativeDatabase.memory());
  final database = AppDatabase(
    connection: interceptor == null
        ? connection
        : connection.interceptWith(interceptor),
  );
  final workspace = await database.workspaceDao.insertWorkspace(
    .insert(name: 'Benchmark Workspace', type: .local),
  );
  final conversationId = 'resume-$messageCount';
  final _ = await database.conversationDao.insertConversation(
    .insert(
      id: Value(conversationId),
      workspaceId: workspace.id,
      title: 'Resume benchmark',
    ),
  );
  final createdAt = DateTime.utc(2026);
  await database.transaction(() async {
    await database.batch((batch) {
      batch.insertAll(database.messages, [
        for (var index = 0; index < messageCount; index++)
          MessagesCompanion.insert(
            id: Value('message-$index'),
            createdAt: Value(createdAt.add(Duration(seconds: index))),
            conversationId: conversationId,
            content: 'Message $index ${'content ' * 32}',
            messageType: .text,
            isUser: index.isEven,
            status: .sent,
          ),
      ]);
      batch.insertAll(database.messageAttachments, [
        for (var index = 0; index < messageCount; index += 4)
          MessageAttachmentsCompanion.insert(
            id: Value('attachment-$index'),
            messageId: 'message-$index',
            localPath: '/benchmark/image-$index.png',
            fileName: 'image-$index.png',
            displayName: Value('image-$index.png'),
            mimeType: 'image/png',
            modality: 'image',
            sizeBytes: 1024,
          ),
      ]);
    });
  });
  return database;
}

class _AttachmentQueryGate extends QueryInterceptor {
  final started = Completer<void>();
  final completed = Completer<void>();
  final _resume = Completer<void>();
  bool armed = false;

  void release() {
    if (!_resume.isCompleted) _resume.complete();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (!armed ||
        started.isCompleted ||
        !statement.contains('message_attachments') ||
        !statement.contains(' IN ')) {
      return executor.runSelect(statement, args);
    }
    started.complete();
    await _resume.future;
    final rows = await executor.runSelect(statement, args);
    completed.complete();
    return rows;
  }
}
