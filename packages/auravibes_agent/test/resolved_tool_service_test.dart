import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:auravibes_agent/src/resolved_tool_service.dart';
import 'package:test/test.dart';

void main() {
  group('ResolvedToolService', () {
    test('runs input tools with input argument', () async {
      final usecase = _usecase();

      final result = await usecase.call(
        conversationId: 'c1',
        tool: AgentResolvedToolName.builtIn(
          tableId: 'calc',
          toolIdentifier: 'calculator',
        ),
        arguments: {'input': '1+1'},
      );

      expect(result, 'built-in:1+1');
    });

    test('runs native tools with input argument', () async {
      final usecase = _usecase();

      final result = await usecase.call(
        conversationId: 'c1',
        tool: AgentResolvedToolName.native(
          tableId: 'native',
          toolIdentifier: 'search',
        ),
        arguments: {'input': 'query'},
      );

      expect(result, 'native:query');
    });

    test('rejects input tools without input', () async {
      final usecase = _usecase();

      expect(
        () => usecase.call(
          conversationId: 'c1',
          tool: AgentResolvedToolName.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
          ),
          arguments: const {},
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('runs MCP tools with server binding', () async {
      final usecase = _usecase();

      final result = await usecase.call(
        conversationId: 'c1',
        tool: AgentResolvedToolName.mcp(
          tableId: 'server-1',
          toolIdentifier: 'sum',
          mcpServerId: 'server-1',
        ),
        arguments: {'a': 1},
      );

      expect(result, 'mcp:server-1:sum:1');
    });

    test('rejects MCP tools without server binding', () async {
      final usecase = _usecase();

      expect(
        () => usecase.call(
          conversationId: 'c1',
          tool: AgentResolvedToolName.mcp(
            tableId: 'server-1',
            toolIdentifier: 'sum',
            mcpServerId: '',
          ),
          arguments: const {},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('runs skill control tools with workspace from conversation', () async {
      final usecase = _usecase();

      final result = await usecase.call(
        conversationId: 'c1',
        tool: AgentResolvedToolName.skillControl(toolIdentifier: 'load_skill'),
        arguments: {'slug': 'writer'},
      );

      expect(result, 'control:w1:load_skill');
    });

    test(
      'runs skill template tools with workspace from conversation',
      () async {
        final usecase = _usecase();

        final result = await usecase.call(
          conversationId: 'c1',
          tool: AgentResolvedToolName.skillTemplate(
            tableId: 'draft',
            skillSlug: 'writer',
            toolIdentifier: 'draft',
          ),
          arguments: {'topic': 'x'},
        );

        expect(result, 'template:w1:writer:draft');
      },
    );

    test('runs skill native tools with workspace from conversation', () async {
      final usecase = _usecase();

      final result = await usecase.call(
        conversationId: 'c1',
        tool: AgentResolvedToolName.skillNative(
          tableId: 'run',
          skillSlug: 'manager',
          toolIdentifier: 'run',
        ),
        arguments: {'topic': 'x'},
      );

      expect(result, 'native-skill:w1:manager:run');
    });
  });
}

ResolvedToolService<AgentResolvedToolName> _usecase() {
  return const ResolvedToolService<AgentResolvedToolName>(
    provider: _FakeResolvedToolProvider(),
  );
}

class _FakeResolvedToolProvider
    implements ResolvedToolProvider<AgentResolvedToolName> {
  const _FakeResolvedToolProvider();

  @override
  AgentResolvedToolExecution<AgentResolvedToolName> toExecution(
    AgentResolvedToolName tool,
  ) {
    return AgentResolvedToolExecution(
      descriptor: tool,
      tool: tool,
    );
  }

  @override
  Future<Object?> runBuiltInTool({
    required String conversationId,
    required AgentResolvedToolName tool,
    required Object input,
  }) async {
    return 'built-in:$input';
  }

  @override
  Future<Object?> runNativeTool({
    required String conversationId,
    required AgentResolvedToolName tool,
    required Object input,
  }) async {
    return 'native:$input';
  }

  @override
  Future<Object?> runMcpTool({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    return 'mcp:$mcpServerId:$toolIdentifier:${arguments.length}';
  }

  @override
  Future<String> getConversationWorkspaceId(String conversationId) async {
    return 'w1';
  }

  @override
  Future<Object?> runSkillControlTool({
    required String conversationId,
    required String workspaceId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
  }) async {
    return 'control:$workspaceId:$toolIdentifier';
  }

  @override
  Future<Object?> runSkillTemplateTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    return 'template:$workspaceId:$skillSlug:$toolSlug';
  }

  @override
  Future<Object?> runSkillNativeTool({
    required String workspaceId,
    required String skillSlug,
    required String toolSlug,
    required Map<String, dynamic> arguments,
  }) async {
    return 'native-skill:$workspaceId:$skillSlug:$toolSlug';
  }
}
