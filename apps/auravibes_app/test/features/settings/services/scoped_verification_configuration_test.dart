import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/settings/services/scoped_verification_configuration.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var database = AppDatabase(connection: NativeDatabase.memory());
  var configuration = ScopedVerificationConfiguration(database);
  setUp(() async {
    await database.close();
    database = AppDatabase(connection: NativeDatabase.memory());
    configuration = ScopedVerificationConfiguration(database);
    for (final id in ['local', 'other']) {
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(id: .new(id), name: id, type: .local),
          );
      final _ = await database
          .into(database.mcpServers)
          .insert(
            McpServersCompanion.insert(
              id: .new('server-$id'),
              workspaceId: id,
              name: id,
              url: 'http://localhost/mcp',
              transport: const McpTransportTypeStreamableHttp(),
            ),
          );
      final _ = await database
          .into(database.toolsGroups)
          .insert(
            ToolsGroupsCompanion.insert(
              id: .new('group-$id'),
              workspaceId: id,
              mcpServerId: .new('server-$id'),
              name: id,
              permissions: .granted,
            ),
          );
      for (final tool in ['runner', 'edit']) {
        final _ = await database
            .into(database.tools)
            .insert(
              ToolsCompanion.insert(
                id: .new('$tool-$id'),
                workspaceId: id,
                workspaceToolsGroupId: .new('group-$id'),
                toolId: tool,
                isEnabled: const .new(true),
                permissions: const .new(.granted),
              ),
            );
      }
    }
  });
  tearDownAll(() => database.close());

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
      final _ =
          await (database.update(database.tools)
                ..where((row) => row.id.equals('edit-local')))
              .write(const ToolsCompanion(permissions: .new(.ask)));
      expect(await configuration.validate('local', _settings()), isTrue);
      final _ =
          await (database.update(database.tools)
                ..where((row) => row.id.equals('runner-local')))
              .write(const ToolsCompanion(permissions: .new(.ask)));
      expect(await configuration.validate('local', _settings()), isFalse);
    },
  );

  test(
    'denied or disabled tools, groups, and servers remove saved authority',
    () async {
      final _ =
          await (database.update(database.toolsGroups)
                ..where((row) => row.id.equals('group-local')))
              .write(const ToolsGroupsCompanion(permissions: .new(.denied)));
      expect(await configuration.tools('local'), isEmpty);
      expect(await configuration.validate('local', _settings()), isFalse);
      final _ =
          await (database.update(database.toolsGroups)
                ..where((row) => row.id.equals('group-local')))
              .write(const ToolsGroupsCompanion(permissions: .new(.granted)));
      final _ =
          await (database.update(database.mcpServers)
                ..where((row) => row.id.equals('server-local')))
              .write(const McpServersCompanion(isEnabled: .new(false)));
      expect(await configuration.validate('local', _settings()), isFalse);
    },
  );

  test(
    'conversion to a cloud workspace invalidates local configuration',
    () async {
      final _ =
          await (database.update(database.workspaces)
                ..where((row) => row.id.equals('local')))
              .write(const WorkspacesCompanion(type: .new(.remote)));
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
