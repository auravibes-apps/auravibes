// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/tools_groups_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/database/drift/tables/tools_groups.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'tools_groups_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ToolsGroupsDao>()])
void main() {
  group('ToolsGroupsRepositoryImpl', () {
    late MockToolsGroupsDao mockDao;
    late _TestAppDatabase database;
    late ToolsGroupsRepositoryImpl repository;

    setUp(() {
      mockDao = MockToolsGroupsDao();
      database = _TestAppDatabase(mockDao);
      repository = ToolsGroupsRepositoryImpl(database);
    });

    tearDown(() async {
      await database.close();
    });

    final now = DateTime(2026);

    ToolsGroupsTable createGroupRow({
      String id = 'group-1',
      String workspaceId = 'ws-1',
      String name = 'Test Group',
      bool isEnabled = true,
      PermissionAccess permissions = PermissionAccess.ask,
      String? mcpServerId,
    }) {
      return ToolsGroupsTable(
        id: id,
        createdAt: now,
        updatedAt: now,
        workspaceId: workspaceId,
        mcpServerId: mcpServerId,
        name: name,
        isEnabled: isEnabled,
        permissions: permissions,
      );
    }

    test('getToolsGroupsForWorkspace returns mapped entities', () async {
      final rows = [
        createGroupRow(id: 'g1', name: 'Group 1'),
        createGroupRow(id: 'g2', name: 'Group 2'),
      ];
      when(
        mockDao.getToolsGroupsForWorkspace('ws-1'),
      ).thenAnswer((_) async => rows);

      final result = await repository.getToolsGroupsForWorkspace('ws-1');

      expect(result, hasLength(2));
      expect(result.firstOrNull?.id, 'g1');
      expect(result.firstOrNull?.name, 'Group 1');
      expect(result[1].id, 'g2');
      verify(mockDao.getToolsGroupsForWorkspace('ws-1')).called(1);
    });

    test('getToolsGroupsForWorkspace returns empty list', () async {
      when(
        mockDao.getToolsGroupsForWorkspace('ws-1'),
      ).thenAnswer((_) async => []);

      final result = await repository.getToolsGroupsForWorkspace('ws-1');

      expect(result, isEmpty);
    });

    test('getToolsGroupById returns entity when found', () async {
      final row = createGroupRow(id: 'g1');
      when(mockDao.getToolsGroupById('g1')).thenAnswer((_) async => row);

      final result = await repository.getToolsGroupById('g1');

      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).id, 'g1');
      expect(result.workspaceId, 'ws-1');
      expect(result.isEnabled, true);
      expect(result.permissions, PermissionAccess.ask);
    });

    test('getToolsGroupById returns null when not found', () async {
      when(
        mockDao.getToolsGroupById('nonexistent'),
      ).thenAnswer((_) async => null);

      final result = await repository.getToolsGroupById('nonexistent');

      expect(result, isNull);
    });

    test('getToolsGroupByMcpServerId returns entity when found', () async {
      final row = createGroupRow(id: 'g1', mcpServerId: 'mcp-1');
      when(
        mockDao.getToolsGroupByMcpServerId('mcp-1'),
      ).thenAnswer((_) async => row);

      final result = await repository.getToolsGroupByMcpServerId('mcp-1');

      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).id, 'g1');
      expect(result.mcpServerId, 'mcp-1');
    });

    test('getToolsGroupByMcpServerId returns null when not found', () async {
      when(
        mockDao.getToolsGroupByMcpServerId('nonexistent'),
      ).thenAnswer((_) async => null);

      final result = await repository.getToolsGroupByMcpServerId('nonexistent');

      expect(result, isNull);
    });

    test('setToolsGroupEnabled delegates to dao', () async {
      when(
        mockDao.setToolsGroupEnabled('g1', isEnabled: true),
      ).thenAnswer((_) async => true);

      final result = await repository.setToolsGroupEnabled(
        'g1',
        isEnabled: true,
      );

      expect(result, true);
      verify(mockDao.setToolsGroupEnabled('g1', isEnabled: true)).called(1);
    });

    test('setToolsGroupEnabled returns false when dao fails', () async {
      when(
        mockDao.setToolsGroupEnabled('g1', isEnabled: false),
      ).thenAnswer((_) async => false);

      final result = await repository.setToolsGroupEnabled(
        'g1',
        isEnabled: false,
      );

      expect(result, false);
    });

    test('deleteToolsGroup delegates to dao', () async {
      when(mockDao.deleteToolsGroupById('g1')).thenAnswer((_) async => true);

      final result = await repository.deleteToolsGroup('g1');

      expect(result, true);
      verify(mockDao.deleteToolsGroupById('g1')).called(1);
    });

    test('deleteToolsGroup returns false when not found', () async {
      when(
        mockDao.deleteToolsGroupById('nonexistent'),
      ).thenAnswer((_) async => false);

      final result = await repository.deleteToolsGroup('nonexistent');

      expect(result, false);
    });

    test('maps mcpServerId correctly', () async {
      final row = createGroupRow(id: 'g1', mcpServerId: 'mcp-1');
      when(mockDao.getToolsGroupById('g1')).thenAnswer((_) async => row);

      final result = await repository.getToolsGroupById('g1');

      expect(
        (result ?? fail('Expected result to be non-null')).mcpServerId,
        'mcp-1',
      );
    });

    test('maps null mcpServerId correctly', () async {
      final row = createGroupRow(id: 'g1');
      when(mockDao.getToolsGroupById('g1')).thenAnswer((_) async => row);

      final result = await repository.getToolsGroupById('g1');

      expect(
        (result ?? fail('Expected result to be non-null')).mcpServerId,
        isNull,
      );
    });
  });
}

class _TestAppDatabase extends AppDatabase {
  _TestAppDatabase(this._toolsGroupsDao)
    : super(connection: DatabaseConnection(NativeDatabase.memory()));
  final ToolsGroupsDao _toolsGroupsDao;

  @override
  ToolsGroupsDao get toolsGroupsDao => _toolsGroupsDao;
}
