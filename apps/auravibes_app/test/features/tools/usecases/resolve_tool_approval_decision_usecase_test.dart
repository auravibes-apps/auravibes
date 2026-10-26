import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/service_connections/usecases/sync_connector_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ResolveToolApprovalDecisionUsecase', () {
    final fixture = _ResolveToolApprovalDecisionFixture();

    setUp(fixture.setUp);
    for (final mode in agent.ConversationToolAccessMode.values) {
      test('workspace $mode access and structural previews', () async {
        final usecase = ResolveToolApprovalDecisionUsecase(
          conversationToolsRepository: fixture.conversationToolsRepository,
          toolsGroupsRepository: fixture.toolsGroupsRepository,
          workspaceToolsRepository: fixture.workspaceToolsRepository,
          getToolAccessMode: (_) async => mode,
          workspaceAccess: (_, _) async => true,
        );
        for (final action in [
          'read',
          'createRecord',
          'updateRecord',
          'createTable',
          'saveColumn',
          'saveView',
        ]) {
          final result = await usecase.callForRequest((
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'call',
            resolvedTool: ResolvedTool.workspaceCommand(),
            argumentsRaw: jsonEncode({'action': action}),
          ));
          expect(
            result.permissionResult,
            mode == .allowAll ||
                    ['read', 'createRecord', 'updateRecord'].contains(action)
                ? ToolPermissionResult.granted
                : ToolPermissionResult.needsConfirmation,
          );
        }
        final denied = ResolveToolApprovalDecisionUsecase(
          conversationToolsRepository: fixture.conversationToolsRepository,
          toolsGroupsRepository: fixture.toolsGroupsRepository,
          workspaceToolsRepository: fixture.workspaceToolsRepository,
          getToolAccessMode: (_) async => mode,
          workspaceAccess: (_, _) async => false,
        );
        expect(
          (await denied.callForRequest((
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'call',
            resolvedTool: ResolvedTool.workspaceCommand(),
            argumentsRaw: '{"action":"updateRecord"}',
          ))).permissionResult,
          ToolPermissionResult.disabledInWorkspace,
        );
      });
    }

    for (final mode in agent.ConversationToolAccessMode.values) {
      for (final permission in ToolPermissionResult.values) {
        test('mode $mode preserves $permission except final ask', () async {
          final repository = fixture.conversationToolsRepository;
          when(
            () => repository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'calc',
            ),
          ).thenAnswer((_) async => permission);
          final usecase = ResolveToolApprovalDecisionUsecase(
            conversationToolsRepository: repository,
            toolsGroupsRepository: fixture.toolsGroupsRepository,
            workspaceToolsRepository: fixture.workspaceToolsRepository,
            getToolAccessMode: (_) async => mode,
          );
          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: ResolvedTool.builtIn(
              tableId: 'calc',
              toolIdentifier: 'calculator',
              tooltype: .calculator,
            ),
          );
          expect(
            decision.permissionResult,
            mode == agent.ConversationToolAccessMode.allowAll &&
                    permission == ToolPermissionResult.needsConfirmation
                ? ToolPermissionResult.granted
                : permission,
          );
        });
      }
    }

    test(
      'Skill control command without a permission row is unconfigured',
      () async {
        final usecase = ResolveToolApprovalDecisionUsecase(
          conversationToolsRepository: fixture.conversationToolsRepository,
          toolsGroupsRepository: fixture.toolsGroupsRepository,
          workspaceToolsRepository: fixture.workspaceToolsRepository,
          getToolAccessMode: (_) async => .allowAll,
        );
        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: ResolvedTool.skillControl(
            toolIdentifier: agent.activateSkillToolName,
          ),
        );
        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
        final _ = verifyNever(
          () => fixture.conversationToolsRepository.checkToolPermission(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
            toolId: any(named: 'toolId'),
          ),
        );
      },
    );

    test(
      'uses the current Connector command workspace permission row',
      () async {
        final syncPermissions = _MockSyncConnectorToolPermissionsUsecase();
        when(
          () => syncPermissions.permissionTableIdFor(
            workspaceId: 'ws-1',
            toolName: agent.executeConnectorToolName,
          ),
        ).thenAnswer((_) async => 'connector-execute-row');
        when(
          () => fixture.conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'connector-execute-row',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.disabledInWorkspace);
        final usecase = ResolveToolApprovalDecisionUsecase(
          conversationToolsRepository: fixture.conversationToolsRepository,
          toolsGroupsRepository: fixture.toolsGroupsRepository,
          workspaceToolsRepository: fixture.workspaceToolsRepository,
          syncConnectorToolPermissionsUsecase: syncPermissions,
        );

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-connector',
          resolvedTool: ResolvedTool.connectorCommand(
            commandName: agent.executeConnectorToolName,
          ),
        );

        expect(
          decision.permissionResult,
          ToolPermissionResult.disabledInWorkspace,
        );
        verify(
          () => syncPermissions.permissionTableIdFor(
            workspaceId: 'ws-1',
            toolName: agent.executeConnectorToolName,
          ),
        ).called(1);
        verify(
          () => fixture.conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'connector-execute-row',
          ),
        ).called(1);
      },
    );

    for (final mode in agent.ConversationToolAccessMode.values) {
      test('Connector $mode asks in Default and keeps denials', () async {
        final sync = _MockSyncConnectorToolPermissionsUsecase();
        when(
          () => sync.permissionTableIdFor(
            workspaceId: 'ws-1',
            toolName: agent.executeConnectorToolName,
          ),
        ).thenAnswer((_) async => 'execute');
        var permission = ToolPermissionResult.granted;
        when(
          () => fixture.conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'execute',
          ),
        ).thenAnswer((_) async => permission);
        final usecase = ResolveToolApprovalDecisionUsecase(
          conversationToolsRepository: fixture.conversationToolsRepository,
          toolsGroupsRepository: fixture.toolsGroupsRepository,
          workspaceToolsRepository: fixture.workspaceToolsRepository,
          syncConnectorToolPermissionsUsecase: sync,
          getToolAccessMode: (_) async => mode,
        );
        Future<ToolApprovalDecision> decision() => usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'call',
          resolvedTool: ResolvedTool.connectorCommand(
            commandName: agent.executeConnectorToolName,
          ),
        );
        expect(
          (await decision()).permissionResult,
          mode == agent.ConversationToolAccessMode.allowAll
              ? ToolPermissionResult.granted
              : ToolPermissionResult.needsConfirmation,
        );
        final read = await usecase.callForRequest((
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'read',
          resolvedTool: ResolvedTool.connectorCommand(
            commandName: agent.executeConnectorToolName,
          ),
          argumentsRaw:
              '{"toolId":"connector/brave/web_search","args":{"query":"read"}}',
        ));
        expect(read.permissionResult, ToolPermissionResult.granted);
        permission = ToolPermissionResult.disabledInWorkspace;
        expect(
          (await decision()).permissionResult,
          ToolPermissionResult.disabledInWorkspace,
        );
      });
    }

    group('built-in tools', () {
      test('returns granted for always-approved built-in tool', () async {
        final conversationToolsRepository = fixture.conversationToolsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: .calculator,
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
            tooltype: .calculator,
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
          nativeToolType: .url,
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
      test('skill command permissions use stored grants', () async {
        final conversationToolsRepository = fixture.conversationToolsRepository;
        final syncSkillToolPermissionsUsecase =
            MockSyncSkillToolPermissionsUsecase();
        final usecase = ResolveToolApprovalDecisionUsecase(
          conversationToolsRepository: conversationToolsRepository,
          toolsGroupsRepository: fixture.toolsGroupsRepository,
          workspaceToolsRepository: fixture.workspaceToolsRepository,
          syncSkillToolPermissionsUsecase: syncSkillToolPermissionsUsecase,
        );

        for (final toolName in [
          agent.activateSkillToolName,
          agent.loadSkillResourceToolName,
        ]) {
          final permissionId = '$toolName-permission';
          when(
            () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolName: toolName,
            ),
          ).thenAnswer((_) async => permissionId);
          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: permissionId,
            ),
          ).thenAnswer((_) async => ToolPermissionResult.needsConfirmation);

          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: ResolvedTool.skillControl(toolIdentifier: toolName),
          );

          expect(
            decision.permissionResult,
            ToolPermissionResult.needsConfirmation,
          );
          expect(decision.permissionTableId, permissionId);
        }
      });

      test('does not bypass permission lookup for activation', () async {
        final decision = await fixture.usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: ResolvedTool.skillControl(
            toolIdentifier: agent.activateSkillToolName,
          ),
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
        expect(decision.permissionTableId, isNull);
      });

      test(
        'requires approval for run_sub_agent without loading agents',
        () async {
          final syncSkillToolPermissionsUsecase =
              MockSyncSkillToolPermissionsUsecase();
          when(
            () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolName: 'skill__app_native__agents__run_sub_agent',
            ),
          ).thenAnswer((_) async => 'run-sub-agent-permission');
          when(
            () => fixture.conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'run-sub-agent-permission',
            ),
          ).thenAnswer((_) async => ToolPermissionResult.needsConfirmation);
          final usecase = ResolveToolApprovalDecisionUsecase(
            conversationToolsRepository: fixture.conversationToolsRepository,
            toolsGroupsRepository: fixture.toolsGroupsRepository,
            workspaceToolsRepository: fixture.workspaceToolsRepository,
            syncSkillToolPermissionsUsecase: syncSkillToolPermissionsUsecase,
          );

          final decision = await usecase(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolCallId: 'tc-1',
            resolvedTool: ResolvedTool.skillNative(
              tableId: agent.runSubAgentToolName,
              skillSlug: agent.agentsSkillSlug,
              toolIdentifier: agent.runSubAgentToolName,
            ),
          );

          expect(
            decision.permissionResult,
            ToolPermissionResult.needsConfirmation,
          );
          expect(decision.permissionTableId, 'run-sub-agent-permission');
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
            mcp: (
              mcpServerId: 'server-1',
              mcpSlug: 'server-1',
              outputSchemaJson: null,
            ),
          );

          when(
            () => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
          ).thenAnswer(
            (_) async => ToolsGroupEntity(
              id: 'group-1',
              workspaceId: 'ws-1',
              name: 'Group',
              isEnabled: true,
              permissions: .ask,
              createdAt: .new(2026),
              updatedAt: .new(2026),
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
              permissionMode: .alwaysAllow,
              createdAt: .new(2026),
              updatedAt: .new(2026),
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
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'server-1',
            outputSchemaJson: null,
          ),
        );

        when(() => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'))
            .thenAnswer((_) async => null);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
        expect(decision.permissionTableId, isNull);
      });

      test('returns notConfigured when MCP tool group is disabled', () async {
        final toolsGroupsRepository = fixture.toolsGroupsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'server-1',
            outputSchemaJson: null,
          ),
        );

        when(() => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'))
            .thenAnswer(
              (_) async => ToolsGroupEntity(
                id: 'group-1',
                workspaceId: 'ws-1',
                name: 'Group',
                isEnabled: false,
                permissions: .ask,
                createdAt: .new(2026),
                updatedAt: .new(2026),
                mcpServerId: 'server-1',
              ),
            );

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
        expect(decision.permissionTableId, isNull);
        final _ = verifyNever(
          () => fixture.workspaceToolsRepository.getWorkspaceToolByToolName(
            toolGroupId: any(named: 'toolGroupId'),
            toolName: any(named: 'toolName'),
          ),
        );
      });

      test('returns notConfigured when MCP workspace tool not found', () async {
        final toolsGroupsRepository = fixture.toolsGroupsRepository;
        final workspaceToolsRepository = fixture.workspaceToolsRepository;
        final usecase = fixture.usecase;
        final resolvedTool = ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcp: (
            mcpServerId: 'server-1',
            mcpSlug: 'server-1',
            outputSchemaJson: null,
          ),
        );

        when(() => toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'))
            .thenAnswer(
              (_) async => ToolsGroupEntity(
                id: 'group-1',
                workspaceId: 'ws-1',
                name: 'Group',
                isEnabled: true,
                permissions: .ask,
                createdAt: .new(2026),
                updatedAt: .new(2026),
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
          tooltype: .calculator,
        );

        when(
          () => conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.disabledInConversation);

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

class _MockSyncConnectorToolPermissionsUsecase extends Mock
    implements SyncConnectorToolPermissionsUsecase;

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
    _usecase = .new(
      conversationToolsRepository: conversationToolsRepository,
      toolsGroupsRepository: toolsGroupsRepository,
      workspaceToolsRepository: workspaceToolsRepository,
    );
  }
}
