import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_mocks.dart';

void main() {
  setUpAll(registerTestFallbackValues);

  group('ConversationToolsRepositoryImpl - checkToolPermission', () {
    final fixture = _ConversationToolsRepositoryFixture();

    const testConversationId = 'test-conversation-id';
    const testWorkspaceId = 'test-workspace-id';
    const testToolId = 'read_file';

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns notConfigured when tool is not in workspace', () async {
      // Arrange.
      when(
        () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
          testWorkspaceId,
          testToolId,
        ),
      ).thenAnswer((_) async => null);

      // Act.
      final result = await fixture.repository.checkToolPermission(
        conversationId: testConversationId,
        workspaceId: testWorkspaceId,
        toolId: testToolId,
      );

      // Assert.
      expect(result, ToolPermissionResult.notConfigured);
    });

    test(
      'returns notConfigured when workspace tool is disabled',
      () async {
        // Arrange.
        when(
          () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
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

        // Act.
        final result = await fixture.repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert.
        expect(result, ToolPermissionResult.notConfigured);
      },
    );

    test(
      'returns granted when workspace grants and no conversation override',
      () async {
        // Arrange.
        when(
          () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
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

        // Act.
        final result = await fixture.repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert.
        expect(result, ToolPermissionResult.granted);
      },
    );

    test(
      'returns needsConfirmation when workspace requires confirmation',
      () async {
        // Arrange.
        when(
          () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
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

        // Act.
        final result = await fixture.repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert.
        expect(result, ToolPermissionResult.needsConfirmation);
      },
    );

    test(
      'conversation override takes priority - disables tool',
      () async {
        // Arrange: workspace allows, but conversation disables.
        when(
          () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
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

        // Create a conversation tool that disables this tool.
        final _ = await fixture.database.conversationToolsDao
            .upsertConversationTool(
              testConversationId,
              'workspace-tool-id',
              isEnabled: false,
              permission: PermissionAccess.ask,
            );

        // Act.
        final result = await fixture.repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert.
        expect(result, ToolPermissionResult.disabledInConversation);
      },
    );

    test(
      'conversation override takes priority - requires confirmation',
      () async {
        // Arrange: workspace grants, but conversation requires confirmation.
        when(
          () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
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

        // Create a conversation tool that requires confirmation.
        final _ = await fixture.database.conversationToolsDao
            .upsertConversationTool(
              testConversationId,
              'workspace-tool-id',
              isEnabled: true,
              permission: PermissionAccess.ask,
            );

        // Act.
        final result = await fixture.repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert.
        expect(result, ToolPermissionResult.needsConfirmation);
      },
    );

    test(
      'conversation can grant when workspace requires confirmation',
      () async {
        // Arrange: workspace asks, but conversation grants.
        when(
          () => fixture.mockWorkspaceToolsRepository.getWorkspaceTool(
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

        // Create a conversation tool that grants permission.
        final _ = await fixture.database.conversationToolsDao
            .upsertConversationTool(
              testConversationId,
              'workspace-tool-id',
              isEnabled: true,
              permission: PermissionAccess.granted,
            );

        // Act.
        final result = await fixture.repository.checkToolPermission(
          conversationId: testConversationId,
          workspaceId: testWorkspaceId,
          toolId: testToolId,
        );

        // Assert.
        expect(result, ToolPermissionResult.granted);
      },
    );
  });

  group('getConversationTools', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns empty list when no tools configured', () async {
      final tools = await fixture.repository.getConversationTools('conv-1');
      expect(tools, isEmpty);
    });

    test('returns mapped entities from database', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.granted,
          );

      final tools = await fixture.repository.getConversationTools('conv-1');
      expect(tools, hasLength(1));
      expect(tools.firstOrNull?.conversationId, 'conv-1');
      expect(tools.firstOrNull?.toolId, 'tool-1');
      expect(tools.firstOrNull?.isEnabled, isTrue);
      expect(tools.firstOrNull?.permissionMode, ToolPermissionMode.alwaysAllow);
    });
  });

  group('getConversationTool', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns null when tool not found', () async {
      final tool = await fixture.repository.getConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(tool, isNull);
    });

    test('returns mapped entity when found', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.ask,
          );

      final tool = await fixture.repository.getConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(tool, isNotNull);
      expect((tool ?? fail('Expected tool to be non-null')).toolId, 'tool-1');
      expect(tool.isEnabled, isTrue);
      expect(tool.permissionMode, ToolPermissionMode.alwaysAsk);
    });
  });

  group('setConversationToolEnabled', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns true after enabling', () async {
      final result = await fixture.repository.setConversationToolEnabled(
        'conv-1',
        'tool-1',
        isEnabled: true,
      );
      expect(result, isTrue);
    });

    test('returns true after disabling', () async {
      final result = await fixture.repository.setConversationToolEnabled(
        'conv-1',
        'tool-1',
        isEnabled: false,
      );
      expect(result, isTrue);
    });
  });

  group('setConversationToolPermission', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns true after setting alwaysAllow', () async {
      final result = await fixture.repository.setConversationToolPermission(
        'conv-1',
        'tool-1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );
      expect(result, isTrue);
    });

    test('returns true after setting alwaysAsk', () async {
      final result = await fixture.repository.setConversationToolPermission(
        'conv-1',
        'tool-1',
        permissionMode: ToolPermissionMode.alwaysAsk,
      );
      expect(result, isTrue);
    });
  });

  group('toggleConversationTool', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns true (toggles) for non-existent tool', () async {
      final result = await fixture.repository.toggleConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);
    });

    test('toggles enabled to disabled', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.ask,
          );

      final result = await fixture.repository.toggleConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);

      final tool = await fixture.repository.getConversationTool(
        'conv-1',
        'tool-1',
      );
      expect((tool ?? fail('Expected tool to be non-null')).isEnabled, isFalse);
    });
  });

  group('isConversationToolEnabled', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns true when tool not found (defaults to enabled)', () async {
      final result = await fixture.repository.isConversationToolEnabled(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);
    });

    test('returns true when tool is enabled', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.ask,
          );

      final result = await fixture.repository.isConversationToolEnabled(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);
    });
  });

  group('removeConversationTool', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns false for non-existent tool', () async {
      final result = await fixture.repository.removeConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isFalse);
    });

    test('returns true and removes existing tool', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.ask,
          );

      final result = await fixture.repository.removeConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(result, isTrue);

      final tool = await fixture.repository.getConversationTool(
        'conv-1',
        'tool-1',
      );
      expect(tool, isNull);
    });
  });

  group('getConversationToolsCount', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns zero when no tools', () async {
      final count = await fixture.repository.getConversationToolsCount(
        'conv-1',
      );
      expect(count, 0);
    });

    test('returns correct count', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.ask,
          );
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-2',
            isEnabled: false,
            permission: PermissionAccess.granted,
          );

      final count = await fixture.repository.getConversationToolsCount(
        'conv-1',
      );
      expect(count, 2);
    });
  });

  group('getEnabledConversationToolsCount', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns zero when conversation not found', () async {
      final count = await fixture.repository.getEnabledConversationToolsCount(
        'nonexistent',
      );
      expect(count, 0);
    });
  });

  group('copyConversationTools', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('copies tools from source to target conversation', () async {
      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: true,
            permission: PermissionAccess.granted,
          );

      await fixture.repository.copyConversationTools('conv-1', 'conv-2');

      final tools = await fixture.repository.getConversationTools('conv-2');
      expect(tools, hasLength(1));
      expect(tools.firstOrNull?.conversationId, 'conv-2');
      expect(tools.firstOrNull?.toolId, 'tool-1');
      expect(tools.firstOrNull?.isEnabled, isTrue);
      expect(tools.firstOrNull?.permissionMode, ToolPermissionMode.alwaysAllow);
    });
  });

  group('isToolAvailableForConversation', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test(
      'returns true when workspace enabled and no conversation override',
      () async {
        when(
          () => fixture.mockWorkspaceToolsRepository.isWorkspaceToolEnabled(
            'ws-1',
            'tool-1',
          ),
        ).thenAnswer((_) async => true);

        final result = await fixture.repository.isToolAvailableForConversation(
          'conv-1',
          'ws-1',
          'tool-1',
        );
        expect(result, isTrue);
      },
    );

    test('returns false when workspace disabled', () async {
      when(
        () => fixture.mockWorkspaceToolsRepository.isWorkspaceToolEnabled(
          'ws-1',
          'tool-1',
        ),
      ).thenAnswer((_) async => false);

      final result = await fixture.repository.isToolAvailableForConversation(
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
          () => fixture.mockWorkspaceToolsRepository.isWorkspaceToolEnabled(
            'ws-1',
            'tool-1',
          ),
        ).thenAnswer((_) async => true);

        final _ = await fixture.database.conversationToolsDao
            .upsertConversationTool(
              'conv-1',
              'tool-1',
              isEnabled: false,
              permission: PermissionAccess.ask,
            );

        final result = await fixture.repository.isToolAvailableForConversation(
          'conv-1',
          'ws-1',
          'tool-1',
        );
        expect(result, isFalse);
      },
    );
  });

  group('getAvailableToolsForConversation', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns all workspace tools when no disabled matches', () async {
      when(
        () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
          'ws-1',
        ),
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

      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: false,
            permission: PermissionAccess.ask,
          );

      final result = await fixture.repository.getAvailableToolsForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, hasLength(2));
    });

    test('filters out disabled tools by workspace tool id', () async {
      when(
        () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
          'ws-1',
        ),
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

      final result = await fixture.repository.getAvailableToolsForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, hasLength(1));
      expect(result.firstOrNull, 'read_file');
    });

    test('returns empty when no workspace tools', () async {
      when(
        () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
          'ws-1',
        ),
      ).thenAnswer((_) async => []);

      final result = await fixture.repository.getAvailableToolsForConversation(
        'conv-1',
        'ws-1',
      );
      expect(result, isEmpty);
    });
  });

  group('getAvailableToolEntitiesForConversation', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

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
        () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
          'ws-1',
        ),
      ).thenAnswer((_) async => [wsTool]);

      final _ = await fixture.database.conversationToolsDao
          .upsertConversationTool(
            'conv-1',
            'tool-1',
            isEnabled: false,
            permission: PermissionAccess.ask,
          );

      final result = await fixture.repository
          .getAvailableToolEntitiesForConversation(
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
        () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
          'ws-1',
        ),
      ).thenAnswer((_) async => [wsTool]);

      final result = await fixture.repository
          .getAvailableToolEntitiesForConversation(
            'conv-1',
            'ws-1',
          );
      expect(result, hasLength(1));
      expect(result.firstOrNull?.id, 'tool-1');
    });
  });

  group('setConversationToolsDisabled', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('completes without error', () async {
      await expectLater(
        fixture.repository.setConversationToolsDisabled('conv-1', [
          'tool-1',
          'tool-2',
        ]),
        completes,
      );
    });
  });

  group('validateConversationToolSetting', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('throws for non-existent conversation', () {
      expect(
        () => fixture.repository.validateConversationToolSetting(
          'nonexistent',
          'calculator',
          isEnabled: true,
        ),
        throwsA(isA<ConversationToolsValidationException>()),
      );
    });

    test('throws for invalid tool type', () {
      expect(
        () => fixture.repository.validateConversationToolSetting(
          'nonexistent-conversation',
          'invalid_tool_type_that_does_not_exist',
          isEnabled: true,
        ),
        throwsA(isA<ConversationToolsValidationException>()),
      );
    });
  });

  group('getEnabledConversationTools', () {
    final fixture = _ConversationToolsRepositoryFixture();

    setUp(fixture.setUp);

    tearDown(fixture.tearDown);

    test('returns empty list when no workspace tools', () async {
      when(
        () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
          any(),
        ),
      ).thenAnswer((_) async => []);

      final tools = await fixture.repository.getEnabledConversationTools(
        'conv-1',
      );
      expect(tools, isEmpty);
    });

    test(
      'returns enabled tools filtered by disabled conversation tools',
      () async {
        when(
          () => fixture.mockWorkspaceToolsRepository.getEnabledWorkspaceTools(
            any(),
          ),
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

        final tools = await fixture.repository.getEnabledConversationTools(
          'conv-1',
        );
        expect(tools, hasLength(1));
      },
    );
  });
}

final class _ConversationToolsRepositoryFixture {
  AppDatabase? _database;
  ConversationToolsRepositoryImpl? _repository;
  MockWorkspaceToolsRepository? _mockWorkspaceToolsRepository;

  AppDatabase get database =>
      _database ?? fail('Expected database fixture to be initialized.');

  ConversationToolsRepositoryImpl get repository =>
      _repository ?? fail('Expected repository fixture to be initialized.');

  MockWorkspaceToolsRepository get mockWorkspaceToolsRepository =>
      _mockWorkspaceToolsRepository ??
      fail('Expected workspace tools repository fixture to be initialized.');

  void setUp() {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    final mockWorkspaceToolsRepository = MockWorkspaceToolsRepository();

    _database = database;
    _mockWorkspaceToolsRepository = mockWorkspaceToolsRepository;
    _repository = ConversationToolsRepositoryImpl(
      database,
      mockWorkspaceToolsRepository,
    );
  }

  Future<void> tearDown() async {
    await database.close();
    _database = null;
    _mockWorkspaceToolsRepository = null;
    _repository = null;
  }
}
