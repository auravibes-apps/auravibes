import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/settings/services/scoped_verification_configuration.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ScopedVerificationConfiguration configuration;
  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    configuration = ScopedVerificationConfiguration(database);
    for (final id in ['local', 'other']) {
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(id: Value(id), name: id, type: .local),
          );
      await database
          .into(database.mcpServers)
          .insert(
            McpServersCompanion.insert(
              id: Value('server-$id'),
              workspaceId: id,
              name: id,
              url: 'http://localhost/mcp',
              transport: const McpTransportTypeStreamableHttp(),
            ),
          );
      await database
          .into(database.toolsGroups)
          .insert(
            ToolsGroupsCompanion.insert(
              id: Value('group-$id'),
              workspaceId: id,
              name: id,
              mcpServerId: Value('server-$id'),
              permissions: .granted,
            ),
          );
      for (final tool in ['runner', 'edit']) {
        await database
            .into(database.tools)
            .insert(
              ToolsCompanion.insert(
                id: Value('$tool-$id'),
                workspaceId: id,
                toolId: tool,
                workspaceToolsGroupId: Value('group-$id'),
                isEnabled: const Value(true),
                permissions: const Value(.granted),
              ),
            );
      }
    }
  });
  tearDown(() => database.close());

  test(
    'lists only this workspace tools and validates exact same-server binding',
    () async {
      expect(
        (await configuration.tools('local')).map((tool) => tool.id),
        containsAll(['runner-local', 'edit-local']),
      );
      expect(await configuration.validate('local', _settings()), isTrue);
      expect(
        await configuration.validate('local', _settings(edit: 'edit-other')),
        isFalse,
      );
      expect(await configuration.validate('other', _settings()), isFalse);
    },
  );

  test(
    'ask permits edit selection but cannot authorize unattended runner probes',
    () async {
      await (database.update(database.tools)
            ..where((row) => row.id.equals('edit-local')))
          .write(const ToolsCompanion(permissions: Value(.ask)));
      expect(await configuration.validate('local', _settings()), isTrue);
      await (database.update(database.tools)
            ..where((row) => row.id.equals('runner-local')))
          .write(const ToolsCompanion(permissions: Value(.ask)));
      expect(await configuration.validate('local', _settings()), isFalse);
    },
  );

  test(
    'denied or disabled tools, groups, and servers remove saved authority',
    () async {
      await (database.update(database.toolsGroups)
            ..where((row) => row.id.equals('group-local')))
          .write(const ToolsGroupsCompanion(permissions: Value(.denied)));
      expect(await configuration.tools('local'), isEmpty);
      expect(await configuration.validate('local', _settings()), isFalse);
      await (database.update(database.toolsGroups)
            ..where((row) => row.id.equals('group-local')))
          .write(const ToolsGroupsCompanion(permissions: Value(.granted)));
      await (database.update(database.mcpServers)
            ..where((row) => row.id.equals('server-local')))
          .write(const McpServersCompanion(isEnabled: Value(false)));
      expect(await configuration.validate('local', _settings()), isFalse);
    },
  );

  test(
    'conversion to a cloud workspace invalidates local configuration',
    () async {
      await (database.update(database.workspaces)
            ..where((row) => row.id.equals('local')))
          .write(const WorkspacesCompanion(type: Value(.remote)));
      expect(await configuration.validate('local', _settings()), isFalse);
    },
  );
}

ScopedVerificationSettings _settings({String edit = 'edit-local'}) =>
    ScopedVerificationSettings(
      enabled: true,
      runnerToolId: 'runner-local',
      mcpServerId: 'server-local',
      workspaceRoot: 'checkout',
      editToolIds: {edit},
      checks: [ScopedVerificationCheck(id: 'analyze', executable: 'dart')],
    );
