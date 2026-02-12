// test/domain/usecases/tools/filter_tools_by_permission_usecase_test.dart
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/check_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/filter_tools_by_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/update_message_metadata_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'filter_tools_by_permission_usecase_test.mocks.dart';

@GenerateMocks([
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
  MessageRepository,
])
void main() {
  group('FilterToolsByPermissionUseCase', () {
    test('should categorize tools by permission', () async {
      final mockConversationRepo = MockConversationToolsRepository();
      final mockToolsGroupsRepo = MockToolsGroupsRepository();
      final mockWorkspaceToolsRepo = MockWorkspaceToolsRepository();
      final mockMessageRepo = MockMessageRepository();

      when(
        mockConversationRepo.checkToolPermission(
          conversationId: anyNamed('conversationId'),
          workspaceId: anyNamed('workspaceId'),
          toolId: anyNamed('toolId'),
        ),
      ).thenAnswer((_) async => ToolPermissionResult.granted);

      final checkPermissionUseCase = CheckToolPermissionUseCase(
        mockConversationRepo,
        mockToolsGroupsRepo,
        mockWorkspaceToolsRepo,
      );

      final updateMetadataUseCase = UpdateMessageMetadataUseCase(
        mockMessageRepo,
      );

      final useCase = FilterToolsByPermissionUseCase(
        checkPermissionUseCase,
        updateMetadataUseCase,
      );

      final tools = [
        ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'table-1',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{}',
        ),
      ];

      final result = await useCase.call(
        tools: tools,
        conversationId: 'conv-123',
        workspaceId: 'ws-123',
        responseMessageId: 'msg-123',
      );

      expect(
        result.grantedTools.isNotEmpty || result.resolvedUpdates.isNotEmpty,
        true,
      );
    });
  });
}
