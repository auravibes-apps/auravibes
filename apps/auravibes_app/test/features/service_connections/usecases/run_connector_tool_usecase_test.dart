import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_connector_write_journal.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/sync_connector_tool_permissions_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared execution honors wrapper and group denial before HTTP',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('workspace'),
              name: 'Workspace',
              type: .local,
            ),
          );
      final permissions = SyncConnectorToolPermissionsUsecase(database);
      await permissions.call(workspaceId: 'workspace');
      final connector = connectorDefinitions.singleWhere(
        (item) => item.identifier == 'duckduckgo',
      );
      final _ = await database.workspaceToolsDao.setWorkspaceToolEnabled(
        'workspace',
        connectorToolId(connector, connector.tools.single),
        isEnabled: true,
      );
      final repository = ServiceConnectionRepository(database, .new(.new()));
      var requests = 0;
      final execute = RunConnectorToolUsecase(
        repository,
        .new(() => repository),
        .new(const ResolveConnectorRequestTemplate(), (_) {
          requests++;

          return .fromFuture(
            .value(
              const .new(
                statusCode: 200,
                body: 'search result',
                headers: {},
                elapsed: .zero,
              ),
            ),
          );
        }),
        null,
        permissions,
        journalForWorkspace: (id) => LocalConnectorWriteJournal(database, id),
      );
      Future<Object?> run() => execute.call((
        workspaceId: 'workspace',
        connectorId: connector.identifier,
        toolSlug: connector.tools.single.slug,
        arguments: {'query': 'example'},
        operationId: 'search-operation',
      ));
      final _ = await run();
      expect(requests, 1);
      final group = await database.toolsGroupsDao.getToolsGroupByName(
        workspaceId: 'workspace',
        name: SyncConnectorToolPermissionsUsecase.groupName,
      );
      final commands = await database.workspaceToolsDao.getToolsByGroupId(
        group?.id ?? '',
      );
      final command = commands.singleWhere(
        (item) => item.toolId == executeConnectorToolName,
      );
      final _ = await database.workspaceToolsDao.setWorkspaceToolPermission(
        command.id,
        permission: .denied,
      );
      await expectLater(run(), throwsA(isA<AgentToolExecutionFailure>()));
      final _ = await database.workspaceToolsDao.setWorkspaceToolPermission(
        command.id,
        permission: .granted,
      );
      final _ = await database.toolsGroupsDao.setToolsGroupEnabled(
        group?.id ?? '',
        isEnabled: false,
      );
      await expectLater(run(), throwsA(isA<AgentToolExecutionFailure>()));
      expect(requests, 1);
    },
  );
}
