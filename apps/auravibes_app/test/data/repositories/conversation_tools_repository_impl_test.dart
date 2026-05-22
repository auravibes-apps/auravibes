import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
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
          'workspace-tool-id',
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
          'workspace-tool-id',
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
          'workspace-tool-id',
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

  group('getConversationTools', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns empty list when no tools configured', () async {
      final tools = await repository.getConversationTools('conv-1');
      expect(tools, isEmpty);
    });

    test('returns mapped entities from database', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.granted,
      );

      final tools = await repository.getConversationTools('conv-1');
      expect(tools, hasLength(1));
      expect(tools.first.conversationId, 'conv-1');
      expect(tools.first.toolId, 'tool-1');
      expect(tools.first.isEnabled, isTrue);
      expect(tools.first.permissionMode, ToolPermissionMode.alwaysAllow);
    });
  });

  group('getConversationTool', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns null when tool not found', () async {
      final tool = await repository.getConversationTool('conv-1', 'tool-1');
      expect(tool, isNull);
    });

    test('returns mapped entity when found', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.ask,
      );

      final tool = await repository.getConversationTool('conv-1', 'tool-1');
      expect(tool, isNotNull);
      expect(tool!.toolId, 'tool-1');
      expect(tool.isEnabled, isTrue);
      expect(tool.permissionMode, ToolPermissionMode.alwaysAsk);
    });
  });

  group('setConversationToolEnabled', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns true after enabling', () async {
      final result = await repository.setConversationToolEnabled(
        'conv-1',
        'tool-1',
        isEnabled: true,
      );
      expect(result, isTrue);
    });

    test('returns true after disabling', () async {
      final result = await repository.setConversationToolEnabled(
        'conv-1',
        'tool-1',
        isEnabled: false,
      );
      expect(result, isTrue);
    });
  });

  group('setConversationToolPermission', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns true after setting alwaysAllow', () async {
      final result = await repository.setConversationToolPermission(
        'conv-1',
        'tool-1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );
      expect(result, isTrue);
    });

    test('returns true after setting alwaysAsk', () async {
      final result = await repository.setConversationToolPermission(
        'conv-1',
        'tool-1',
        permissionMode: ToolPermissionMode.alwaysAsk,
      );
      expect(result, isTrue);
    });
  });

  group('toggleConversationTool', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns true (toggles) for non-existent tool', () async {
      final result = await repository.toggleConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);
    });

    test('toggles enabled to disabled', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.ask,
      );

      final result = await repository.toggleConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);

      final tool = await repository.getConversationTool('conv-1', 'tool-1');
      expect(tool!.isEnabled, isFalse);
    });
  });

  group('isConversationToolEnabled', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns true when tool not found (defaults to enabled)', () async {
      final result = await repository.isConversationToolEnabled(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);
    });

    test('returns true when tool is enabled', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.ask,
      );

      final result = await repository.isConversationToolEnabled(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);
    });
  });

  group('removeConversationTool', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns false for non-existent tool', () async {
      final result = await repository.removeConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isFalse);
    });

    test('returns true and removes existing tool', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.ask,
      );

      final result = await repository.removeConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);

      final tool = await repository.getConversationTool('conv-1', 'tool-1');
      expect(tool, isNull);
    });
  });

  group('getConversationToolsCount', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns zero when no tools', () async {
      final count = await repository.getConversationToolsCount('conv-1');
      expect(count, 0);
    });

    test('returns correct count', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.ask,
      );
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-2',
        isEnabled: false,
        permission: PermissionAccess.granted,
      );

      final count = await repository.getConversationToolsCount('conv-1');
      expect(count, 2);
    });
  });

  group('getEnabledConversationToolsCount', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns zero when conversation not found', () async {
      final count = await repository.getEnabledConversationToolsCount(
        'nonexistent',
      );
      expect(count, 0);
    });
  });

  group('copyConversationTools', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('copies tools from source to target conversation', () async {
      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: true,
        permission: PermissionAccess.granted,
      );

      await repository.copyConversationTools('conv-1', 'conv-2');

      final tools = await repository.getConversationTools('conv-2');
      expect(tools, hasLength(1));
      expect(tools.first.toolId, 'tool-1');
    });
  });

  group('isToolAvailableForConversation', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test(
      'returns true when workspace enabled and no conversation override',
      () async {
        when(
          mockWorkspaceToolsRepository.isWorkspaceToolEnabled('ws-1', 'tool-1'),
        ).thenAnswer((_) async => true);

        final result = await repository.isToolAvailableForConversation(
          'conv-1',
          'ws-1',
          'tool-1',
        );
        expect(result, isTrue);
      },
    );

    test('returns false when workspace disabled', () async {
      when(
        mockWorkspaceToolsRepository.isWorkspaceToolEnabled('ws-1', 'tool-1'),
      ).thenAnswer((_) async => false);

      final result = await repository.isToolAvailableForConversation(
        'conv-1',
        'ws-1',
        'tool-1',
      );
      expect(result, isFalse);
    });

    test(
      'returns false when workspace enabled but conversation disabled',
      () async {
        when(
          mockWorkspaceToolsRepository.isWorkspaceToolEnabled('ws-1', 'tool-1'),
        ).thenAnswer((_) async => true);

        await database.conversationToolsDao.upsertConversationTool(
          'conv-1',
          'tool-1',
          isEnabled: false,
          permission: PermissionAccess.ask,
        );

        final result = await repository.isToolAvailableForConversation(
          'conv-1',
          'ws-1',
          'tool-1',
        );
        expect(result, isFalse);
      },
    );
  });

  group('getAvailableToolsForConversation', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns all workspace tools when no disabled matches', () async {
      when(
        mockWorkspaceToolsRepository.getEnabledWorkspaceTools('ws-1'),
      ).thenAnswer(
        (_) async => [
          WorkspaceToolEntity(
            id: 'tool-1',
            workspaceId: 'ws-1',
            toolId: 'read_file',
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
          WorkspaceToolEntity(
            id: 'tool-2',
            workspaceId: 'ws-1',
            toolId: 'write_file',
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );

      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: false,
        permission: PermissionAccess.ask,
      );

      final result = await repository.getAvailableToolsForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, hasLength(2));
    });

    test('filters out disabled tools by workspace tool id', () async {
      when(
        mockWorkspaceToolsRepository.getEnabledWorkspaceTools('ws-1'),
      ).thenAnswer(
        (_) async => [
          WorkspaceToolEntity(
            id: 'tool-1',
            workspaceId: 'ws-1',
            toolId: 'read_file',
            isEnabled: true,
            permissionMode: ToolPermissionMode.alwaysAllow,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );

      final result = await repository.getAvailableToolsForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, hasLength(1));
      expect(result.first, 'read_file');
    });

    test('returns empty when no workspace tools', () async {
      when(
        mockWorkspaceToolsRepository.getEnabledWorkspaceTools('ws-1'),
      ).thenAnswer((_) async => []);

      final result = await repository.getAvailableToolsForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, isEmpty);
    });
  });

  group('getAvailableToolEntitiesForConversation', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns all entities when disabled tool id does not match', () async {
      final wsTool = WorkspaceToolEntity(
        id: 'tool-1',
        workspaceId: 'ws-1',
        toolId: 'read_file',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAllow,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      when(
        mockWorkspaceToolsRepository.getEnabledWorkspaceTools('ws-1'),
      ).thenAnswer((_) async => [wsTool]);

      await database.conversationToolsDao.upsertConversationTool(
        'conv-1',
        'tool-1',
        isEnabled: false,
        permission: PermissionAccess.ask,
      );

      final result = await repository.getAvailableToolEntitiesForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, hasLength(1));
    });

    test('returns all workspace entities when no overrides', () async {
      final wsTool = WorkspaceToolEntity(
        id: 'tool-1',
        workspaceId: 'ws-1',
        toolId: 'read_file',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAllow,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      when(
        mockWorkspaceToolsRepository.getEnabledWorkspaceTools('ws-1'),
      ).thenAnswer((_) async => [wsTool]);

      final result = await repository.getAvailableToolEntitiesForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'tool-1');
    });
  });

  group('setConversationToolsDisabled', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('completes without error', () async {
      await expectLater(
        repository.setConversationToolsDisabled('conv-1', ['tool-1', 'tool-2']),
        completes,
      );
    });
  });

  group('validateConversationToolSetting', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('throws for non-existent conversation', () async {
      expect(
        () => repository.validateConversationToolSetting(
          'nonexistent',
          'calculator',
          isEnabled: true,
        ),
        throwsA(isA<ConversationToolsValidationException>()),
      );
    });

    test('throws for invalid tool type', () async {
      expect(
        () => repository.validateConversationToolSetting(
          'nonexistent-conversation',
          'invalid_tool_type_that_does_not_exist',
          isEnabled: true,
        ),
        throwsA(isA<ConversationToolsValidationException>()),
      );
    });
  });

  group('getEnabledConversationTools', () {
    late AppDatabase database;
    late ConversationToolsRepositoryImpl repository;
    late MockWorkspaceToolsRepository mockWorkspaceToolsRepository;

    setUp(() {
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

    test('returns empty list when no workspace tools', () async {
      when(
        mockWorkspaceToolsRepository.getEnabledWorkspaceTools(any),
      ).thenAnswer((_) async => []);

      final tools = await repository.getEnabledConversationTools('conv-1');
      expect(tools, isEmpty);
    });

    test(
      'returns enabled tools filtered by disabled conversation tools',
      () async {
        when(
          mockWorkspaceToolsRepository.getEnabledWorkspaceTools(any),
        ).thenAnswer(
          (_) async => [
            WorkspaceToolEntity(
              id: 'tool-1',
              workspaceId: 'ws-1',
              toolId: 'read_file',
              isEnabled: true,
              permissionMode: ToolPermissionMode.alwaysAllow,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ],
        );

        final tools = await repository.getEnabledConversationTools('conv-1');
        expect(tools, hasLength(1));
      },
    );
  });
}
