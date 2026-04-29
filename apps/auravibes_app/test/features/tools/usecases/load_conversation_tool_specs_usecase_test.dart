import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_usecase.dart';
import 'package:auravibes_app/features/tools/usecases/load_conversation_tool_specs_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConversationToolsRepository extends ConversationToolsRepository {
  _FakeConversationToolsRepository(this._tools);
  final List<WorkspaceToolEntity> _tools;

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async => _tools;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBuildCombinedToolSpecsUseCase extends BuildCombinedToolSpecsUseCase {
  _FakeBuildCombinedToolSpecsUseCase(this._result)
    : super(
        getToolsGroupById: (_) async => null,
        getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
      );
  final List<ToolSpec> _result;

  @override
  Future<List<ToolSpec>> call(List<WorkspaceToolEntity> enabledTools) async =>
      _result;
}

class _CapturingRepo extends ConversationToolsRepository {
  _CapturingRepo({required this.onGetTools});

  final Future<List<WorkspaceToolEntity>> Function(String, String) onGetTools;

  @override
  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async => onGetTools(conversationId, workspaceId);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('LoadConversationToolSpecsUsecase', () {
    test('returns empty list when no tools', () async {
      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );
      expect(result, isEmpty);
    });

    test('returns tool specs from build combined usecase', () async {
      final specs = [
        const ToolSpec(
          name: 'tool-1',
          description: 'desc',
          inputJsonSchema: {},
        ),
      ];

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase(
          specs,
        ),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'tool-1');
    });

    test('passes correct conversationId and workspaceId', () async {
      String? capturedConvId;
      String? capturedWsId;

      final repo = _CapturingRepo(
        onGetTools: (convId, wsId) async {
          capturedConvId = convId;
          capturedWsId = wsId;
          return <WorkspaceToolEntity>[];
        },
      );

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: repo,
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase([]),
      );

      await usecase(
        conversationId: 'conv-abc',
        workspaceId: 'ws-xyz',
      );

      expect(capturedConvId, 'conv-abc');
      expect(capturedWsId, 'ws-xyz');
    });

    test('returns multiple tool specs', () async {
      final specs = [
        const ToolSpec(name: 't1', description: 'd1', inputJsonSchema: {}),
        const ToolSpec(name: 't2', description: 'd2', inputJsonSchema: {}),
        const ToolSpec(name: 't3', description: 'd3', inputJsonSchema: {}),
      ];

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository([]),
        buildCombinedToolSpecsUseCase: _FakeBuildCombinedToolSpecsUseCase(
          specs,
        ),
      );

      final result = await usecase(
        conversationId: 'conv-1',
        workspaceId: 'ws-1',
      );
      expect(result, hasLength(3));
    });

    test('constructor stores dependencies', () {
      final repo = _FakeConversationToolsRepository([]);
      final buildUseCase = _FakeBuildCombinedToolSpecsUseCase([]);
      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: repo,
        buildCombinedToolSpecsUseCase: buildUseCase,
      );
      expect(
        usecase,
        isA<LoadConversationToolSpecsUsecase>(),
      );
    });

    test('passes tools from repo to build usecase', () async {
      final tools = [
        WorkspaceToolEntity(
          id: 'w1',
          toolId: 'tool1',
          isEnabled: true,
          workspaceId: 'ws-1',
          permissionMode: ToolPermissionMode.alwaysAllow,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];

      List<WorkspaceToolEntity>? capturedTools;
      final buildUseCase = _CapturingBuildCombined(
        onCall: (t) async {
          capturedTools = t;
          return [];
        },
      );

      final usecase = LoadConversationToolSpecsUsecase(
        conversationToolsRepository: _FakeConversationToolsRepository(tools),
        buildCombinedToolSpecsUseCase: buildUseCase,
      );

      await usecase(conversationId: 'conv-1', workspaceId: 'ws-1');

      expect(capturedTools, isNotNull);
      expect(capturedTools!.length, 1);
      expect(capturedTools!.first.toolId, 'tool1');
    });
  });
}

class _CapturingBuildCombined extends BuildCombinedToolSpecsUseCase {
  _CapturingBuildCombined({required this.onCall})
    : super(
        getToolsGroupById: (_) async => null,
        getMcpToolSpec: ({required mcpServerId, required toolName}) => null,
      );

  final Future<List<ToolSpec>> Function(List<WorkspaceToolEntity>) onCall;

  @override
  Future<List<ToolSpec>> call(List<WorkspaceToolEntity> tools) => onCall(tools);
}
