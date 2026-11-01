import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_metadata_reducer.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_graph_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('node links bind typed fields and survive a v2 round trip', () {
    final workflow = _boundWorkflow();

    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(workflow),
      isEmpty,
    );
    final decoded = WorkspaceWorkflow.decode(workflow.encode());
    expect(WorkflowDefinition.formatVersion, 2);
    expect(decoded.connections.first.fromNodeId, 'inputs');
    expect(
      decoded.nodes
          .singleWhere((node) => node.kind == .connectorTool)
          .inputBindings['prompt']
          ?.jsonPointer,
      '/query',
    );
  });

  test('rejects incompatible types and missing dependency links', () {
    final workflow = _boundWorkflow(inputType: .boolean, addInputLink: false);

    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(workflow),
      contains(WorkflowGraphIssue.nodeBindingUnavailable),
    );
  });

  test(
    'resolves array JSON Pointers and enforces schema-compatible bindings',
    () {
      final sourceField = WorkflowField(
        id: 'records',
        name: 'records',
        type: .array,
        items: const WorkflowField(
          id: 'record',
          name: 'record',
          type: .object,
          properties: [WorkflowField(id: 'code', name: 'code', type: .integer)],
        ),
      );
      final workflow = _boundWorkflow(
        inputFields: [sourceField],
        sourcePointer: '/records/0/code',
        sourceType: .integer,
        targetType: .number,
      );

      expect(
        WorkflowGraphValidation.validateWorkflowDefinition(workflow),
        isEmpty,
      );
    },
  );

  test('rejects cycles and unknown nodes in node links', () {
    final workflow = WorkspaceWorkflow.create(
      id: 'cycle',
      workspaceId: 'workspace-1',
      name: 'Workflow',
      description: '',
      nodes: [
        _node(id: 'inputs', kind: .inputs, targetId: 'inputs'),
        _node(id: 'first', kind: .connectorTool),
        _node(id: 'second', kind: .connectorTool),
        _node(id: 'outputs', kind: .outputs, targetId: 'outputs'),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'first', toNodeId: 'second'),
        WorkflowConnection(fromNodeId: 'second', toNodeId: 'first'),
        WorkflowConnection(fromNodeId: 'missing', toNodeId: 'outputs'),
      ],
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(workflow),
      containsAll([
        WorkflowGraphIssue.cycle,
        WorkflowGraphIssue.missingConnectionNode,
      ]),
    );
  });

  test('deleting source leaves a broken binding for repair', () {
    final workflow = _boundWorkflow();
    final state = WorkflowEditorState.newWorkflow(workflow.workspaceId)
        .copyWith(workflow: workflow);

    final updated = WorkflowEditorNodeReducer.remove(state, 'connector');

    expect(
      updated.workflow!.nodes.any((node) => node.id == 'connector'),
      isFalse,
    );
    expect(
      updated.workflow!.nodes
          .singleWhere((node) => node.id == 'outputs')
          .inputBindings['answer']
          ?.sourceNodeId,
      'connector',
    );
    expect(
      WorkflowGraphValidation.validateWorkflowDefinition(updated.workflow!),
      contains(WorkflowGraphIssue.nodeBindingUnavailable),
    );
  });

  test('editor refuses a binding that would add a node-link cycle', () {
    final workflow = _workflow(
      nodes: [
        _node(id: 'inputs', kind: .inputs, targetId: 'inputs'),
        _node(
          id: 'first',
          inputFields: const [
            WorkflowField(id: 'value', name: 'value', type: .string),
          ],
        ),
        _node(
          id: 'second',
          outputFields: const [
            WorkflowField(id: 'value', name: 'value', type: .string),
          ],
        ),
        _node(id: 'outputs', kind: .outputs, targetId: 'outputs'),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'first'),
        WorkflowConnection(fromNodeId: 'first', toNodeId: 'second'),
        WorkflowConnection(fromNodeId: 'second', toNodeId: 'outputs'),
      ],
    );
    final state = WorkflowEditorState.newWorkflow(workflow.workspaceId)
        .copyWith(workflow: workflow);

    final updated = WorkflowEditorNodeReducer.setInputBinding(
      state,
      nodeId: 'first',
      fieldId: 'value',
      binding: const WorkflowBinding.fromNode(
        sourceNodeId: 'second',
        jsonPointer: '/value',
      ),
    );

    expect(identical(updated, state), isTrue);
    expect(updated.workflow!.connections, hasLength(3));
  });

  test('selecting Transform operands creates node dependency links', () {
    final workflow = _workflow(
      nodes: [
        _node(id: 'inputs', kind: .inputs, targetId: 'inputs'),
        _node(
          id: 'connector',
          outputFields: const [
            WorkflowField(id: 'value', name: 'value', type: .number),
          ],
        ),
        _node(id: 'transform', kind: .transform),
        _node(id: 'outputs', kind: .outputs, targetId: 'outputs'),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'connector'),
        WorkflowConnection(fromNodeId: 'transform', toNodeId: 'outputs'),
      ],
    );
    final state = WorkflowEditorState.newWorkflow(workflow.workspaceId)
        .copyWith(workflow: workflow);

    final updated = WorkflowEditorNodeReducer.setTransformOutputs(
      state,
      'transform',
      [
        WorkflowTransformOutput(
          id: 'sum',
          name: 'sum',
          type: .number,
          operation: .selectField,
          operands: [
            const WorkflowTransformOperand(
              id: 'source',
              name: 'source',
              binding: WorkflowBinding.fromNode(
                sourceNodeId: 'connector',
                jsonPointer: '/value',
              ),
            ),
          ],
        ),
      ],
    );

    expect(
      updated.workflow!.connections.any(
        (connection) =>
            connection.fromNodeId == 'connector' &&
            connection.toNodeId == 'transform',
      ),
      isTrue,
    );
  });

  test('identifies incompatible Transform output for inline repair', () {
    final workflow = _workflow(
      nodes: [
        _node(id: 'inputs', kind: .inputs, targetId: 'inputs'),
        _node(
          id: 'connector',
          outputFields: const [
            WorkflowField(id: 'value', name: 'value', type: .string),
          ],
        ),
        _node(
          id: 'transform',
          kind: .transform,
          transformOutputs: const [
            WorkflowTransformOutput(
              id: 'number',
              name: 'number',
              type: .number,
              operation: .selectField,
              operands: [
                WorkflowTransformOperand(
                  id: 'value',
                  name: 'value',
                  binding: WorkflowBinding.fromNode(
                    sourceNodeId: 'connector',
                    jsonPointer: '/value',
                  ),
                ),
              ],
            ),
          ],
        ),
        _node(id: 'outputs', kind: .outputs, targetId: 'outputs'),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'connector'),
        WorkflowConnection(fromNodeId: 'connector', toNodeId: 'transform'),
        WorkflowConnection(fromNodeId: 'transform', toNodeId: 'outputs'),
      ],
    );

    expect(
      WorkflowGraphValidation.invalidTransformOutputIds(workflow, 'transform'),
      contains('number'),
    );
  });

  test('fan-in exposes only values available on every route', () {
    final workflow = _workflow(
      nodes: [
        _node(
          id: 'inputs',
          kind: .inputs,
          targetId: 'inputs',
          outputFields: const [
            WorkflowField(id: 'request', name: 'request', type: .object),
          ],
        ),
        _node(id: 'condition', kind: .condition),
        _node(
          id: 'left',
          outputFields: const [
            WorkflowField(id: 'leftValue', name: 'leftValue', type: .string),
          ],
        ),
        _node(
          id: 'right',
          outputFields: const [
            WorkflowField(id: 'rightValue', name: 'rightValue', type: .string),
          ],
        ),
        _node(id: 'join'),
        _node(id: 'outputs', kind: .outputs, targetId: 'outputs'),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'condition'),
        WorkflowConnection(
          fromNodeId: 'condition',
          toNodeId: 'left',
          conditionBranch: .trueBranch,
        ),
        WorkflowConnection(
          fromNodeId: 'condition',
          toNodeId: 'right',
          conditionBranch: .falseBranch,
        ),
        WorkflowConnection(fromNodeId: 'left', toNodeId: 'join'),
        WorkflowConnection(fromNodeId: 'right', toNodeId: 'join'),
        WorkflowConnection(fromNodeId: 'join', toNodeId: 'outputs'),
      ],
    );

    expect(
      WorkflowGraphValidation.availableValueSources(workflow, 'join'),
      contains('inputs'),
    );
    expect(
      WorkflowGraphValidation.availableValueSources(workflow, 'join'),
      isNot(contains('left')),
    );
    expect(
      WorkflowGraphValidation.availableValueSources(workflow, 'join'),
      isNot(contains('right')),
    );
  });

  test('workflow references reject a transitive cycle', () {
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

  test('node-link validation reports the reason a candidate is rejected', () {
    final workflow = _workflow(
      nodes: [
        _node(id: 'inputs', kind: .inputs),
        _node(id: 'condition', kind: .condition),
        _node(id: 'step'),
        _node(id: 'outputs', kind: .outputs),
      ],
      connections: const [
        WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'condition'),
        WorkflowConnection(
          fromNodeId: 'condition',
          toNodeId: 'step',
          conditionBranch: WorkflowConditionBranch.trueBranch,
        ),
        WorkflowConnection(fromNodeId: 'step', toNodeId: 'outputs'),
      ],
    );

    expect(
      WorkflowGraphValidation.connectionRejection(
        workflow,
        sourceNodeId: 'condition',
        targetNodeId: 'step',
        branch: WorkflowConditionBranch.trueBranch,
      ),
      WorkflowConnectionRejection.duplicate,
    );
    expect(
      WorkflowGraphValidation.connectionRejection(
        workflow,
        sourceNodeId: 'condition',
        targetNodeId: 'outputs',
      ),
      WorkflowConnectionRejection.missingConditionBranch,
    );
    expect(
      WorkflowGraphValidation.connectionRejection(
        workflow,
        sourceNodeId: 'step',
        targetNodeId: 'condition',
      ),
      WorkflowConnectionRejection.cycle,
    );
  });

  test('node positions accept signed finite values and reject non-finite', () {
    final workflow = _boundWorkflow();
    final connector = workflow.nodes.firstWhere(
      (node) => node.id == 'connector',
    );
    for (final position in [
      const Offset(-100000, -100000),
      const Offset(100000, 100000),
    ]) {
      final candidate = workflow.copyWith(
        nodes: [
          for (final node in workflow.nodes)
            node.id == connector.id
                ? node.copyWith(x: position.dx, y: position.dy)
                : node,
        ],
      );
      expect(
        WorkflowGraphValidation.validateWorkflowDefinition(candidate),
        isNot(contains(WorkflowGraphIssue.invalidNodePosition)),
      );
    }

    for (final position in [
      const Offset(double.nan, 0),
      const Offset(0, double.infinity),
      const Offset(double.negativeInfinity, 0),
    ]) {
      final candidate = workflow.copyWith(
        nodes: [
          for (final node in workflow.nodes)
            node.id == connector.id
                ? node.copyWith(x: position.dx, y: position.dy)
                : node,
        ],
      );
      expect(
        WorkflowGraphValidation.validateWorkflowDefinition(candidate),
        contains(WorkflowGraphIssue.invalidNodePosition),
      );
    }
  });
}

