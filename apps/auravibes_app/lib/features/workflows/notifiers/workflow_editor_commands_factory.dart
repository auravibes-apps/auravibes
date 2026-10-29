import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_metadata_reducer.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/models/workflow_node_draft.dart';

typedef _WorkflowEditorStateUpdate = void Function(
  WorkflowEditorState Function(WorkflowEditorState) update,
);

typedef WorkflowEditorMetadataCommands = ({
  void Function(String name) setName,
  void Function(String description) setDescription,
});

typedef WorkflowEditorCommands = ({
  WorkflowEditorMetadataCommands metadata,
  WorkflowEditorNodeCommands nodes,
  WorkflowEditorConnectionCommands connections,
  WorkflowEditorPortCommands ports,
});

typedef WorkflowEditorNodeCommands = ({
  void Function(WorkflowNodeDraft draft) add,
  void Function(String nodeId) select,
  void Function() clearSelection,
  void Function(String nodeId, double x, double y) move,
  void Function(String nodeId, String label) setLabel,
  void Function(String nodeId, List<WorkflowPort> outputs) inferOutputs,
  void Function(String nodeId) remove,
});

typedef WorkflowEditorConnectionCommands = ({
  void Function(String? nodeId, String portId) selectOutput,
  void Function(String? nodeId, String portId) selectInput,
  void Function(WorkflowConnection connection) remove,
});

typedef WorkflowEditorPortCommands = ({
  WorkflowPortAdder addWorkflow,
  WorkflowPortUpdater updateWorkflow,
  WorkflowPortRemover removeWorkflow,
  WorkflowNodePortAdder addNode,
  WorkflowNodePortUpdater updateNode,
  WorkflowNodePortRemover removeNode,
});

typedef WorkflowPortAdder = String Function({
  required bool isInput,
  required String name,
});
typedef WorkflowPortUpdater = void Function({
  required bool isInput,
  required String portId,
  required WorkflowPort port,
});
typedef WorkflowPortRemover = void Function({
  required bool isInput,
  required String portId,
});
typedef WorkflowNodePortAdder = String Function({
  required String nodeId,
  required bool isInput,
  required String name,
});
typedef WorkflowNodePortUpdater = void Function({
  required String nodeId,
  required bool isInput,
  required String portId,
  required WorkflowPort port,
});
typedef WorkflowNodePortRemover = void Function({
  required String nodeId,
  required bool isInput,
  required String portId,
});

abstract final class WorkflowEditorCommandsFactory {
  static WorkflowEditorCommands create(_WorkflowEditorStateUpdate update) => (
    metadata: WorkflowEditorMetadataCommandFactory.create(update),
    nodes: WorkflowEditorNodeCommandFactory.create(update),
    connections: WorkflowEditorConnectionCommandFactory.create(update),
    ports: WorkflowEditorPortCommandFactory.create(update),
  );
}

abstract final class WorkflowEditorMetadataCommandFactory {
  static WorkflowEditorMetadataCommands create(
    _WorkflowEditorStateUpdate update,
  ) => (setName: _setName(update), setDescription: _setDescription(update));

  static void Function(String) _setName(_WorkflowEditorStateUpdate update) =>
      (name) =>
          update((state) => WorkflowEditorMetadataReducer.setName(state, name));

  static void Function(String) _setDescription(
    _WorkflowEditorStateUpdate update,
  ) =>
      (description) => update(
        (state) =>
            WorkflowEditorMetadataReducer.setDescription(state, description),
      );
}

abstract final class WorkflowEditorNodeCommandFactory {
  static WorkflowEditorNodeCommands create(_WorkflowEditorStateUpdate update) =>
      (
        add: _add(update),
        select: _select(update),
        clearSelection: _clearSelection(update),
        move: _move(update),
        setLabel: _setLabel(update),
        inferOutputs: _inferOutputs(update),
        remove: _remove(update),
      );

  static void Function(WorkflowNodeDraft) _add(
    _WorkflowEditorStateUpdate update,
  ) =>
      (draft) => update((state) => WorkflowEditorNodeReducer.add(state, draft));

  static void Function(String) _select(_WorkflowEditorStateUpdate update) =>
      (nodeId) =>
          update((state) => WorkflowEditorNodeReducer.select(state, nodeId));

  static void Function() _clearSelection(_WorkflowEditorStateUpdate update) =>
      () => update(WorkflowEditorNodeReducer.clearSelection);

  static void Function(String, double, double) _move(
    _WorkflowEditorStateUpdate update,
  ) =>
      (nodeId, x, y) => update(
        (state) => WorkflowEditorNodeReducer.move(state, nodeId, x, y),
      );

  static void Function(String, String) _setLabel(
    _WorkflowEditorStateUpdate update,
  ) =>
      (nodeId, label) => update(
        (state) => WorkflowEditorNodeReducer.setLabel(state, nodeId, label),
      );

