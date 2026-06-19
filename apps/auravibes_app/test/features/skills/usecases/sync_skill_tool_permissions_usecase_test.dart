import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBuildDynamicSkillToolSpecsUsecase extends Mock
    implements BuildDynamicSkillToolSpecsUsecase {}

class _MockBuildSkillTemplateToolSpecsUsecase extends Mock
    implements BuildSkillTemplateToolSpecsUsecase {}

class _MockBuildAppSkillNativeToolSpecsUsecase extends Mock
    implements BuildAppSkillNativeToolSpecsUsecase {}

void main() {
  group('SyncSkillToolPermissionsUsecase', () {
    final fixture = _Fixture();

    setUp(() async {
      fixture.database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      final workspace = await fixture.database.workspaceDao.insertWorkspace(
        WorkspacesCompanion.insert(
          name: 'Workspace',
          type: WorkspaceType.local,
        ),
      );
      final dynamicSpecs = _MockBuildDynamicSkillToolSpecsUsecase();
      final templateSpecs = _MockBuildSkillTemplateToolSpecsUsecase();
      final nativeSpecs = _MockBuildAppSkillNativeToolSpecsUsecase();
      fixture
        ..workspaceId = workspace.id
        ..dynamicSpecs = dynamicSpecs
        ..templateSpecs = templateSpecs
        ..nativeSpecs = nativeSpecs
        ..usecase = SyncSkillToolPermissionsUsecase(
          database: fixture.database,
          buildDynamicSkillToolSpecs: dynamicSpecs,
          buildSkillTemplateToolSpecs: templateSpecs,
          buildAppSkillNativeToolSpecs: nativeSpecs,
        );
    });

    tearDown(() async {
      await fixture.database.close();
      fixture.reset();
    });

    void stubSpecs({
      List<ToolSpec> dynamic = const [],
      List<ToolSpec> template = const [],
      List<ToolSpec> native = const [],
    }) {
      when(
        () => fixture.dynamicSpecs.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
        ),
      ).thenAnswer((_) async => dynamic);
      when(
        () => fixture.templateSpecs.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
        ),
      ).thenAnswer((_) async => template);
      when(
        () => fixture.nativeSpecs.call(
          conversationId: any(named: 'conversationId'),
          workspaceId: any(named: 'workspaceId'),
        ),
      ).thenAnswer((_) async => native);
    }

    test('creates skills group and default ask tool rows', () async {
      const spec = ToolSpec(
        name: 'load_skill',
        description: 'Load a skill',
        inputJsonSchema: {'type': 'object'},
      );
      stubSpecs(dynamic: [spec]);

      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );

      final group = await fixture.database.toolsGroupsDao.getToolsGroupByName(
        workspaceId: fixture.workspaceId,
        name: skillToolsGroupName,
      );
      expect(group?.permissions, PermissionAccess.ask);

      final tools = await fixture.database.workspaceToolsDao.getToolsByGroupId(
        group?.id ?? fail('Expected skills group'),
      );
      expect(tools, hasLength(1));
      expect(tools.single.toolId, spec.name);
      expect(tools.single.description, spec.description);
      expect(tools.single.inputSchema, jsonEncode(spec.inputJsonSchema));
      expect(tools.single.isEnabled, isTrue);
      expect(tools.single.permissions, PermissionAccess.ask);
    });

    test('updates metadata and preserves permission settings', () async {
      const initialSpec = ToolSpec(
        name: 'skill__user__example__search',
        description: 'Search records',
        inputJsonSchema: {'type': 'object'},
      );
      stubSpecs(template: [initialSpec]);
      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );
      final group = await fixture.database.toolsGroupsDao.getToolsGroupByName(
        workspaceId: fixture.workspaceId,
        name: skillToolsGroupName,
      );
      final groupId = group?.id ?? fail('Expected skills group');
      final created =
          (await fixture.database.workspaceToolsDao.getToolsByGroupId(
            groupId,
          )).single;
      final _ = await fixture.database.workspaceToolsDao
          .setWorkspaceToolEnabledById(
            created.id,
            isEnabled: false,
          );
      final _ = await fixture.database.workspaceToolsDao
          .setWorkspaceToolPermission(
            created.id,
            permission: PermissionAccess.granted,
          );

      const updatedSpec = ToolSpec(
        name: 'skill__user__example__search',
        description: 'Search updated records',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'},
          },
        },
      );
      stubSpecs(template: [updatedSpec]);

      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );

      final updated =
          (await fixture.database.workspaceToolsDao.getToolsByGroupId(
            groupId,
          )).single;
      expect(updated.description, updatedSpec.description);
      expect(updated.inputSchema, jsonEncode(updatedSpec.inputJsonSchema));
      expect(updated.isEnabled, isFalse);
      expect(updated.permissions, PermissionAccess.granted);
    });

    test('does not update unchanged metadata', () async {
      const spec = ToolSpec(
        name: 'skill__user__example__search',
        description: 'Search records',
        inputJsonSchema: {'type': 'object'},
      );
      stubSpecs(template: [spec]);
      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );
      final group = await fixture.database.toolsGroupsDao.getToolsGroupByName(
        workspaceId: fixture.workspaceId,
        name: skillToolsGroupName,
      );
      final groupId = group?.id ?? fail('Expected skills group');
      final created =
          (await fixture.database.workspaceToolsDao.getToolsByGroupId(
            groupId,
          )).single;

      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );

      final unchanged =
          (await fixture.database.workspaceToolsDao.getToolsByGroupId(
            groupId,
          )).single;
      expect(unchanged.updatedAt, created.updatedAt);
    });

    test('keeps stale skill tool rows', () async {
      const staleSpec = ToolSpec(
        name: 'skill__app__skills_manager__create_user_skill',
        description: 'Create skill',
        inputJsonSchema: {'type': 'object'},
      );
      stubSpecs(native: [staleSpec]);
      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );
      stubSpecs();

      await fixture.usecase.call(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
      );

      final group = await fixture.database.toolsGroupsDao.getToolsGroupByName(
        workspaceId: fixture.workspaceId,
        name: skillToolsGroupName,
      );
      final tools = await fixture.database.workspaceToolsDao.getToolsByGroupId(
        group?.id ?? fail('Expected skills group'),
      );
      expect(tools, hasLength(1));
      expect(tools.single.toolId, staleSpec.name);
    });

    test('permissionTableIdFor returns matching row id', () async {
      const spec = ToolSpec(
        name: 'list_skill_credentials',
        description: 'List credentials',
        inputJsonSchema: {'type': 'object'},
      );
      stubSpecs(dynamic: [spec]);

      final permissionId = await fixture.usecase.permissionTableIdFor(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
        toolName: spec.name,
      );

      final group = await fixture.database.toolsGroupsDao.getToolsGroupByName(
        workspaceId: fixture.workspaceId,
        name: skillToolsGroupName,
      );
      final tool = (await fixture.database.workspaceToolsDao.getToolsByGroupId(
        group?.id ?? fail('Expected skills group'),
      )).single;
      expect(permissionId, tool.id);
    });

    test('permissionTableIdFor returns null for missing tool', () async {
      stubSpecs();

      final permissionId = await fixture.usecase.permissionTableIdFor(
        conversationId: 'conversation-id',
        workspaceId: fixture.workspaceId,
        toolName: 'missing',
      );

      expect(permissionId, isNull);
    });

    test('isSkillPermissionToolName identifies skill permission subjects', () {
      expect(isSkillPermissionToolName('load_skill'), isTrue);
      expect(isSkillPermissionToolName('unload_skill'), isTrue);
      expect(isSkillPermissionToolName('list_skill_credentials'), isTrue);
      expect(isSkillPermissionToolName('skill__user__example__search'), isTrue);
      expect(
        isSkillPermissionToolName(
          'skill__app__skills_manager__list_user_skills',
        ),
        isTrue,
      );
      expect(isSkillPermissionToolName('web_search'), isFalse);
    });
  });
}

