import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/call_mcp_tool_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('throws when server is not connected', () async {
    final usecase = CallMcpToolUseCase(
      callTool: ({required toolIdentifier, required arguments}) async => 'ok',
    );

    expect(
      () => usecase.call(
        isConnected: false,
        availableTools: const [],
        mcpServerId: 'm1',
        toolIdentifier: 'tool',
        arguments: const {},
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('delegates call when connected and tool exists', () async {
    final usecase = CallMcpToolUseCase(
      callTool: ({required toolIdentifier, required arguments}) async {
        expect(toolIdentifier, 'tool1');
        expect(arguments['input'], 'x');
        return 'result';
      },
    );

    final result = await usecase.call(
      isConnected: true,
      availableTools: const [
        McpToolInfo(toolName: 'tool1', description: 'd', inputSchema: {}),
      ],
      mcpServerId: 'm1',
      toolIdentifier: 'tool1',
      arguments: const {'input': 'x'},
    );

    expect(result, 'result');
  });
}
