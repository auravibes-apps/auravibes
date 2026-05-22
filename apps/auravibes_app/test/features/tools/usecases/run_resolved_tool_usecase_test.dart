import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/tools/usecases/run_resolved_tool_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late AgentCancellationRuntime cancellationRuntime;
  late RunResolvedToolUsecase usecase;
  late List<({String serverId, String toolIdentifier})> mcpCalls;

  setUp(() {
    cancellationRuntime = AgentCancellationRuntime();
    mcpCalls = [];
    usecase = RunResolvedToolUsecase(
      agentCancellationRuntime: cancellationRuntime,
      mcpToolCaller:
          ({
            required mcpServerId,
            required toolIdentifier,
            required arguments,
          }) async {
            mcpCalls.add((
              serverId: mcpServerId,
              toolIdentifier: toolIdentifier,
            ));
            return 'mcp result';
          },
    );
  });

  test('runs built-in calculator tools', () async {
    final result = await usecase(
      conversationId: 'conversation-1',
      tool: ResolvedTool.builtIn(
        tableId: 'tool-1',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      ),
      arguments: {'input': '2 + 3'},
    );

    expect(result, '5.0');
  });

  test('rejects built-in tools without input', () {
    expect(
      () => usecase(
        conversationId: 'conversation-1',
        tool: ResolvedTool.builtIn(
          tableId: 'tool-1',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        ),
        arguments: {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects native tools without input', () {
    expect(
      () => usecase(
        conversationId: 'conversation-1',
        tool: ResolvedTool.native(
          tableId: 'tool-1',
          nativeToolType: NativeToolType.url,
        ),
        arguments: {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('runs MCP tools through the injected caller', () async {
    final result = await usecase(
      conversationId: 'conversation-1',
      tool: ResolvedTool.mcp(
        tableId: 'tool-1',
        toolIdentifier: 'remote-tool',
        mcpServerId: 'server-1',
      ),
      arguments: {'value': 1},
    );

    expect(result, 'mcp result');
    expect(
      mcpCalls,
      [(serverId: 'server-1', toolIdentifier: 'remote-tool')],
    );
  });

  test('rejects MCP tools without a server binding', () {
    expect(
      () => usecase(
        conversationId: 'conversation-1',
        tool: ResolvedTool.mcp(
          tableId: 'tool-1',
          toolIdentifier: 'remote-tool',
          mcpServerId: '',
        ),
        arguments: {'value': 1},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('provider creates the shared tool runner', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(runResolvedToolUsecaseProvider),
      isA<RunResolvedToolUsecase>(),
    );
  });
}