class _Fixture {
  AppDatabase? _database;
  String? _workspaceId;
  _MockBuildDynamicSkillToolSpecsUsecase? _dynamicSpecs;
  _MockBuildSkillTemplateToolSpecsUsecase? _templateSpecs;
  _MockBuildAppSkillNativeToolSpecsUsecase? _nativeSpecs;
  SyncSkillToolPermissionsUsecase? _usecase;

  AppDatabase get database =>
      _database ?? fail('Database fixture not initialized');

  set database(AppDatabase value) => _database = value;

  String get workspaceId =>
      _workspaceId ?? fail('Workspace fixture not initialized');

  set workspaceId(String value) => _workspaceId = value;

  _MockBuildDynamicSkillToolSpecsUsecase get dynamicSpecs =>
      _dynamicSpecs ?? fail('Dynamic specs fixture not initialized');

  set dynamicSpecs(_MockBuildDynamicSkillToolSpecsUsecase value) =>
      _dynamicSpecs = value;

  _MockBuildSkillTemplateToolSpecsUsecase get templateSpecs =>
      _templateSpecs ?? fail('Template specs fixture not initialized');

  set templateSpecs(_MockBuildSkillTemplateToolSpecsUsecase value) =>
      _templateSpecs = value;

  _MockBuildAppSkillNativeToolSpecsUsecase get nativeSpecs =>
      _nativeSpecs ?? fail('Native specs fixture not initialized');

  set nativeSpecs(_MockBuildAppSkillNativeToolSpecsUsecase value) =>
      _nativeSpecs = value;

  SyncSkillToolPermissionsUsecase get usecase =>
      _usecase ?? fail('Usecase fixture not initialized');

  set usecase(SyncSkillToolPermissionsUsecase value) => _usecase = value;

  void reset() {
    _database = null;
    _workspaceId = null;
    _dynamicSpecs = null;
    _templateSpecs = null;
    _nativeSpecs = null;
    _usecase = null;
  }
}
