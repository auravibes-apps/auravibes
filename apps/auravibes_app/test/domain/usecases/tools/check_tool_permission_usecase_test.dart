// test/domain/usecases/tools/check_tool_permission_usecase_test.dart
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/check_tool_permission_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'check_tool_permission_usecase_test.mocks.dart';

@GenerateMocks([
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
])
void main() {
  group('CheckToolPermissionUseCase', () {
    test('should return granted for built-in calculator tool', () async {
      final mockConversationRepo = MockConversationToolsRepository();
      final mockToolsGroupsRepo = MockToolsGroupsRepository();
      final mockWorkspaceToolsRepo = MockWorkspaceToolsRepository();

      when(
        mockConversationRepo.checkToolPermission(
          conversationId: 'conv-123',
          workspaceId: 'workspace-123',
          toolId: 'calc-123',
        ),
      ).thenAnswer((_) async => ToolPermissionResult.granted);

      final useCase = CheckToolPermissionUseCase(
        mockConversationRepo,
        mockToolsGroupsRepo,
        mockWorkspaceToolsRepo,
      );

      final tool = ResolvedTool.builtIn(
        tableId: 'calc-123',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );

      final result = await useCase.call(
        conversationId: 'conv-123',
        workspaceId: 'workspace-123',
        resolvedTool: tool,
      );

      expect(result, ToolPermissionResult.granted);

      verify(
        mockConversationRepo.checkToolPermission(
          conversationId: 'conv-123',
          workspaceId: 'workspace-123',
          toolId: 'calc-123',
        ),
      ).called(1);
    });
  });
}