  static void Function(String, List<WorkflowPort>) _inferOutputs(
    _WorkflowEditorStateUpdate update,
  ) =>
      (nodeId, outputs) => update(
        (state) =>
            WorkflowEditorNodeReducer.inferOutputs(state, nodeId, outputs),
      );

  static void Function(String) _remove(_WorkflowEditorStateUpdate update) =>
      (nodeId) =>
          update((state) => WorkflowEditorNodeReducer.remove(state, nodeId));
}

abstract final class WorkflowEditorConnectionCommandFactory {
  static WorkflowEditorConnectionCommands create(
    _WorkflowEditorStateUpdate update,
  ) => (
    selectOutput: _selectOutput(update),
    selectInput: _selectInput(update),
    remove: _remove(update),
  );

  static void Function(String?, String) _selectOutput(
    _WorkflowEditorStateUpdate update,
  ) =>
      (nodeId, portId) => update(
        (state) =>
            WorkflowEditorConnectionReducer.selectOutput(state, nodeId, portId),
      );

  static void Function(String?, String) _selectInput(
    _WorkflowEditorStateUpdate update,
  ) =>
      (nodeId, portId) => update(
        (state) =>
            WorkflowEditorConnectionReducer.selectInput(state, nodeId, portId),
      );

  static void Function(WorkflowConnection) _remove(
    _WorkflowEditorStateUpdate update,
  ) =>
      (connection) => update(
        (state) => WorkflowEditorConnectionReducer.remove(state, connection),
      );
}

abstract final class WorkflowEditorPortCommandFactory {
  static WorkflowEditorPortCommands create(_WorkflowEditorStateUpdate update) =>
      (
        addWorkflow: _addWorkflow(update),
        updateWorkflow: _updateWorkflow(update),
        removeWorkflow: _removeWorkflow(update),
        addNode: _addNode(update),
        updateNode: _updateNode(update),
        removeNode: _removeNode(update),
      );

  static WorkflowPortAdder _addWorkflow(_WorkflowEditorStateUpdate update) =>
      ({required isInput, required name}) {
        return _addWorkflowPort(update, isInput: isInput, name: name);
      };

  static String _addWorkflowPort(
    _WorkflowEditorStateUpdate update, {
    required bool isInput,
    required String name,
  }) {
    final id = WorkflowEditorPortFactory.newId();
    update(
      (state) => WorkflowEditorBoundaryPortReducer.addWorkflow(
        state,
        draft: (id: id, isInput: isInput, name: name),
      ),
    );

    return id;
  }

  static WorkflowPortUpdater _updateWorkflow(
    _WorkflowEditorStateUpdate update,
  ) =>
      ({required isInput, required portId, required port}) => update(
        (state) => WorkflowEditorBoundaryPortReducer.updateWorkflow(
          state,
          update: (isInput: isInput, portId: portId, port: port),
        ),
      );

  static WorkflowPortRemover _removeWorkflow(
    _WorkflowEditorStateUpdate update,
  ) =>
      ({required isInput, required portId}) => update(
        (state) => WorkflowEditorBoundaryPortReducer.removeWorkflow(
          state,
          removal: (isInput: isInput, portId: portId),
        ),
      );

  static WorkflowNodePortAdder _addNode(_WorkflowEditorStateUpdate update) =>
      ({required nodeId, required isInput, required name}) {
        return _addNodePort(
          update,
          nodeId: nodeId,
          isInput: isInput,
          name: name,
        );
      };

  static String _addNodePort(
    _WorkflowEditorStateUpdate update, {
    required String nodeId,
    required bool isInput,
    required String name,
  }) {
    final id = WorkflowEditorPortFactory.newId();
    update(
      (state) => WorkflowEditorNodePortReducer.addNode(
        state,
        draft: (id: id, nodeId: nodeId, isInput: isInput, name: name),
      ),
    );

    return id;
  }

  static WorkflowNodePortUpdater _updateNode(
    _WorkflowEditorStateUpdate update,
  ) =>
      ({required nodeId, required isInput, required portId, required port}) =>
          _updateNodePort(update, (
            nodeId: nodeId,
            isInput: isInput,
            portId: portId,
            port: port,
          ));

  static void _updateNodePort(
    _WorkflowEditorStateUpdate update,
    WorkflowNodePortUpdate portUpdate,
  ) => update(
    (state) =>
        WorkflowEditorNodePortReducer.updateNode(state, update: portUpdate),
  );

  static WorkflowNodePortRemover _removeNode(
    _WorkflowEditorStateUpdate update,
  ) =>
      ({required nodeId, required isInput, required portId}) => update(
        (state) => WorkflowEditorNodePortReducer.removeNode(
          state,
          removal: (nodeId: nodeId, isInput: isInput, portId: portId),
        ),
      );
}
