import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/domain/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/batch_execute_tools_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/grant_tool_permission_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/update_message_metadata_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'grant_tool_permission_usecase_test.mocks.dart';

@GenerateMocks([
  MessageRepository,
  ConversationToolsRepository,
  ToolsGroupsRepository,
  WorkspaceToolsRepository,
  BatchExecuteToolsUseCase,
  UpdateMessageMetadataUseCase,
])
void main() {
  group('GrantToolPermissionUseCase', () {
    test('can be instantiated', () {
      final mockMessageRepo = MockMessageRepository();
      final mockConversationToolsRepo = MockConversationToolsRepository();
      final mockToolsGroupsRepo = MockToolsGroupsRepository();
      final mockWorkspaceToolsRepo = MockWorkspaceToolsRepository();
      final mockBatchExecuteUseCase = MockBatchExecuteToolsUseCase();
      final mockUpdateMetadataUseCase = MockUpdateMessageMetadataUseCase();

      final useCase = GrantToolPermissionUseCase(
        mockMessageRepo,
        mockConversationToolsRepo,
        mockToolsGroupsRepo,
        mockWorkspaceToolsRepo,
        mockBatchExecuteUseCase,
        mockUpdateMetadataUseCase,
      );

      expect(useCase, isNotNull);
    });
  });
}
