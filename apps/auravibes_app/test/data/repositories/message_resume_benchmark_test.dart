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
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
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
      final messages = [
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
      ];
      final attachments = [
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
      ];
      await database.transaction(() async {
        await database.batch((batch) {
          batch.insertAll(database.messages, messages);
          batch.insertAll(database.messageAttachments, attachments);
        });
      });

      final repository = MessageRepository(database);
      final readTimer = Stopwatch()..start();
      final hydrated = await repository.getMessagesByConversation(
        conversationId,
      );
      readTimer.stop();
      expect(hydrated, hasLength(messageCount));
      expect(
        hydrated.fold<int>(
          0,
          (total, message) => total + message.attachments.length,
        ),
        attachments.length,
      );

      final firstValue = Completer<List<MessageEntity>>();
      final streamTimer = Stopwatch()..start();
      final subscription = repository
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
      expect(streamed, hasLength(messageCount));
      expect(
        streamed.fold<int>(
          0,
          (total, message) => total + message.attachments.length,
        ),
        attachments.length,
      );
      await subscription.cancel();

      // Model a route change before the new watch finishes its first read.
      var canceledEmissions = 0;
      final pendingSubscription = repository
          .watchMessagesByConversation(conversationId)
          .listen((_) => canceledEmissions++);
      final cancelTimer = Stopwatch()..start();
      await pendingSubscription.cancel();
      cancelTimer.stop();
      expect(canceledEmissions, 0);

      debugPrint(
        'resume baseline messages=$messageCount attachments=${attachments.length} '
        'firstUsefulStreamUs=${streamTimer.elapsedMicroseconds} '
        'fullHydrationUs=${readTimer.elapsedMicroseconds} '
        'cancelUs=${cancelTimer.elapsedMicroseconds}',
      );
    });
  }
}
