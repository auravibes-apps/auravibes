import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workflow boundary inputs and outputs connect to node ports', () {
    final workflow = _workflow(
      inputs: const [
        WorkflowPort(id: 'workflow-input', name: 'query', type: .string),
      ],
      outputs: const [
        WorkflowPort(id: 'workflow-output', name: 'answer', type: .string),
      ],
      nodes: [
        _node(
          id: 'step',
          inputs: const [
            WorkflowPort(id: 'step-input', name: 'prompt', type: .string),
          ],
          outputs: const [
            WorkflowPort(id: 'step-output', name: 'text', type: .string),
          ],
        ),
      ],
      connections: const [
        WorkflowConnection(
          fromPortId: 'workflow-input',
          toPortId: 'step-input',
          toNodeId: 'step',
        ),
        WorkflowConnection(
          fromPortId: 'step-output',
          toPortId: 'workflow-output',
          fromNodeId: 'step',
        ),
      ],
    );

    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(workflow),
      isEmpty,
    );
    final decoded = WorkspaceWorkflow.decode(workflow.encode());
    expect(decoded.connections.first.fromNodeId, isNull);
    expect(decoded.connections.last.toNodeId, isNull);
  });

  test('workflow node graph rejects cycles and dangling endpoints', () {
    final first = _node(
      id: 'first',
      inputs: const [WorkflowPort(id: 'first-input', name: 'in', type: .any)],
      outputs: const [
        WorkflowPort(id: 'first-output', name: 'out', type: .any),
      ],
    );
    final second = _node(
      id: 'second',
      inputs: const [WorkflowPort(id: 'second-input', name: 'in', type: .any)],
      outputs: const [
        WorkflowPort(id: 'second-output', name: 'out', type: .any),
      ],
    );
    final workflow = _workflow(
      nodes: [first, second],
      connections: const [
        WorkflowConnection(
          fromPortId: 'first-output',
          toPortId: 'second-input',
          fromNodeId: 'first',
          toNodeId: 'second',
        ),
        WorkflowConnection(
          fromPortId: 'second-output',
          toPortId: 'first-input',
          fromNodeId: 'second',
          toNodeId: 'first',
        ),
        WorkflowConnection(
          fromPortId: 'missing-output',
          toPortId: 'first-input',
          fromNodeId: 'missing',
          toNodeId: 'first',
        ),
      ],
    );

    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(workflow),
      containsAll([
        WorkflowGraphIssue.cycle,
        WorkflowGraphIssue.missingConnectionNode,
      ]),
    );
  });

  test('workflow dependencies reject a transitive cycle', () {
    final candidate = _workflow(
      id: 'a',
      nodes: [_node(id: 'b-ref', kind: .workflow, targetId: 'b')],
    );
    final b = _workflow(
      id: 'b',
      nodes: [_node(id: 'a-ref', kind: .workflow, targetId: 'a')],
    );

    expect(
      WorkflowGraphValidation.workflowHasDependencyCycle(candidate, [b]),
      isTrue,
    );
    expect(
      WorkflowGraphValidation.workflowHasDependencyCycle(candidate, const []),
      isFalse,
    );
  });

  test('workflow node positions stay within the scrollable canvas limit', () {
    final workflow = _workflow(
      nodes: [_node(id: 'far-away').copyWith(x: 10001, y: 10001)],
    );

    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(workflow),
      contains(WorkflowGraphIssue.invalidNodePosition),
    );
  });
}

WorkspaceWorkflow _workflow({
  String id = 'draft',
  List<WorkflowPort> inputs = const [],
  List<WorkflowPort> outputs = const [],
  List<WorkflowNode> nodes = const [],
  List<WorkflowConnection> connections = const [],
}) => WorkspaceWorkflow.create(
  id: id,
  workspaceId: 'workspace-1',
  name: 'Workflow',
  description: '',
  inputs: inputs,
  outputs: outputs,
  nodes: nodes,
  connections: connections,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);

WorkflowNode _node({
  required String id,
  WorkflowNodeKind kind = .agent,
  String? targetId,
  List<WorkflowPort> inputs = const [],
  List<WorkflowPort> outputs = const [],
}) => WorkflowNode(
  id: id,
  kind: kind,
  targetId: targetId ?? id,
  label: id,
  x: 100,
  y: 100,
  inputs: inputs,
  outputs: outputs,
);
