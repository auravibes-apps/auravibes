import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects a non-map definition with a format error', () {
    expect(
      () => WorkflowDefinition.fromJson({'definition': null}),
      throwsFormatException,
    );
  });

  test('preserves Connector tool node identity and typed input ports', () {
    final definition = WorkflowDefinition(
      id: 'workflow-1',
      workspaceId: 'workspace-1',
      name: 'Research',
      description: '',
      inputs: const [],
      outputs: const [],
      nodes: const [
        WorkflowNode(
          id: 'node-1',
          kind: .connectorTool,
          targetId: 'connector/brave/web_search',
          label: 'Brave Search: Web search',
          x: 100,
          y: 100,
          targetSource: 'Brave Search',
          inputs: [WorkflowPort(id: 'query', name: 'query', type: .string)],
          outputs: [
            WorkflowPort(
              id: 'result',
              name: 'Result',
              type: .any,
              isRequired: false,
            ),
          ],
        ),
      ],
      connections: const [],
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

    final node = WorkflowDefinition.decode(definition.encode()).nodes.single;

    expect(node.kind, WorkflowNodeKind.connectorTool);
    expect(node.targetId, 'connector/brave/web_search');
    expect(node.inputs.single.name, 'query');
    expect(node.inputs.single.type, WorkflowValueType.string);
  });
}
