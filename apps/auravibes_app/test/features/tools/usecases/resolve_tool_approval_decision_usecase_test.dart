import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/tools_group.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/tools/usecases/resolve_tool_approval_decision_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'resolve_tool_approval_decision_usecase_test.mocks.dart';

@GenerateMocks([
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
])
void main() {
  group('ResolveToolApprovalDecisionUsecase', () {
    late MockConversationToolsRepository conversationToolsRepository;
    late MockToolsGroupsRepository toolsGroupsRepository;
    late MockWorkspaceToolsRepository workspaceToolsRepository;
    late ResolveToolApprovalDecisionUsecase usecase;

    setUp(() {
      conversationToolsRepository = MockConversationToolsRepository();
      toolsGroupsRepository = MockToolsGroupsRepository();
      workspaceToolsRepository = MockWorkspaceToolsRepository();
      usecase = ResolveToolApprovalDecisionUsecase(
        conversationToolsRepository: conversationToolsRepository,
        toolsGroupsRepository: toolsGroupsRepository,
        workspaceToolsRepository: workspaceToolsRepository,
      );
    });

    group('built-in tools', () {
      test('returns granted for always-approved built-in tool', () async {
        final resolvedTool = ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );

        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'calculator',
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
        expect(decision.permissionTableId, 'calculator');
        expect(decision.needsConfirmation, isFalse);
      });

      test(
        'returns needsConfirmation for conversation-ask built-in tool',
        () async {
          final resolvedTool = ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          );

          when(
            conversationToolsRepository.checkToolPermission(
              conversationId: 'conv-1',
              workspaceId: 'ws-1',
              toolId: 'calculator',
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

      test('returns granted for native tool using toolIdentifier', () async {
        final resolvedTool = ResolvedTool.native(
          tableId: 'native-1',
          nativeToolType: NativeToolType.url,
        );

        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'url',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);

        final decision = await usecase(
          conversationId: 'conv-1',
          workspaceId: 'ws-1',
          toolCallId: 'tc-1',
          resolvedTool: resolvedTool,
        );

        expect(decision.permissionResult, ToolPermissionResult.granted);
        expect(decision.permissionTableId, 'url');
      });
    });

    group('MCP tools', () {
      test(
        'resolves permission table ID via tool group and workspace tool',
        () async {
          final resolvedTool = ResolvedTool.mcp(
            tableId: 'server-1',
            toolIdentifier: 'sum',
            mcpServerId: 'server-1',
          );

          when(
            toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
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
            workspaceToolsRepository.getWorkspaceToolByToolName(
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
            conversationToolsRepository.checkToolPermission(
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
        final resolvedTool = ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        );

        when(
          toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
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
        final resolvedTool = ResolvedTool.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        );

        when(
          toolsGroupsRepository.getToolsGroupByMcpServerId('server-1'),
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
          workspaceToolsRepository.getWorkspaceToolByToolName(
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
        final resolvedTool = ResolvedTool.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );

        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conv-1',
            workspaceId: 'ws-1',
            toolId: 'calculator',
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
