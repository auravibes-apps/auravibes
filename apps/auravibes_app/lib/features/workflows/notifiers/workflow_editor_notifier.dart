import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_metadata_reducer.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_commands_factory.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:auravibes_app/features/workflows/notifiers/workflow_editor_commands_factory.dart';

part 'workflow_editor_notifier.g.dart';

@riverpod
class WorkflowEditorNotifier extends _$WorkflowEditorNotifier {
  @override
  WorkflowEditorState build(String workspaceId, String? workflowId) {
    if (workflowId == null) return WorkflowEditorState.newWorkflow(workspaceId);
    final loaded = ref.watch(workflowProvider(workspaceId, workflowId));

    return switch (loaded) {
      AsyncData(:final value) =>
        value == null
            ? WorkflowEditorState.missing()
            : WorkflowEditorState(
                workflow: value,
                selectedNodeId: value.nodes
                    .where((node) => node.kind == .inputs)
                    .firstOrNull
                    ?.id,
              ),
      AsyncError() => WorkflowEditorState.loadFailed(),
      AsyncLoading() => WorkflowEditorState.loading(),
    };
  }

  WorkflowEditorCommands commands() =>
      WorkflowEditorCommandsFactory.create(_changeState);

  void markSaved(WorkspaceWorkflow workflow) => _changeState(
    (current) => WorkflowEditorStateReducer.markSaved(current, workflow),
  );

  void _changeState(WorkflowEditorState Function(WorkflowEditorState) update) {
    state = update(state);
  }
}
