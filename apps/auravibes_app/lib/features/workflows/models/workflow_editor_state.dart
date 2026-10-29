import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';

typedef WorkflowPendingOutput = ({String? nodeId, String portId});
typedef _WorkflowWorkflowCopy = ({
  WorkspaceWorkflow? workflow,
  String? initialSnapshot,
  bool resetInitialSnapshot,
  bool clearWorkflow,
});
typedef _WorkflowSelectionCopy = ({
  String? selectedNodeId,
  bool clearSelectedNode,
  WorkflowPendingOutput? pendingOutput,
  bool clearPendingOutput,
});
typedef _WorkflowLoadingCopy = ({
  bool? isLoading,
  bool? notFound,
  bool? loadFailed,
});
typedef _WorkflowEditorStateCopy = ({
  _WorkflowWorkflowCopy workflow,
  _WorkflowSelectionCopy selection,
  _WorkflowLoadingCopy loading,
});
typedef _WorkflowAndSnapshot = ({
  WorkspaceWorkflow? workflow,
  String? initialSnapshot,
});
typedef _WorkflowSelection = ({
  String? selectedNodeId,
  WorkflowPendingOutput? pendingOutput,
});
typedef _WorkflowLoadingState = ({
  bool isLoading,
  bool notFound,
  bool loadFailed,
});

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
      workflow: WorkspaceWorkflow.create(
        id: '',
        workspaceId: workspaceId,
        name: '',
        description: '',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  factory loading() => WorkflowEditorState(workflow: null, isLoading: true);

  factory loadFailed() => WorkflowEditorState(workflow: null, loadFailed: true);

  factory missing() => WorkflowEditorState(workflow: null, notFound: true);

  final WorkspaceWorkflow? workflow;
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

  WorkflowEditorState withWorkflow(WorkspaceWorkflow value) =>
      copyWith(workflow: value);

  WorkflowEditorState withSelection(String nodeId) =>
      copyWith(selectedNodeId: nodeId, clearPendingOutput: true);

  WorkflowEditorState withoutSelection() =>
      copyWith(clearSelectedNode: true, clearPendingOutput: true);

  WorkflowEditorState copyWith({
    WorkspaceWorkflow? workflow,
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
  }) => WorkflowEditorStateValues.copy(this, (
    workflow: (
      workflow: workflow,
      initialSnapshot: initialSnapshot,
      resetInitialSnapshot: resetInitialSnapshot,
      clearWorkflow: clearWorkflow,
    ),
    selection: (
      selectedNodeId: selectedNodeId,
      clearSelectedNode: clearSelectedNode,
      pendingOutput: pendingOutput,
      clearPendingOutput: clearPendingOutput,
    ),
    loading: (isLoading: isLoading, notFound: notFound, loadFailed: loadFailed),
  ));
}

abstract final class WorkflowEditorStateValues {
  static WorkflowEditorState copy(
    WorkflowEditorState current,
    _WorkflowEditorStateCopy update,
  ) => _create(
    workflowAndSnapshot: _workflowAndSnapshot(current, update.workflow),
    selection: _selection(current, update.selection),
    loading: _loading(current, update.loading),
  );

  static WorkflowEditorState _create({
    required _WorkflowAndSnapshot workflowAndSnapshot,
    required _WorkflowSelection selection,
    required _WorkflowLoadingState loading,
  }) => WorkflowEditorState(
    workflow: workflowAndSnapshot.workflow,
    initialSnapshot: workflowAndSnapshot.initialSnapshot,
    selectedNodeId: selection.selectedNodeId,
    pendingOutput: selection.pendingOutput,
    isLoading: loading.isLoading,
    notFound: loading.notFound,
    loadFailed: loading.loadFailed,
  );

  static _WorkflowAndSnapshot _workflowAndSnapshot(
    WorkflowEditorState current,
    _WorkflowWorkflowCopy update,
  ) => (
    workflow: _workflow(
      value: update.workflow,
      current: current.workflow,
      clear: update.clearWorkflow,
    ),
    initialSnapshot: _initialSnapshot(
      value: update.initialSnapshot,
      current: current.initialSnapshot,
      workflow: update.workflow ?? current.workflow,
      reset: update.resetInitialSnapshot,
    ),
  );

  static _WorkflowSelection _selection(
    WorkflowEditorState current,
    _WorkflowSelectionCopy update,
  ) => (
    selectedNodeId: _value(
      value: update.selectedNodeId,
      current: current.selectedNodeId,
      clear: update.clearSelectedNode,
    ),
    pendingOutput: _value(
      value: update.pendingOutput,
      current: current.pendingOutput,
      clear: update.clearPendingOutput,
    ),
  );

  static _WorkflowLoadingState _loading(
    WorkflowEditorState current,
    _WorkflowLoadingCopy update,
  ) => (
    isLoading: _flag(value: update.isLoading, current: current.isLoading),
    notFound: _flag(value: update.notFound, current: current.notFound),
    loadFailed: _flag(value: update.loadFailed, current: current.loadFailed),
  );

  static bool _flag({required bool? value, required bool current}) =>
      value ?? current;

  static WorkspaceWorkflow? _workflow({
    required WorkspaceWorkflow? value,
    required WorkspaceWorkflow? current,
    required bool clear,
  }) => clear ? null : value ?? current;

  static String? _initialSnapshot({
    required String? value,
    required String? current,
    required WorkspaceWorkflow? workflow,
    required bool reset,
  }) => reset ? workflow?.encode() : value ?? current;

  static T? _value<T>({
    required T? value,
    required T? current,
    bool clear = false,
  }) => clear ? null : value ?? current;
}
