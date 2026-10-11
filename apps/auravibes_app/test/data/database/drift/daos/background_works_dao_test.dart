import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor _createTestConnection() => DatabaseConnection.delayed(
  Future(() {
    return DatabaseConnection(
      LazyDatabase(() async => NativeDatabase.memory()),
    );
  }),
);

typedef _BackgroundWorkDaoFixture = ({
  AppDatabase database,
  String workspaceId,
  String conversationId,
  String otherConversationId,
});

Future<_BackgroundWorkDaoFixture> _createFixture() async {
  final database = AppDatabase(connection: _createTestConnection());
  final workspace = await database.workspaceDao.insertWorkspace(
    .insert(name: 'Background work tests', type: WorkspaceType.local),
  );
  final conversation = await database.conversationDao.insertConversation(
    .insert(workspaceId: workspace.id, title: 'Conversation'),
  );
  final otherConversation = await database.conversationDao.insertConversation(
    .insert(workspaceId: workspace.id, title: 'Other conversation'),
  );

  return (
    database: database,
    workspaceId: workspace.id,
    conversationId: conversation.id,
    otherConversationId: otherConversation.id,
  );
}

void main() {
  test('completion is terminal and scoped to the conversation', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final database = fixture.database;
    final workspaceId = fixture.workspaceId;
    final conversationId = fixture.conversationId;
    final otherConversationId = fixture.otherConversationId;
    final created = await database.backgroundWorksDao.create(
      .new(
        id: 'work-1',
        workspaceId: workspaceId,
        conversationId: conversationId,
        toolCallId: 'tool-call-1',
        toolKind: 'native',
      ),
    );
    expect(created.state.status, AgentBackgroundWorkStatus.running);

    final finished = await database.backgroundWorksDao.finish(
      .new(
        conversationId: conversationId,
        workId: created.identity.id,
        status: .completed,
        resultContent: 'done',
        resultByteLength: 4,
        statusPreview: 'Completed',
      ),
    );
    expect(finished?.state.status, AgentBackgroundWorkStatus.completed);
    expect(
      await database.backgroundWorksDao.finish(
        .new(
          conversationId: conversationId,
          workId: created.identity.id,
          status: .failed,
          resultContent: null,
          resultByteLength: 0,
        ),
      ),
      isNull,
    );
    expect(
      await database.backgroundWorksDao.find(
        conversationId: otherConversationId,
        workId: created.identity.id,
      ),
      isNull,
    );
  });

  test('stored previews and results respect UTF-8 byte caps', () async {
    final fixture = await _createFixture();
    addTearDown(fixture.database.close);
    final database = fixture.database;
    final workspaceId = fixture.workspaceId;
    final conversationId = fixture.conversationId;
    final created = await database.backgroundWorksDao.create(
      .new(
        id: 'work-4',
        workspaceId: workspaceId,
        conversationId: conversationId,
        toolCallId: 'tool-call-4',
        toolKind: 'native',
      ),
    );
    final supplementaryCharacter = String.fromCharCode(0x1f600);
    final resultPrefix = 'a' * (AgentBackgroundWorkLimits.resultBytes - 1);
    final previewPrefix =
        'a' * (AgentBackgroundWorkLimits.statusPreviewBytes - 1);
    final result = '$resultPrefix$supplementaryCharacter';
    final preview = '$previewPrefix$supplementaryCharacter';

    final finished = await database.backgroundWorksDao.finish(
      .new(
        conversationId: conversationId,
        workId: created.identity.id,
        status: .completed,
        resultContent: result,
        resultByteLength: utf8.encode(result).length,
        statusPreview: preview,
      ),
    );

    final storedResult = finished?.state.resultContent;
    final storedPreview = finished?.state.statusPreview;
    expect(
      utf8.encode(storedResult ?? '').length,
      lessThanOrEqualTo(AgentBackgroundWorkLimits.resultBytes),
    );
    expect(
      utf8.encode(storedPreview ?? '').length,
      lessThanOrEqualTo(AgentBackgroundWorkLimits.statusPreviewBytes),
    );
    expect(storedResult, 'a' * (AgentBackgroundWorkLimits.resultBytes - 1));
    expect(
      storedPreview,
      'a' * (AgentBackgroundWorkLimits.statusPreviewBytes - 1),
    );
  });
}
