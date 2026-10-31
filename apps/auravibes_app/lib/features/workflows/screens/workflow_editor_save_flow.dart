import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_mutations.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/usecases/save_workflow_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef WorkflowEditorSaveRequest = ({
  WidgetRef ref,
  BuildContext context,
  String workspaceId,
  String? workflowId,
  WorkflowEditorState editorState,
  DraftExitGuard exitGuard,
  void Function({required bool saving}) setSaving,
  void Function(String messageKey) showMessage,
});

typedef _SaveOutcome = ({WorkspaceWorkflow? workflow, Object? error});

abstract final class WorkflowEditorSaveFlow {
  static Future<void> save(WorkflowEditorSaveRequest request) async {
    final workflow = request.editorState.workflow;
    if (workflow == null) return;

    _beginSave(request);
    final outcome = await _persist(request, workflow);
    if (!request.context.mounted) return;
    _finishSave(request, outcome);
  }

  static void _beginSave(WorkflowEditorSaveRequest request) {
    FocusManager.instance.primaryFocus?.unfocus();
    request.setSaving(saving: true);
    request.exitGuard.update(
      isDirty: request.editorState.isDirty,
      isSaving: true,
    );
  }

  static void _finishSave(
    WorkflowEditorSaveRequest request,
    _SaveOutcome outcome,
  ) {
    final saved = outcome.workflow;
    if (saved == null) {
      request.showMessage(_failureMessage(outcome.error));

      return;
    }
    _markSaved(request, saved);
  }

  static Future<_SaveOutcome> _persist(
    WorkflowEditorSaveRequest request,
    WorkspaceWorkflow workflow,
  ) async {
    try {
      final saved = await _runMutation(request, workflow);

      return (workflow: saved, error: null);
    } on Object catch (cause) {
      return (workflow: null, error: cause);
    } finally {
      _finishSaving(request);
    }
  }

  static Future<WorkspaceWorkflow> _runMutation(
    WorkflowEditorSaveRequest request,
    WorkspaceWorkflow workflow,
  ) => WorkflowMutations.save.run(
    request.ref,
    (_) => request.ref
        .read(saveWorkflowUsecaseProvider(request.workspaceId))
        .call(workflow),
  );

  static void _finishSaving(WorkflowEditorSaveRequest request) {
    if (!request.context.mounted) return;
    request.setSaving(saving: false);
    request.exitGuard.update(
      isDirty: request.ref
          .read(workflowEditorProvider(request.workspaceId, request.workflowId))
          .isDirty,
      isSaving: false,
    );
  }

  static String _failureMessage(Object? error) => switch (error) {
    final WorkflowValidationException validation => validation.messageKeyOr(
      LocaleKeys.workflow_editor_save_error,
    ),
    _ => LocaleKeys.workflow_editor_save_error,
  };

  static void _markSaved(
    WorkflowEditorSaveRequest request,
    WorkspaceWorkflow workflow,
  ) {
    request.ref
        .read(
          workflowEditorProvider(
            request.workspaceId,
            request.workflowId,
          ).notifier,
        )
        .markSaved(workflow);
    request.showMessage(LocaleKeys.workflow_editor_save_success);
  }
}
