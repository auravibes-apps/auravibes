import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ResolveToolApprovalDecisionUsecase', () {
    final fixture = _ResolveToolApprovalDecisionFixture();

    setUp(fixture.setUp);

    group('built-in tools', () {
      test('returns granted for always-approved built-in tool', () async {
        final conversationToolsRepository = fixture.conversationToolsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );

        when(
          () => conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.toolCallId, 'tc-1');
        expect(decision.permissionResult, ToolPermissionResult.granted);
        expect(decision.permissionTableId, 'calc');
        expect(decision.needsConfirmation, isFalse);
      });

      test(
        'returns needsConfirmation for conversation-ask built-in tool',
        () async {
          final conversationToolsRepository =
              fixture.conversationToolsRepository;
          final usecase = fixture.usecase;
          final resolvedTool = ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          );

          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'calc',
            ),
          ).thenAnswer((_) async => ToolPermissionResult.needsConfirmation);

          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: resolvedTool,
          );

          expect(
            decision.permissionResult,
            ToolPermissionResult.needsConfirmation,
          );
          expect(decision.needsConfirmation, isTrue);
        },
      );
    });

    group('native tools', () {
      test('returns granted for native tool using table id', () async {
        final conversationToolsRepository = fixture.conversationToolsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.native(
          tableId: 'native-1',
          nativeToolType: NativeToolType.url,
        );

        when(
          () => conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'native-1',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.permissionResult, ToolPermissionResult.granted);
        expect(decision.permissionTableId, 'native-1');
      });
    });

    group('skill tools', () {
      test(
        'returns needsConfirmation by default for skill control tool',
        () async {
          final conversationToolsRepository =
              fixture.conversationToolsRepository;
          final syncSkillToolPermissionsUsecase =
              MockSyncSkillToolPermissionsUsecase();
          when(
            () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolName: loadSkillToolName,
            ),
          ).thenAnswer((_) async => 'skill-tool-1');
          final usecase = ResolveToolApprovalDecisionUsecase(
            conversationToolsRepository: conversationToolsRepository,
            toolsGroupsRepository: fixture.toolsGroupsRepository,
            workspaceToolsRepository: fixture.workspaceToolsRepository,
            syncSkillToolPermissionsUsecase: syncSkillToolPermissionsUsecase,
          );

          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'skill-tool-1',
            ),
          ).thenAnswer(
            (_) async => ToolPermissionResult.needsConfirmation,
          );

          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: ResolvedTool.skillControl(
              toolIdentifier: loadSkillToolName,
            ),
          );

          expect(
            decision.permissionResult,
            ToolPermissionResult.needsConfirmation,
          );
          expect(decision.permissionTableId, 'skill-tool-1');
        },
      );

      test(
        'returns granted for conversation-allowed skill template tool',
        () async {
          final conversationToolsRepository =
              fixture.conversationToolsRepository;
          final syncSkillToolPermissionsUsecase =
              MockSyncSkillToolPermissionsUsecase();
          when(
            () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolName: 'skill__user__research__search_web',
            ),
          ).thenAnswer((_) async => 'skill-tool-2');
          final usecase = ResolveToolApprovalDecisionUsecase(
            conversationToolsRepository: conversationToolsRepository,
            toolsGroupsRepository: fixture.toolsGroupsRepository,
            workspaceToolsRepository: fixture.workspaceToolsRepository,
            syncSkillToolPermissionsUsecase: syncSkillToolPermissionsUsecase,
          );

          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'skill-tool-2',
            ),
          ).thenAnswer((_) async => ToolPermissionResult.granted);

          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: ResolvedTool.skillTemplate(
              tableId: 'search_web',
              skillSlug: 'research',
              toolIdentifier: 'search_web',
            ),
          );

          expect(decision.permissionResult, ToolPermissionResult.granted);
          expect(decision.permissionTableId, 'skill-tool-2');
        },
      );
    });

    group('MCP tools', () {
      test(
        'resolves permission table ID via tool group and workspace tool',
        () async {
          final conversationToolsRepository =
              fixture.conversationToolsRepository;
          final toolsGroupsRepository = fixture.toolsGroupsRepository;
          final workspaceToolsRepository = fixture.workspaceToolsRepository;
          final usecase = fixture.usecase;
          final resolvedTool = ResolvedTool.mcp(
            tableId: 'server-1',
            toolIdentifier: 'sum',
            mcpServerId: 'server-1',
          );

          when(
            () => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
          ).thenAnswer(
            (_) async => ToolsGroupEntity(
              id: 'group-1',
              workspaceId: 'ws-1',
              name: 'Group',
              isEnabled: true,
              permissions: PermissionAccess.ask,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              mcpServerId: 'server-1',
            ),
          );
          when(
            () => workspaceToolsRepository.getWorkspaceToolByToolName(
              toolGroupId: 'group-1',
              toolName: 'sum',
            ),
          ).thenAnswer(
            (_) async => WorkspaceToolEntity(
              id: 'workspace-tool-1',
              workspaceId: 'ws-1',
              toolId: 'sum',
              isEnabled: true,
              permissionMode: ToolPermissionMode.alwaysAllow,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              workspaceToolsGroupId: 'group-1',
            ),
          );
          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'workspace-tool-1',
            ),
          ).thenAnswer((_) async => ToolPermissionResult.granted);

          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: resolvedTool,
          );

          expect(decision.permissionResult, ToolPermissionResult.granted);
          expect(decision.permissionTableId, 'workspace-tool-1');
          expect(decision.needsConfirmation, isFalse);
        },
      );

      test('returns notConfigured when MCP tool group not found', () async {
        final toolsGroupsRepository = fixture.toolsGroupsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        );

        when(
          () => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
        ).thenAnswer((_) async => null);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
        expect(decision.permissionTableId, isNull);
      });

      test('returns notConfigured when MCP workspace tool not found', () async {
        final toolsGroupsRepository = fixture.toolsGroupsRepository;
        final workspaceToolsRepository = fixture.workspaceToolsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        );

        when(
          () => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
        ).thenAnswer(
          (_) async => ToolsGroupEntity(
            id: 'group-1',
            workspaceId: 'ws-1',
            name: 'Group',
            isEnabled: true,
            permissions: PermissionAccess.ask,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            mcpServerId: 'server-1',
          ),
        );
        when(
          () => workspaceToolsRepository.getWorkspaceToolByToolName(
            toolGroupId: 'group-1',
            toolName: 'sum',
          ),
        ).thenAnswer((_) async => null);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
      });
    });

    group('disabled tools', () {
      test('returns disabledInConversation', () async {
        final conversationToolsRepository = fixture.conversationToolsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );

        when(
          () => conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'calc',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.disabledInConversation,
        );

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(
          decision.permissionResult,
          ToolPermissionResult.disabledInConversation,
        );
        expect(decision.needsConfirmation, isFalse);
      });
    });
  });
}

