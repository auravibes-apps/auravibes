import 'package:auravibes_app/router/draft_exit_guard.dart';

/// Sections bind their own readers; the route sees the union of their drafts.
class WorkspaceSettingsDraftGuards {
  new(this.parent) {
    parent.bind(
      readers: (
        isDirty: () => compaction.isDirty || verification.isDirty,
        isSaving: () => compaction.isSaving || verification.isSaving,
      ),
    );
    compaction.addListener(_changed);
    verification.addListener(_changed);
  }

  final DraftExitGuard parent;
  final compaction = DraftExitGuard();
  final verification = DraftExitGuard();

  void dispose() {
    compaction.removeListener(_changed);
    verification.removeListener(_changed);
    parent.unbind();
    compaction.dispose();
    verification.dispose();
  }

  void _changed() {
    parent.releaseApproval(restoreFocus: false);
    parent.update(
      isDirty: compaction.isDirty || verification.isDirty,
      isSaving: compaction.isSaving || verification.isSaving,
    );
  }
}
