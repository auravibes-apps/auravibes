import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/usecases/tools/execution/execute_tool_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExecuteToolUseCase', () {
    test('should execute built-in tool successfully', () async {
      const useCase = ExecuteToolUseCase();
      final tool = ResolvedTool.builtIn(
        tableId: 'test-id',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );

      final result = await useCase(tool: tool, arguments: {'input': '42'});

      expect(result.status, ToolCallResultStatus.success);
      expect(result.responseRaw, isNotNull);
    });

    test(
      'should return toolNotFound for MCP tools (not yet implemented)',
      () async {
        const useCase = ExecuteToolUseCase();
        final tool = ResolvedTool.mcp(
          tableId: 'test-id',
          toolIdentifier: 'mcp_tool',
          mcpServerId: 'test-server',
        );

        final result = await useCase(tool: tool, arguments: {'input': 'test'});

        expect(result.status, ToolCallResultStatus.toolNotFound);
      },
    );

    test(
      'should return executionError with errorMessage when exception is thrown',
      () async {
        const useCase = ExecuteToolUseCase();
        final tool = ResolvedTool.builtIn(
          tableId: 'test-id',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        );

        // Pass invalid arguments that might cause an exception
        final result = await useCase(
          tool: tool,
          arguments: {'wrong_key': 'value'},
        );

        // Verify we get an execution error with error message
        expect(result.status, ToolCallResultStatus.executionError);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, isNotEmpty);
      },
    );
  });
}