class _ResolveToolApprovalDecisionFixture {
  MockConversationToolsRepository? _conversationToolsRepository;
  MockToolsGroupsRepository? _toolsGroupsRepository;
  MockWorkspaceToolsRepository? _workspaceToolsRepository;
  ResolveToolApprovalDecisionUsecase? _usecase;

  MockConversationToolsRepository get conversationToolsRepository =>
      _conversationToolsRepository ??
      fail('Expected conversationToolsRepository to be initialized');

  MockToolsGroupsRepository get toolsGroupsRepository =>
      _toolsGroupsRepository ??
      fail('Expected toolsGroupsRepository to be initialized');

  MockWorkspaceToolsRepository get workspaceToolsRepository =>
      _workspaceToolsRepository ??
      fail('Expected workspaceToolsRepository to be initialized');

  ResolveToolApprovalDecisionUsecase get usecase =>
      _usecase ?? fail('Expected usecase to be initialized');

  void setUp() {
    final conversationToolsRepository = MockConversationToolsRepository();
    final toolsGroupsRepository = MockToolsGroupsRepository();
    final workspaceToolsRepository = MockWorkspaceToolsRepository();

    _conversationToolsRepository = conversationToolsRepository;
    _toolsGroupsRepository = toolsGroupsRepository;
    _workspaceToolsRepository = workspaceToolsRepository;
    _usecase = ResolveToolApprovalDecisionUsecase(
      conversationToolsRepository: conversationToolsRepository,
      toolsGroupsRepository: toolsGroupsRepository,
      workspaceToolsRepository: workspaceToolsRepository,
    );
  }
}
