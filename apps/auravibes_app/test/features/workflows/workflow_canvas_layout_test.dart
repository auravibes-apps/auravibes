import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canvas bounds include distant nodes and their ports', () {
    final workflow = WorkspaceWorkflow.create(
      id: 'workflow-1',
      workspaceId: 'workspace-1',
      name: 'Workflow',
      description: '',
      nodes: [
        const WorkflowNode(
          id: 'node-1',
          kind: .agent,
          targetId: 'agent-1',
          label: 'Agent',
          x: 4000,
          y: 8040,
          outputs: [
            WorkflowPort(id: 'output-1', name: 'result', type: .any),
            WorkflowPort(id: 'output-2', name: 'summary', type: .string),
          ],
        ),
      ],
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

    final size = WorkflowCanvasLayout.sizeFor(workflow);

    expect(size.width, greaterThan(4000 + 260));
    expect(size.height, greaterThan(8040 + 40 + 1 + 2 * 28));
  });
}
