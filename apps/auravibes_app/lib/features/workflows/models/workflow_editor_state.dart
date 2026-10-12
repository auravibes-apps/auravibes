import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

typedef WorkflowPendingOutput = ({String? nodeId, String portId});

class WorkflowEditorState {
  new({
    required this.workflow,
    String? initialSnapshot,
    this.selectedNodeId,
    this.pendingOutput,
    this.isLoading = false,
    this.notFound = false,
    this.loadFailed = false,
  }) : initialSnapshot = initialSnapshot ?? workflow?.encode();

  factory newWorkflow(String workspaceId) {
    final now = DateTime.now().toUtc();

    return WorkflowEditorState(
      workflow: .new(
        id: '',
        workspaceId: workspaceId,
        name: '',
        description: '',
        inputs: const [],
        outputs: const [],
        nodes: const [],
        connections: const [],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  factory loading() => WorkflowEditorState(workflow: null, isLoading: true);

  factory loadFailed() => WorkflowEditorState(workflow: null, loadFailed: true);

  factory missing() => WorkflowEditorState(workflow: null, notFound: true);

  final WorkflowDefinition? workflow;
  final String? initialSnapshot;
  final String? selectedNodeId;
  final WorkflowPendingOutput? pendingOutput;
  final bool isLoading;
  final bool notFound;
  final bool loadFailed;

  bool get isDirty {
    final currentWorkflow = workflow;

    return currentWorkflow != null &&
        currentWorkflow.encode() != initialSnapshot;
  }

  WorkflowEditorState copyWith({
    WorkflowDefinition? workflow,
    String? initialSnapshot,
    bool resetInitialSnapshot = false,
    bool clearWorkflow = false,
    String? selectedNodeId,
    bool clearSelectedNode = false,
    WorkflowPendingOutput? pendingOutput,
    bool clearPendingOutput = false,
    bool? isLoading,
    bool? notFound,
    bool? loadFailed,
  }) => WorkflowEditorState(
    workflow: clearWorkflow ? null : workflow ?? this.workflow,
    initialSnapshot: resetInitialSnapshot
        ? (workflow ?? this.workflow)?.encode()
        : initialSnapshot ?? this.initialSnapshot,
    selectedNodeId: clearSelectedNode
        ? null
        : selectedNodeId ?? this.selectedNodeId,
    pendingOutput: clearPendingOutput
        ? null
        : pendingOutput ?? this.pendingOutput,
    isLoading: isLoading ?? this.isLoading,
    notFound: notFound ?? this.notFound,
    loadFailed: loadFailed ?? this.loadFailed,
  );
}