WorkspaceWorkflow _boundWorkflow({
  WorkflowValueType inputType = .string,
  WorkflowValueType sourceType = .string,
  WorkflowValueType targetType = .string,
  String sourcePointer = '/query',
  bool addInputLink = true,
  List<WorkflowField>? inputFields,
}) {
  final inputs = _node(
    id: 'inputs',
    kind: .inputs,
    targetId: 'inputs',
    outputFields:
        inputFields ??
        [WorkflowField(id: 'query', name: 'query', type: inputType)],
  );
  final connector = _node(
    id: 'connector',
    kind: .connectorTool,
    inputFields: [
      WorkflowField(id: 'prompt', name: 'prompt', type: sourceType),
    ],
    outputFields: [WorkflowField(id: 'text', name: 'text', type: sourceType)],
    inputBindings: {
      'prompt': WorkflowBinding.fromNode(
        sourceNodeId: 'inputs',
        jsonPointer: sourcePointer,
      ),
    },
  );
  final outputs = _node(
    id: 'outputs',
    kind: .outputs,
    targetId: 'outputs',
    inputFields: [
      WorkflowField(id: 'answer', name: 'answer', type: targetType),
    ],
    inputBindings: {
      'answer': const WorkflowBinding.fromNode(
        sourceNodeId: 'connector',
        jsonPointer: '/text',
      ),
    },
  );

  return _workflow(
    nodes: [inputs, connector, outputs],
    connections: [
      if (addInputLink)
        const WorkflowConnection(fromNodeId: 'inputs', toNodeId: 'connector'),
      const WorkflowConnection(fromNodeId: 'connector', toNodeId: 'outputs'),
    ],
  );
}

WorkspaceWorkflow _workflow({
  String id = 'draft',
  List<WorkflowNode> nodes = const [],
  List<WorkflowConnection> connections = const [],
}) => WorkspaceWorkflow.create(
  id: id,
  workspaceId: 'workspace-1',
  name: 'Workflow',
  description: '',
  nodes: nodes,
  connections: connections,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
);

WorkflowNode _node({
  required String id,
  WorkflowNodeKind kind = .connectorTool,
  String? targetId,
  List<WorkflowField> inputFields = const [],
  List<WorkflowField> outputFields = const [],
  Map<String, WorkflowBinding> inputBindings = const {},
  List<WorkflowTransformOutput> transformOutputs = const [],
}) => WorkflowNode(
  id: id,
  kind: kind,
  targetId: targetId ?? id,
  canonicalName: kind.name,
  label: id,
  x: 100,
  y: 100,
  inputFields: inputFields,
  outputFields: outputFields,
  inputBindings: inputBindings,
  transformOutputs: transformOutputs,
);
