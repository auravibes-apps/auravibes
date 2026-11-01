import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canvas link geometry supports negative and distant node positions', () {
    final workflow = WorkspaceWorkflow.create(
      id: 'workflow-1',
      workspaceId: 'workspace-1',
      name: 'Workflow',
      description: '',
      nodes: const [
        WorkflowNode(
          id: 'inputs',
          kind: .inputs,
          targetId: 'inputs',
          label: 'Inputs',
          x: -400,
          y: -200,
        ),
        WorkflowNode(
          id: 'outputs',
          kind: .outputs,
          targetId: 'outputs',
          label: 'Outputs',
          x: 10000,
          y: 8040,
        ),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'outputs'),
      ],
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );
    final nodes = {for (final node in workflow.nodes) node.id: node};
    final connection = workflow.connections.single;
    final start = WorkflowConnectionGeometry.start(connection, nodes);
    final end = WorkflowConnectionGeometry.end(connection, nodes);
    final path = WorkflowConnectionGeometry.pathForConnection(
      connection,
      nodes,
    );
    final midpoint = path == null
        ? null
        : WorkflowConnectionGeometry.midpoint(path);

    expect(start, const Offset(-120, -134));
    expect(end, const Offset(10000, 8106));
    expect(midpoint, isNotNull);
    expect(WorkflowConnectionGeometry.distanceToPath(midpoint!, path!), 0);
  });
}
