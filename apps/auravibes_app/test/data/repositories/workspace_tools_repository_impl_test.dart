// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_dao.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/tools.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'workspace_tools_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WorkspaceToolsDao>(), MockSpec<WorkspaceDao>()])
void main() {
  group('WorkspaceToolsRepositoryImpl', () {
    late MockWorkspaceToolsDao mockToolsDao;
    late MockWorkspaceDao mockWorkspaceDao;
    late _TestAppDatabase database;
    late WorkspaceToolsRepositoryImpl repository;

    setUp(() {
      mockToolsDao = MockWorkspaceToolsDao();
      mockWorkspaceDao = MockWorkspaceDao();
      database = _TestAppDatabase(mockToolsDao, mockWorkspaceDao);
      repository = WorkspaceToolsRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    final now = DateTime(2026);

    ToolsTable createToolRow({
      String id = 'tool-1',
      String workspaceId = 'ws-1',
      String toolId = 'calculator',
      bool isEnabled = true,
      PermissionAccess permissions = PermissionAccess.ask,
      String? config,
      String? description,
      String? inputSchema,
      String? workspaceToolsGroupId,
    }) {
      return ToolsTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        workspaceToolsGroupId: workspaceToolsGroupId,
        toolId: toolId,
        description: description,
        config: config,
        inputSchema: inputSchema,
        isEnabled: isEnabled,
        permissions: permissions,
      );
    }

    group('getWorkspaceTools', () {
      test('returns mapped entities after ensuring native tools', () async {
        when(mockToolsDao.getWorkspaceTools('ws-1')).thenAnswer(
          (_) async => [
            createToolRow(id: 't1', toolId: 'url'),
            createToolRow(id: 't2'),
          ],
        );

        final result = await repository.getWorkspaceTools('ws-1');

        expect(result, hasLength(2));
        expect(result.firstOrNull?.id, 't1');
        expect(result.firstOrNull?.toolId, 'url');
        expect(result[1].toolId, 'calculator');
      });
    });

    group('getEnabledWorkspaceTools', () {
      test('returns only enabled tools', () async {
        when(mockToolsDao.getEnabledWorkspaceTools('ws-1')).thenAnswer(
          (_) async => [
            createToolRow(id: 't1', toolId: 'url'),
          ],
        );

        final result = await repository.getEnabledWorkspaceTools('ws-1');

        expect(result, hasLength(1));
        expect(result.firstOrNull?.isEnabled, true);
      });
    });

    group('getWorkspaceTool', () {
      test('returns entity when found', () async {
        when(
          mockToolsDao.getWorkspaceToolByToolId('ws-1', 'calculator'),
        ).thenAnswer((_) async => createToolRow());

        final result = await repository.getWorkspaceTool('ws-1', 'calculator');

        expect(result, isNotNull);
        expect(result!.toolId, 'calculator');
      });

      test('returns null when not found', () async {
        when(
          mockToolsDao.getWorkspaceToolByToolId('ws-1', 'unknown'),
        ).thenAnswer((_) async => null);

        final result = await repository.getWorkspaceTool('ws-1', 'unknown');

        expect(result, isNull);
      });
    });

    group('setWorkspaceToolEnabled', () {
      test('enables tool and returns entity', () async {
        final updatedRow = createToolRow();
        when(
          mockToolsDao.setWorkspaceToolEnabled(
            'ws-1',
            'calculator',
            isEnabled: true,
          ),
        ).thenAnswer((_) async => updatedRow);

        final result = await repository.setWorkspaceToolEnabled(
          'ws-1',
          'calculator',
          isEnabled: true,
        );

        expect(result.isEnabled, true);
      });

      test('disables tool and returns entity', () async {
        final updatedRow = createToolRow(isEnabled: false);
        when(
          mockToolsDao.setWorkspaceToolEnabled(
            'ws-1',
            'calculator',
            isEnabled: false,
          ),
        ).thenAnswer((_) async => updatedRow);

        final result = await repository.setWorkspaceToolEnabled(
          'ws-1',
          'calculator',
          isEnabled: false,
        );

        expect(result.isEnabled, false);
      });
    });

    group('setToolEnabledById', () {
      test('updates tool by ID', () async {
        final updatedRow = createToolRow();
        when(
          mockToolsDao.setWorkspaceToolEnabledById(
            'tool-1',
            isEnabled: true,
          ),
        ).thenAnswer((_) async => updatedRow);

        final result = await repository.setToolEnabledById(
          'tool-1',
          isEnabled: true,
        );

        expect(result.id, 'tool-1');
        expect(result.isEnabled, true);
      });
    });

    group('isWorkspaceToolEnabled', () {
      test('returns true when enabled', () async {
        when(
          mockToolsDao.isWorkspaceToolEnabledByToolId('ws-1', 'calculator'),
        ).thenAnswer((_) async => true);

        final result = await repository.isWorkspaceToolEnabled(
          'ws-1',
          'calculator',
        );

        expect(result, true);
      });

      test('returns false when disabled', () async {
        when(
          mockToolsDao.isWorkspaceToolEnabledByToolId('ws-1', 'calculator'),
        ).thenAnswer((_) async => false);

        final result = await repository.isWorkspaceToolEnabled(
          'ws-1',
          'calculator',
        );

        expect(result, false);
      });
    });

    group('removeWorkspaceTool', () {
      test('removes non-native tool', () async {
        when(
          mockToolsDao.deleteWorkspaceToolByToolId('ws-1', 'custom_tool'),
        ).thenAnswer((_) async => true);

        final result = await repository.removeWorkspaceTool(
          'ws-1',
          'custom_tool',
        );

        expect(result, true);
      });

      test('throws for native tool', () async {
        await expectLater(
          repository.removeWorkspaceTool('ws-1', 'url'),
          throwsA(isA<WorkspaceToolsValidationException>()),
        );
      });
    });

    group('removeWorkspaceToolById', () {
      test('delegates to dao', () async {
        when(
          mockToolsDao.deleteWorkspaceToolById('tool-1'),
        ).thenAnswer((_) async => true);

        final result = await repository.removeWorkspaceToolById('tool-1');

        expect(result, true);
        verify(mockToolsDao.deleteWorkspaceToolById('tool-1')).called(1);
      });
    });

    group('getWorkspaceToolsCount', () {
      test('returns count from dao', () async {
        when(
          mockToolsDao.getWorkspaceToolsCount('ws-1'),
        ).thenAnswer((_) async => 5);

        final result = await repository.getWorkspaceToolsCount('ws-1');

        expect(result, 5);
      });
    });

    group('getEnabledWorkspaceToolsCount', () {
      test('returns enabled count from dao', () async {
        when(
          mockToolsDao.getEnabledWorkspaceToolsCount('ws-1'),
        ).thenAnswer((_) async => 3);

        final result = await repository.getEnabledWorkspaceToolsCount('ws-1');

        expect(result, 3);
      });
    });

    group('copyWorkspaceToolsToConversation', () {
      test('completes without error', () async {
        await repository.copyWorkspaceToolsToConversation('ws-1', 'conv-1');

        expect(true, true);
      });
    });

    group('validateWorkspaceToolSetting', () {
      test('returns true for valid workspace and tool', () async {
        when(mockWorkspaceDao.getWorkspaceById('ws-1')).thenAnswer(
          (_) async => WorkspacesTable(
            id: 'ws-1',
            createdAt: now,
            updatedAt: now,
            name: 'Test',
            type: WorkspaceType.local,
          ),
        );

        final result = await repository.validateWorkspaceToolSetting(
          'ws-1',
          'calculator',
          isEnabled: true,
        );

        expect(result, true);
      });

      test('throws when workspace not found', () async {
        when(
          mockWorkspaceDao.getWorkspaceById('nonexistent'),
        ).thenAnswer((_) async => null);

        await expectLater(
          repository.validateWorkspaceToolSetting(
            'nonexistent',
            'calculator',
            isEnabled: true,
          ),
          throwsA(isA<WorkspaceToolsValidationException>()),
        );
      });

      test('throws for invalid tool type', () async {
        when(mockWorkspaceDao.getWorkspaceById('ws-1')).thenAnswer(
          (_) async => WorkspacesTable(
            id: 'ws-1',
            createdAt: now,
            updatedAt: now,
            name: 'Test',
            type: WorkspaceType.local,
          ),
        );

        await expectLater(
          repository.validateWorkspaceToolSetting(
            'ws-1',
            'totally_invalid_tool_type_xyz',
            isEnabled: true,
          ),
          throwsA(isA<WorkspaceToolsValidationException>()),
        );
      });
    });

    group('getWorkspaceToolConfig', () {
      test('returns config string', () async {
        when(
          mockToolsDao.getWorkspaceToolConfigByToolId('ws-1', 'calculator'),
        ).thenAnswer((_) async => '{"key": "value"}');

        final result = await repository.getWorkspaceToolConfig(
          'ws-1',
          'calculator',
        );

        expect(result, '{"key": "value"}');
      });

      test('returns null when no config', () async {
        when(
          mockToolsDao.getWorkspaceToolConfigByToolId('ws-1', 'calculator'),
        ).thenAnswer((_) async => null);

        final result = await repository.getWorkspaceToolConfig(
          'ws-1',
          'calculator',
        );

        expect(result, isNull);
      });
    });

    group('patchWorkspaceToolConfig', () {
      test('returns patched entities', () async {
        when(
          mockToolsDao.patchWorkspaceToolConfig(
            'ws-1',
            'calculator',
            '{"new": "config"}',
          ),
        ).thenAnswer(
          (_) async => [
            createToolRow(config: '{"new": "config"}'),
          ],
        );

        final result = await repository.patchWorkspaceToolConfig(
          'ws-1',
          'calculator',
          '{"new": "config"}',
        );

        expect(result, hasLength(1));
        expect(result.firstOrNull?.config, '{"new": "config"}');
      });

      test('throws WorkspaceToolsException on dao error', () async {
        when(
          mockToolsDao.patchWorkspaceToolConfig(any, any, any),
        ).thenThrow(Exception('DB error'));

        await expectLater(
          repository.patchWorkspaceToolConfig('ws-1', 'tool', 'config'),
          throwsA(isA<WorkspaceToolsException>()),
        );
      });
    });

    group('setToolPermissionMode', () {
      test('sets alwaysAsk permission', () async {
        final updatedRow = createToolRow();
        when(
          mockToolsDao.setWorkspaceToolPermission(
            'tool-1',
            permission: PermissionAccess.ask,
          ),
        ).thenAnswer((_) async => updatedRow);

        final result = await repository.setToolPermissionMode(
          'tool-1',
          permissionMode: ToolPermissionMode.alwaysAsk,
        );

        expect(result.permissionMode, ToolPermissionMode.alwaysAsk);
      });

      test('sets alwaysAllow permission', () async {
        final updatedRow = createToolRow(permissions: PermissionAccess.granted);
        when(
          mockToolsDao.setWorkspaceToolPermission(
            'tool-1',
            permission: PermissionAccess.granted,
          ),
        ).thenAnswer((_) async => updatedRow);

        final result = await repository.setToolPermissionMode(
          'tool-1',
          permissionMode: ToolPermissionMode.alwaysAllow,
        );

        expect(result.permissionMode, ToolPermissionMode.alwaysAllow);
      });
    });

    group('getWorkspaceToolByToolName', () {
      test('returns entity when found', () async {
        when(
          mockToolsDao.getEnabledToolByToolName(
            toolGroupId: 'group-1',
            toolName: 'my_tool',
          ),
        ).thenAnswer(
          (_) async => createToolRow(
            toolId: 'my_tool',
            workspaceToolsGroupId: 'group-1',
          ),
        );

        final result = await repository.getWorkspaceToolByToolName(
          toolGroupId: 'group-1',
          toolName: 'my_tool',
        );

        expect(result, isNotNull);
        expect(result!.toolId, 'my_tool');
      });

      test('returns null when not found', () async {
        when(
          mockToolsDao.getEnabledToolByToolName(
            toolGroupId: 'group-1',
            toolName: 'unknown',
          ),
        ).thenAnswer((_) async => null);

        final result = await repository.getWorkspaceToolByToolName(
          toolGroupId: 'group-1',
          toolName: 'unknown',
        );

        expect(result, isNull);
      });
    });

    group('permission mapping', () {
      test(
        'maps PermissionAccess.ask to ToolPermissionMode.alwaysAsk',
        () async {
          final row = createToolRow();
          when(
            mockToolsDao.getWorkspaceToolByToolId('ws-1', 'tool'),
          ).thenAnswer((_) async => row);

          final result = await repository.getWorkspaceTool('ws-1', 'tool');

          expect(result!.permissionMode, ToolPermissionMode.alwaysAsk);
        },
      );

      test(
        'maps PermissionAccess.granted to ToolPermissionMode.alwaysAllow',
        () async {
          final row = createToolRow(permissions: PermissionAccess.granted);
          when(
            mockToolsDao.getWorkspaceToolByToolId('ws-1', 'tool'),
          ).thenAnswer((_) async => row);

          final result = await repository.getWorkspaceTool('ws-1', 'tool');

          expect(result!.permissionMode, ToolPermissionMode.alwaysAllow);
        },
      );
    });
  });
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(this._toolsDao, this._workspaceDao)
    : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final WorkspaceToolsDao _toolsDao;
  final WorkspaceDao _workspaceDao;

  @override
  WorkspaceToolsDao get workspaceToolsDao => _toolsDao;

  @override
  WorkspaceDao get workspaceDao => _workspaceDao;
}
