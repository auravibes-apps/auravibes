import 'package:auravibes_app/features/workspaces/models/workspace_creation_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_creation_draft_notifier.g.dart';

@riverpod
class WorkspaceCreationDraftNotifier extends _$WorkspaceCreationDraftNotifier {
  @override
  WorkspaceCreationDraft build(String taskId) => const WorkspaceCreationDraft();

  void update({String? name, String? target, WorkspaceCreationIntent? intent}) {
    state = WorkspaceCreationDraft(
      name: name ?? state.name,
      target: target ?? state.target,
      intent: intent ?? state.intent,
    );
  }
}
