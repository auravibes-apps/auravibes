import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/background_work_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'terminalizes interrupted work without replaying completed work',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Background work test', type: .local),
      );
      final conversation = await ConversationRepository(
        database,
      ).createConversation(.new(title: 'Lifecycle', workspaceId: workspace.id));
      final repository = BackgroundWorkRepository(database);
      final _ = await repository.create(
        .new(
          id: 'interrupted-running',
          workspaceId: workspace.id,
          conversationId: conversation.id,
          toolCallId: 'tool-call-running',
          toolKind: 'skill.native',
        ),
      );
      final _ = await repository.create(
        .new(
          id: 'interrupted-stop-requested',
          workspaceId: workspace.id,
          conversationId: conversation.id,
          toolCallId: 'tool-call-stop-requested',
          toolKind: 'skill.native',
        ),
      );
      final _ = await repository.requestStop(
        conversationId: conversation.id,
        workId: 'interrupted-stop-requested',
      );
      final _ = await repository.create(
        .new(
          id: 'already-completed',
          workspaceId: workspace.id,
          conversationId: conversation.id,
          toolCallId: 'tool-call-completed',
          toolKind: 'skill.native',
        ),
      );
      const deliveredResult = 'result already delivered';
      final _ = await repository.finish(
        .new(
          conversationId: conversation.id,
          workId: 'already-completed',
          status: .completed,
          resultContent: deliveredResult,
          resultByteLength: utf8.encode(deliveredResult).length,
          statusPreview: 'Completed',
        ),
      );

      await repository.reconcileInterrupted(
        startedAt: DateTime.now().toUtc().add(const Duration(seconds: 1)),
      );

      final works = await repository.watchConversation(conversation.id).first;
      final worksById = {for (final work in works) work.identity.id: work};
      for (final workId in const [
        'interrupted-running',
        'interrupted-stop-requested',
      ]) {
        final work = worksById[workId]!;
        expect(work.state.status, AgentBackgroundWorkStatus.failed);
        expect(work.state.statusPreview, 'Outcome unknown');
        expect(work.state.resultContent, isNull);
        expect(work.state.resultByteLength, 0);
        expect(work.state.errorCode, 'outcome_unknown');
      }
      expect(
        worksById['already-completed']!.state.status,
        AgentBackgroundWorkStatus.completed,
      );
      expect(
        worksById['already-completed']!.state.resultContent,
        deliveredResult,
      );
      expect(works, hasLength(3));
    },
  );

  test(
    'deleting a conversation removes its persisted completed work output',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Delete work test', type: .local),
      );
      final conversation = await ConversationRepository(database)
          .createConversation(
            .new(title: 'Delete output', workspaceId: workspace.id),
          );
      final repository = BackgroundWorkRepository(database);
      final _ = await repository.create(
        .new(
          id: 'deleted-completed-work',
          workspaceId: workspace.id,
          conversationId: conversation.id,
          toolCallId: 'deleted-tool-call',
          toolKind: 'skill.native',
        ),
      );
      const privateOutput = 'private tool output';
      final _ = await repository.finish(
        .new(
          conversationId: conversation.id,
          workId: 'deleted-completed-work',
          status: .completed,
          resultContent: privateOutput,
          resultByteLength: utf8.encode(privateOutput).length,
          statusPreview: 'Completed',
        ),
      );

      expect(
        (await repository.watchConversation(conversation.id).first)
            .single
            .state
            .resultContent,
        privateOutput,
      );
      expect(
        await ConversationRepository(database)
            .deleteConversation(conversation.id),
        isTrue,
      );
      expect(
        await repository.watchConversation(conversation.id).first,
        isEmpty,
      );
      expect(await database.select(database.messages).get(), isEmpty);
    },
  );
}
