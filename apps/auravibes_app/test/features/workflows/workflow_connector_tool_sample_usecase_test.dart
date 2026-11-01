import 'package:auravibes_app/features/workflows/usecases/workflow_connector_tool_sample_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('read sample returns shape without private values', () async {
    final connector = connectorDefinitions.firstWhere(
      (connector) => connector.tools.any(
        (tool) => tool.urlTemplate != null && !connectorToolWrites(tool),
      ),
    );
    final tool = connector.tools.firstWhere(
      (tool) => tool.urlTemplate != null && !connectorToolWrites(tool),
    );
    WorkflowConnectorToolSampleRequest? executed;
    Future<Object?> runner(WorkflowConnectorToolSampleRequest request) async {
      executed = request;

      return '{"id":"private","nested":{"secret":"private"}}';
    }

    final usecase = WorkflowConnectorToolSampleUsecase(runner, [connector]);

    final result = await usecase(
      workspaceId: 'workspace-1',
      toolId: connectorToolId(connector, tool),
      arguments: const {},
      connectionId: null,
    );

    expect(executed?.revision, connectorToolRevision(connector, tool));
    expect(result, {'id': '', 'nested': <String, Object?>{}});
  });

  test('write tools cannot run to obtain a sample', () async {
    final connector = connectorDefinitions.firstWhere(
      (connector) => connector.tools.any(
        (tool) => tool.urlTemplate != null && connectorToolWrites(tool),
      ),
    );
    final tool = connector.tools.firstWhere(
      (tool) => tool.urlTemplate != null && connectorToolWrites(tool),
    );
    var calls = 0;
    Future<Object?> runner(WorkflowConnectorToolSampleRequest _) async {
      calls++;

      return const {};
    }

    final usecase = WorkflowConnectorToolSampleUsecase(runner, [connector]);

    await expectLater(
      usecase(
        workspaceId: 'workspace-1',
        toolId: connectorToolId(connector, tool),
        arguments: const {},
        connectionId: null,
      ),
      throwsUnsupportedError,
    );
    expect(calls, 0);
  });
}
