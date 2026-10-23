import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/service_connections/usecases/sync_connector_tool_permissions_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new Connector targets stay disabled; sync preserves grants', () async {
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
    final usecase = SyncConnectorToolPermissionsUsecase(database);
    await usecase.call(workspaceId: 'workspace');
    final tool = await database.workspaceToolsDao.getWorkspaceToolByToolId(
      'workspace',
      'connector/brave/web_search',
    );
    expect(tool, isNotNull);
    expect(tool?.isEnabled, false);
    await expectLater(
      usecase.requireEnabledTarget(
        workspaceId: 'workspace',
        toolId: 'connector/brave/web_search',
      ),
      throwsA(isA<AgentToolExecutionFailure>()),
    );
    final _ = await database.workspaceToolsDao.setWorkspaceToolEnabled(
      'workspace',
      'connector/brave/web_search',
      isEnabled: true,
    );
    await usecase.call(workspaceId: 'workspace');
    await usecase.requireEnabledTarget(
      workspaceId: 'workspace',
      toolId: 'connector/brave/web_search',
    );
    expect(
      (await database.workspaceToolsDao.getWorkspaceToolByToolId(
        'workspace',
        'connector/brave/web_search',
      ))?.isEnabled,
      true,
    );
    final _ = await database.workspaceToolsDao.setWorkspaceToolEnabled(
      'workspace',
      'connector/brave/web_search',
      isEnabled: false,
    );
    await usecase.call(workspaceId: 'workspace');
    expect(
      (await database.workspaceToolsDao.getWorkspaceToolByToolId(
        'workspace',
        'connector/brave/web_search',
      ))?.isEnabled,
      false,
    );
  });
}
