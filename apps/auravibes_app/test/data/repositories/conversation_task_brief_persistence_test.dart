import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _brief = '  Objetivo \u{1F3AF}\nKeep the deadline.  ';

void main() {
  test('task brief reloads exactly after create and edit', () async {
    final fixture = await _TaskBriefDatabase.open();
    addTearDown(fixture.close);
    final created = await fixture.createConversation(taskBrief: _brief);
    final originalMessages = await fixture.messages();

    await fixture.reopen();
    expect((await fixture.read(created.id))?.taskBrief, _brief);
    const edited =
        '  Decisiones: keep Unicode \u{1F3AF}.\nOpen tasks: review.  ';
    final _ = await fixture.repository.patchConversation(
      created.id,
      const ConversationPatch(taskBrief: edited),
    );
    final _ = await fixture.repository.patchConversation(
      created.id,
      const ConversationPatch(title: 'Renamed conversation'),
    );

    await fixture.reopen();
    final restored = await fixture.read(created.id);
    expect(restored?.taskBrief, edited);
    expect(restored?.title, 'Renamed conversation');
    expect(await fixture.messages(), originalMessages);
  });

  test('cleared task brief stays absent after database reopen', () async {
    final fixture = await _TaskBriefDatabase.open();
    addTearDown(fixture.close);
    final created = await fixture.createConversation(taskBrief: _brief);
    final originalMessages = await fixture.messages();

    final _ = await fixture.repository.patchConversation(
      created.id,
      const ConversationPatch(clearTaskBrief: true),
    );
    await fixture.reopen();

    expect((await fixture.read(created.id))?.taskBrief, isNull);
    expect(await fixture.messages(), originalMessages);
  });

  test(
    'invalid brief patches preserve the saved brief and transcript',
    () async {
      final fixture = await _TaskBriefDatabase.open();
      addTearDown(fixture.close);
      final created = await fixture.createConversation(taskBrief: _brief);
      final originalMessages = await fixture.messages();

      for (final patch in const [
        ConversationPatch(taskBrief: ' \n\t '),
        ConversationPatch(taskBrief: 'new brief', clearTaskBrief: true),
      ]) {
        await expectLater(
          fixture.repository.patchConversation(created.id, patch),
          throwsA(isA<ConversationValidationException>()),
        );
      }
      await fixture.reopen();

      expect((await fixture.read(created.id))?.taskBrief, _brief);
      expect(await fixture.messages(), originalMessages);
    },
  );

  test('fork without a brief remains independent after reopen', () async {
    final fixture = await _TaskBriefDatabase.open();
    addTearDown(fixture.close);
    final source = await fixture.createConversation();
    final fork = await fixture.repository.forkConversation(source.id);
    expect(fork.taskBrief, isNull);
    final _ = await fixture.repository.patchConversation(
      source.id,
      const ConversationPatch(taskBrief: _brief),
    );
    final _ = await fixture.repository.patchConversation(
      fork.id,
      const ConversationPatch(taskBrief: 'Only the fork.'),
    );
    await fixture.reopen();
    expect((await fixture.read(source.id))?.taskBrief, _brief);
    expect((await fixture.read(fork.id))?.taskBrief, 'Only the fork.');

    final _ = await fixture.repository.patchConversation(
      source.id,
      const ConversationPatch(clearTaskBrief: true),
    );
    await fixture.reopen();
    expect((await fixture.read(source.id))?.taskBrief, isNull);
    expect((await fixture.read(fork.id))?.taskBrief, 'Only the fork.');
  });
}

final class _TaskBriefDatabase {
  new(this.directory)
    : database = AppDatabase(
        connection: NativeDatabase(
          .new('${directory.path}/conversation.sqlite'),
        ),
      );

  final Directory directory;
  AppDatabase database;

  ConversationRepository get repository => ConversationRepository(database);

  static Future<_TaskBriefDatabase> open() async => _TaskBriefDatabase(
    await Directory.systemTemp.createTemp('conversation-task-brief-'),
  );

  Future<ConversationEntity?> read(String id) =>
      repository.getConversationById(id);

  Future<ConversationEntity> createConversation({String? taskBrief}) async {
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Task brief workspace', type: .local),
    );
    final conversation = await repository.createConversation(
      .new(
        title: 'Task brief conversation',
        workspaceId: workspace.id,
        taskBrief: taskBrief,
      ),
    );
    final _ = await database.messageDao.insertMessage(
      .insert(
        conversationId: conversation.id,
        content: 'Original transcript message',
        messageType: MessagesTableType.text,
        isUser: true,
        status: MessageTableStatus.sent,
      ),
    );

    return conversation;
  }

  Future<List<Map<String, Object?>>> messages() async => [
    for (final row
        in await database
            .customSelect('SELECT * FROM messages ORDER BY id')
            .get())
      row.data,
  ];

  Future<void> reopen() async {
    await database.close();
    database = .new(
      connection: NativeDatabase(.new('${directory.path}/conversation.sqlite')),
    );
  }

  Future<void> close() async {
    await database.close();
    final _ = await directory.delete(recursive: true);
  }
}
