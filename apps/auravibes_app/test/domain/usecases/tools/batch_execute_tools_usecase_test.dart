import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/usecases/tools/batch_execute_tools_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/execute_tool_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/update_message_metadata_usecase.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'batch_execute_tools_usecase_test.mocks.dart';

@GenerateMocks([UpdateMessageMetadataUseCase])
void main() {
  group('ToolToCall', () {
    test('should parse arguments from JSON', () {
      final toolToCall = ToolToCall(
        id: 'tool-1',
        tool: ResolvedTool.builtIn(
          tableId: 'table-1',
          toolIdentifier: 'calculator',
          tooltype: UserToolType.calculator,
        ),
        argumentsRaw: '{"input": 42, "operation": "add"}',
      );

      final arguments = toolToCall.arguments;

      expect(arguments['input'], 42);
      expect(arguments['operation'], 'add');
    });

    test('should have correct properties', () {
      final tool = ResolvedTool.builtIn(
        tableId: 'table-1',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );

      final toolToCall = ToolToCall(
        id: 'tool-1',
        tool: tool,
        argumentsRaw: '{}',
      );

      expect(toolToCall.id, 'tool-1');
      expect(toolToCall.tool, tool);
      expect(toolToCall.argumentsRaw, '{}');
    });
  });

  group('BatchToolResult', () {
    test('should store tool call ID and update', () {
      const update = ToolResultUpdate(
        toolCallId: 'tool-1',
        resultStatus: ToolCallResultStatus.success,
        responseRaw: 'result',
      );

      final result = BatchToolResult(
        toolCallId: 'tool-1',
        update: update,
      );

      expect(result.toolCallId, 'tool-1');
      expect(result.update, update);
      expect(result.update.resultStatus, ToolCallResultStatus.success);
      expect(result.update.responseRaw, 'result');
    });
  });

  group('BatchExecuteToolsUseCase', () {
    test('can be instantiated', () {
      const executeToolUseCase = ExecuteToolUseCase();
      final mockUpdateMetadataUseCase = MockUpdateMessageMetadataUseCase();

      final useCase = BatchExecuteToolsUseCase(
        executeToolUseCase,
        mockUpdateMetadataUseCase,
      );

      expect(useCase, isNotNull);
    });
  });
}
