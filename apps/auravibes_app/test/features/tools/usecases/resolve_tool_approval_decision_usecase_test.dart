import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/features/tools/usecases/tool_approval_decision.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
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
        'load and unload use stored permissions as skill commands',
        () async {
          final conversationToolsRepository =
              fixture.conversationToolsRepository;
          final syncSkillToolPermissionsUsecase =
              MockSyncSkillToolPermissionsUsecase();
          final usecase = ResolveToolApprovalDecisionUsecase(
            conversationToolsRepository: conversationToolsRepository,
            toolsGroupsRepository: fixture.toolsGroupsRepository,
            workspaceToolsRepository: fixture.workspaceToolsRepository,
            syncSkillToolPermissionsUsecase: syncSkillToolPermissionsUsecase,
          );

          for (final toolName in [
            agent.loadSkillToolName,
            agent.unloadSkillToolName,
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
            ).thenAnswer(
              (_) async => ToolPermissionResult.needsConfirmation,
            );

            final decision = await usecase(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolCallId: 'tc-1',
              resolvedTool: ResolvedTool.skillCommand(commandName: toolName),
            );

            expect(
              decision.permissionResult,
              ToolPermissionResult.needsConfirmation,
            );
            expect(decision.permissionTableId, permissionId);
          }
        },
      );

      test(
        'nested grants stay isolated to exact effective target',
        () async {
          final conversationToolsRepository =
              fixture.conversationToolsRepository;
          final syncSkillToolPermissionsUsecase =
              MockSyncSkillToolPermissionsUsecase();
          when(
            () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolName: 'skill__app__duckduckgo__search',
            ),
          ).thenAnswer((_) async => 'duckduckgo-search');
          when(
            () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolName: 'skill__app__weather__search',
            ),
          ).thenAnswer((_) async => 'weather-search');
          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'duckduckgo-search',
            ),
          ).thenAnswer((_) async => ToolPermissionResult.granted);
          when(
            () => conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'weather-search',
            ),
          ).thenAnswer(
            (_) async => ToolPermissionResult.needsConfirmation,
          );
          final usecase = ResolveToolApprovalDecisionUsecase(
            conversationToolsRepository: conversationToolsRepository,
            toolsGroupsRepository: fixture.toolsGroupsRepository,
            workspaceToolsRepository: fixture.workspaceToolsRepository,
            syncSkillToolPermissionsUsecase: syncSkillToolPermissionsUsecase,
          );

          Future<ToolApprovalDecision> resolve(
            String skill,
            String toolCallId,
          ) {
            return usecase(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolCallId: toolCallId,
              resolvedTool: ResolvedTool.skillCommand(
                commandName: agent.callSkillToolName,
                target: agent.AgentResolvedToolName.skillNative(
                  tableId: 'search',
                  skillSlug: skill,
                  toolIdentifier: 'search',
                ),
              ),
            );
          }

          final granted = await resolve('duckduckgo', 'tc-1');
          final other = await resolve('weather', 'tc-2');

          expect(granted.permissionResult, ToolPermissionResult.granted);
          expect(granted.permissionTableId, 'duckduckgo-search');
          expect(
            other.permissionResult,
            ToolPermissionResult.needsConfirmation,
          );
          expect(other.permissionTableId, 'weather-search');
        },
      );

      test('ignores legacy call_skill_tool grant for nested target', () async {
        final syncSkillToolPermissionsUsecase =
            MockSyncSkillToolPermissionsUsecase();
        when(
          () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolName: 'skill__app__duckduckgo__search',
          ),
        ).thenAnswer((_) async => null);
        when(
          () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolName: agent.callSkillToolName,
          ),
        ).thenAnswer((_) async => 'legacy-wrapper-grant');
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
          resolvedTool: ResolvedTool.skillCommand(
            commandName: agent.callSkillToolName,
            target: agent.AgentResolvedToolName.skillNative(
              tableId: 'search',
              skillSlug: 'duckduckgo',
              toolIdentifier: 'search',
            ),
          ),
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
        final _ = verifyNever(
          () => syncSkillToolPermissionsUsecase.permissionTableIdFor(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolName: agent.callSkillToolName,
          ),
        );
      });

      test('grants list_skills without permission lookup', () async {
        final decision = await fixture.usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: ResolvedTool.skillCommand(
            commandName: agent.listSkillsToolName,
          ),
        );

        expect(decision.permissionResult, ToolPermissionResult.granted);
        expect(decision.permissionTableId, isNull);
        final _ = verifyNever(
          () => fixture.conversationToolsRepository.checkToolPermission(
            conversationId: any(named: 'conversationId'),
            workspaceId: any(named: 'workspaceId'),
            toolId: any(named: 'toolId'),
          ),
        );
      });

      test('does not auto-grant run_sub_agent', () async {
        final decision = await fixture.usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: ResolvedTool.skillNative(
            tableId: agent.runSubAgentToolName,
            skillSlug: agent.agentsSkillSlug,
            toolIdentifier: agent.runSubAgentToolName,
          ),
        );

        expect(decision.permissionResult, ToolPermissionResult.notConfigured);
      });
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
            mcpSlug: 'server-1',
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
          mcpSlug: 'server-1',
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
          mcpSlug: 'server-1',
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
