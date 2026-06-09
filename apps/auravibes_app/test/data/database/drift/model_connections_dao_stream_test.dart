import 'package:async/async.dart';
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/service_connections.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('model connections DAO stream emits after create and delete', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await database.workspaceDao.insertWorkspace(
      WorkspacesCompanion.insert(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final stream = StreamQueue(
      database.modelConnectionsDao.watchAllModelConnectionsByWorkspace(
        workspaceIds: [workspace.id],
      ),
    );
    addTearDown(stream.cancel);

    expect(await stream.next, isEmpty);
    final connection = await database.modelConnectionsDao.insertModelConnection(
      ServiceConnectionsCompanion(
        name: const Value('OpenAI'),
        serviceId: const Value('openai'),
        kind: const Value(ServiceConnectionKindTable.modelProvider),
        authenticationType: const Value(
          ServiceAuthenticationTypeTable.apiKey,
        ),
        encryptedAuthValue: const Value('encrypted'),
        workspaceId: Value(workspace.id),
      ),
    );

    expect((await stream.next).map((row) => row.id), [connection.id]);
    await database.modelConnectionsDao.deleteModelConnection(connection.id);
    expect(await stream.next, isEmpty);
  });
}
