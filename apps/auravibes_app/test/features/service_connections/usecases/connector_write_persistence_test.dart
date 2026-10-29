import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_connector_write_journal.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _tool = ConnectorToolDefinition(
  slug: 'create',
  title: 'Create',
  description: 'Write fixture',
  urlTemplate: .new(
    template: .new(url: 'https://example.com/records', method: .post),
    inputs: {},
  ),
);
const _connector = ConnectorDefinition(
  identifier: 'fixture',
  title: 'Fixture',
  description: 'Deterministic provider',
  tools: [_tool],
);

void main() {
  test(
    'local write receipt survives reopening and blocks a duplicate effect',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'connector-write-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workspace.sqlite');
      AppDatabase open() =>
          AppDatabase(connection: DatabaseConnection(NativeDatabase(file)));
      var database = open();
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('workspace'),
              name: 'Workspace',
              type: .local,
            ),
          );
      var effects = 0;
      final executor = ConnectorToolTemplateExecutor(
        const ResolveConnectorRequestTemplate(),
        (_) {
          effects++;

          return CancelableOperation.fromFuture(
            Future<UrlResponse>.error(TimeoutException('synthetic-secret')),
          );
        },
      );
      Future<Object?> run(String operationId) => ConnectorRequestExecution(
        executor: executor,
        connector: _connector,
        tool: _tool,
        inputs: {},
        credentials: {},
        connectionId: 'connection',
        operationId: operationId,
        journal: LocalConnectorWriteJournal(database, 'workspace'),
      ).call();
      final uncertain = isA<AgentToolExecutionFailure>()
          .having(
            (failure) => failure.resultStatus,
            'status',
            AgentToolResultStatus.uncertain,
          )
          .having(
            (failure) => failure.responseRaw,
            'safe result',
            isNot(contains('synthetic-secret')),
          );
      await expectLater(run('first'), throwsA(uncertain));
      await database.close();
      database = open();
      addTearDown(() => database.close());
      await expectLater(run('retry-with-new-id'), throwsA(uncertain));
      expect(effects, 1);
    },
  );

  test(
    'upgrade keeps workspace rows and creates empty receipt storage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'connector-upgrade-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workspace.sqlite');
      AppDatabase open() =>
          AppDatabase(connection: DatabaseConnection(NativeDatabase(file)));
      var database = open();
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('workspace'),
              name: 'Existing workspace',
              type: .local,
            ),
          );
      await database.customStatement('DROP TABLE connector_writes');
      await database.customStatement('PRAGMA user_version = 35');
      await database.close();
      database = open();
      addTearDown(() => database.close());
      final workspace = await database.workspaceDao.getWorkspaceById(
        'workspace',
      );
      expect(workspace?.name, 'Existing workspace');
      final result = await ConnectorRequestExecution(
        executor: .new(
          const ResolveConnectorRequestTemplate(),
          (_) => CancelableOperation.fromFuture(
            .value(
              const UrlResponse(
                statusCode: 201,
                body: 'created after upgrade',
                headers: {},
                elapsed: .zero,
              ),
            ),
          ),
        ),
        connector: _connector,
        tool: _tool,
        inputs: {},
        credentials: {},
        connectionId: 'connection',
        operationId: 'after-upgrade',
        journal: LocalConnectorWriteJournal(database, 'workspace'),
      ).call();
      expect(result, containsPair('outcome', 'completed'));
    },
  );

  test(
    'reopened completed receipt preserves HTTP result and does not resend',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'connector-completed-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workspace.sqlite');
      AppDatabase open() =>
          AppDatabase(connection: DatabaseConnection(NativeDatabase(file)));
      var database = open();
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('workspace'),
              name: 'Workspace',
              type: .local,
            ),
          );
      var effects = 0;
      final executor = ConnectorToolTemplateExecutor(
        const ResolveConnectorRequestTemplate(),
        (_) {
          effects++;

          return CancelableOperation.fromFuture(
            .value(
              const UrlResponse(
                statusCode: 201,
                body: 'provider response',
                headers: {},
                elapsed: .zero,
              ),
            ),
          );
        },
      );
      Future<Object?> run() => ConnectorRequestExecution(
        executor: executor,
        connector: _connector,
        tool: _tool,
        inputs: {},
        credentials: {},
        connectionId: 'connection',
        operationId: 'create',
        journal: LocalConnectorWriteJournal(database, 'workspace'),
      ).call();
      expect(await run(), containsPair('response', 'provider response'));
      await database.close();
      database = open();
      addTearDown(() => database.close());
      expect(
        await run(),
        allOf(
          containsPair('outcome', 'completed'),
          containsPair('statusCode', 201),
          containsPair('replayed', true),
        ),
      );
      expect(effects, 1);
    },
  );
}
