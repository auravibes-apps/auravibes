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

void main() {
  late AppDatabase database;
  late String workspaceId;
  late String conversationId;
  late String otherConversationId;

  setUp(() async {
    database = AppDatabase(connection: _createTestConnection());
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Background work tests', type: WorkspaceType.local),
    );
    workspaceId = workspace.id;
    final conversation = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspaceId, title: 'Conversation'),
    );
    conversationId = conversation.id;
    final otherConversation = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspaceId, title: 'Other conversation'),
    );
    otherConversationId = otherConversation.id;
  });

  tearDown(() => database.close());

  test('completion is terminal and scoped to the conversation', () async {
    final created = await database.backgroundWorksDao.create(
      AgentBackgroundWorkCreateRequest(
        id: 'work-1',
        workspaceId: workspaceId,
        conversationId: conversationId,
        toolCallId: 'tool-call-1',
        toolKind: 'native',
      ),
    );
    expect(created.state.status, AgentBackgroundWorkStatus.running);

    final finished = await database.backgroundWorksDao.finish(
      AgentBackgroundWorkCompletion(
        conversationId: conversationId,
        workId: created.identity.id,
        status: AgentBackgroundWorkStatus.completed,
        resultContent: 'done',
        resultByteLength: 4,
        statusPreview: 'Completed',
      ),
    );
    expect(finished?.state.status, AgentBackgroundWorkStatus.completed);
    expect(
      await database.backgroundWorksDao.finish(
        AgentBackgroundWorkCompletion(
          conversationId: conversationId,
          workId: created.identity.id,
          status: AgentBackgroundWorkStatus.failed,
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
    final created = await database.backgroundWorksDao.create(
      AgentBackgroundWorkCreateRequest(
        id: 'work-4',
        workspaceId: workspaceId,
        conversationId: conversationId,
        toolCallId: 'tool-call-4',
        toolKind: 'native',
      ),
    );
    final result = '${'a' * (AgentBackgroundWorkLimits.resultBytes - 1)}😀';
    final preview =
        '${'a' * (AgentBackgroundWorkLimits.statusPreviewBytes - 1)}😀';

    final finished = await database.backgroundWorksDao.finish(
      AgentBackgroundWorkCompletion(
        conversationId: conversationId,
        workId: created.identity.id,
        status: AgentBackgroundWorkStatus.completed,
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
