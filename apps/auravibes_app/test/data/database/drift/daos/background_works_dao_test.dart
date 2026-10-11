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

final _fixtures = <_BackgroundWorkDaoTestFixture>[];
_BackgroundWorkDaoTestFixture get _fixture => _fixtures.last;
AppDatabase get _database => _fixture.database;
String get _workspaceId => _fixture.workspaceId;
String get _conversationId => _fixture.conversationId;
String get _otherConversationId => _fixture.otherConversationId;

class const _BackgroundWorkDaoTestFixture({
  required final AppDatabase database,
  required final String workspaceId,
  required final String conversationId,
  required final String otherConversationId,
});

void main() {
  setUp(() async {
    final database = AppDatabase(connection: _createTestConnection());
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Background work tests', type: WorkspaceType.local),
    );
    final workspaceId = workspace.id;
    final conversation = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspaceId, title: 'Conversation'),
    );
    final conversationId = conversation.id;
    final otherConversation = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspaceId, title: 'Other conversation'),
    );
    _fixtures.add(
      .new(
        database: database,
        workspaceId: workspaceId,
        conversationId: conversationId,
        otherConversationId: otherConversation.id,
      ),
    );
  });

  tearDown(() async {
    final fixture = _fixtures.removeLast();
    await fixture.database.close();
  });

  test('completion is terminal and scoped to the conversation', () async {
    final created = await _database.backgroundWorksDao.create(
      .new(
        id: 'work-1',
        workspaceId: _workspaceId,
        conversationId: _conversationId,
        toolCallId: 'tool-call-1',
        toolKind: 'native',
      ),
    );
    expect(created.state.status, AgentBackgroundWorkStatus.running);

    final finished = await _database.backgroundWorksDao.finish(
      .new(
        conversationId: _conversationId,
        workId: created.identity.id,
        status: .completed,
        resultContent: 'done',
        resultByteLength: 4,
        statusPreview: 'Completed',
      ),
    );
    expect(finished?.state.status, AgentBackgroundWorkStatus.completed);
    expect(
      await _database.backgroundWorksDao.finish(
        .new(
          conversationId: _conversationId,
          workId: created.identity.id,
          status: .failed,
          resultContent: null,
          resultByteLength: 0,
        ),
      ),
      isNull,
    );
    expect(
      await _database.backgroundWorksDao.find(
        conversationId: _otherConversationId,
        workId: created.identity.id,
      ),
      isNull,
    );
  });

  test('stored previews and results respect UTF-8 byte caps', () async {
    final created = await _database.backgroundWorksDao.create(
      .new(
        id: 'work-4',
        workspaceId: _workspaceId,
        conversationId: _conversationId,
        toolCallId: 'tool-call-4',
        toolKind: 'native',
      ),
    );
    final emoji = String.fromCharCode(0x1f600);
    final result = '${'a' * (AgentBackgroundWorkLimits.resultBytes - 1)}$emoji';
    final preview =
        '${'a' * (AgentBackgroundWorkLimits.statusPreviewBytes - 1)}$emoji';

    final finished = await _database.backgroundWorksDao.finish(
      .new(
        conversationId: _conversationId,
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
