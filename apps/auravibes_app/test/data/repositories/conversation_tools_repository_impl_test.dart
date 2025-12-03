import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'conversation_tools_repository_impl_test.mocks.dart';

@GenerateMocks([WorkspaceToolsRepository])
void main() {
  group('ConversationToolsRepositoryImpl - checkToolPermission', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    const testConversationId = 'test-conversation-id';
    const testWorkspaceId = 'test-workspace-id';
    const testToolId = 'read_file';

    setUp(() {
      // Create an in-memory database for testing
      database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      mockWorkspaceToolsRepository = MockWorkspaceToolsRepository();
      repository = ConversationToolsRepositoryImpl(
        database,
        mockWorkspaceToolsRepository,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('returns notConfigured when tool is not in workspace', () async {
      // Arrange
      when(
        mockWorkspaceToolsRepository.getWorkspaceTool(
          testWorkspaceId,
          testToolId,
        ),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.checkToolPermission(
        conversationId: testConversationId,
        workspaceId: testWorkspaceId,
        toolId: testToolId,
      );

      // Assert
      expect(result, ToolPermissionResult.notConfigured);
    });

    test(
      'returns notConfigured when workspace tool is disabled',
      () async {
        // Arrange
        when(
          mockWorkspaceToolsRepository.getWorkspaceTool(
            testWorkspaceId,
            testToolId,
          ),
        ).thenAnswer(
          (_) async => WorkspaceToolEntity(
            id: 'workspace-tool-id',
            workspaceId: testWorkspaceId,
            toolId: testToolId,
            isEnabled: false,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        final result = await repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert
        expect(result, ToolPermissionResult.notConfigured);
      },
    );

    test(
      'returns granted when workspace grants and no conversation override',
      () async {
        // Arrange
        when(
          mockWorkspaceToolsRepository.getWorkspaceTool(
            testWorkspaceId,
            testToolId,
          ),
        ).thenAnswer(
          (_) async => WorkspaceToolEntity(
            id: 'workspace-tool-id',
            workspaceId: testWorkspaceId,
            toolId: testToolId,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        final result = await repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert
        expect(result, ToolPermissionResult.granted);
      },
    );

    test(
      'returns needsConfirmation when workspace requires confirmation',
      () async {
        // Arrange
        when(
          mockWorkspaceToolsRepository.getWorkspaceTool(
            testWorkspaceId,
            testToolId,
          ),
        ).thenAnswer(
          (_) async => WorkspaceToolEntity(
            id: 'workspace-tool-id',
            workspaceId: testWorkspaceId,
            toolId: testToolId,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        final result = await repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert
        expect(result, ToolPermissionResult.needsConfirmation);
      },
    );

    test(
      'conversation override takes priority - disables tool',
      () async {
        // Arrange: workspace allows, but conversation disables
        when(
          mockWorkspaceToolsRepository.getWorkspaceTool(
            testWorkspaceId,
            testToolId,
          ),
        ).thenAnswer(
          (_) async => WorkspaceToolEntity(
            id: 'workspace-tool-id',
            workspaceId: testWorkspaceId,
            toolId: testToolId,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create a conversation tool that disables this tool
        await database.conversationToolsDao.upsertConversationTool(
          testConversationId,
          testToolId,
          isEnabled: false,
          permission: PermissionAccess.ask,
        );

        // Act
        final result = await repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert
        expect(result, ToolPermissionResult.disabledInConversation);
      },
    );

    test(
      'conversation override takes priority - requires confirmation',
      () async {
        // Arrange: workspace grants, but conversation requires confirmation
        when(
          mockWorkspaceToolsRepository.getWorkspaceTool(
            testWorkspaceId,
            testToolId,
          ),
        ).thenAnswer(
          (_) async => WorkspaceToolEntity(
            id: 'workspace-tool-id',
            workspaceId: testWorkspaceId,
            toolId: testToolId,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create a conversation tool that requires confirmation
        await database.conversationToolsDao.upsertConversationTool(
          testConversationId,
          testToolId,
          isEnabled: true,
          permission: PermissionAccess.ask,
        );

        // Act
        final result = await repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert
        expect(result, ToolPermissionResult.needsConfirmation);
      },
    );

    test(
      'conversation can grant when workspace requires confirmation',
      () async {
        // Arrange: workspace asks, but conversation grants
        when(
          mockWorkspaceToolsRepository.getWorkspaceTool(
            testWorkspaceId,
            testToolId,
          ),
        ).thenAnswer(
          (_) async => WorkspaceToolEntity(
            id: 'workspace-tool-id',
            workspaceId: testWorkspaceId,
            toolId: testToolId,
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Create a conversation tool that grants permission
        await database.conversationToolsDao.upsertConversationTool(
          testConversationId,
          testToolId,
          isEnabled: true,
          permission: PermissionAccess.granted,
        );

        // Act
        final result = await repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert
        expect(result, ToolPermissionResult.granted);
      },
    );
  });

  group('ToolPermissionResult extension methods', () {
    test('shouldSkip returns correct values', () {
      expect(ToolPermissionResult.granted.shouldSkip, false);
      expect(ToolPermissionResult.needsConfirmation.shouldSkip, false);
      expect(ToolPermissionResult.disabledInConversation.shouldSkip, true);
      expect(ToolPermissionResult.disabledInWorkspace.shouldSkip, true);
      expect(ToolPermissionResult.notConfigured.shouldSkip, true);
    });

    test('canExecute returns true only for granted', () {
      expect(ToolPermissionResult.granted.canExecute, true);
      expect(ToolPermissionResult.needsConfirmation.canExecute, false);
      expect(ToolPermissionResult.disabledInConversation.canExecute, false);
      expect(ToolPermissionResult.disabledInWorkspace.canExecute, false);
      expect(ToolPermissionResult.notConfigured.canExecute, false);
    });

    test('requiresConfirmation returns true only for needsConfirmation', () {
      expect(ToolPermissionResult.granted.requiresConfirmation, false);
      expect(ToolPermissionResult.needsConfirmation.requiresConfirmation, true);
      expect(
        ToolPermissionResult.disabledInConversation.requiresConfirmation,
        false,
      );
      expect(
        ToolPermissionResult.disabledInWorkspace.requiresConfirmation,
        false,
      );
      expect(ToolPermissionResult.notConfigured.requiresConfirmation, false);
    });

    test('skipReason returns correct strings', () {
      expect(ToolPermissionResult.granted.skipReason, isNull);
      expect(ToolPermissionResult.needsConfirmation.skipReason, isNull);
      expect(
        ToolPermissionResult.disabledInConversation.skipReason,
        'disabled_in_conversation',
      );
      expect(
        ToolPermissionResult.disabledInWorkspace.skipReason,
        'disabled_in_workspace',
      );
      expect(ToolPermissionResult.notConfigured.skipReason, 'not_configured');
    });
  });
}
