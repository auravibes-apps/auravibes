import 'dart:async';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_mutations.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/usecases/save_workflow_usecase.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_inspector_panel.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_node_picker.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_signature_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class WorkflowEditorScreen extends ConsumerStatefulWidget {
  const new({required this.workspaceId, this.workflowId, super.key});

  final String workspaceId;
  final String? workflowId;

  @override
  ConsumerState<WorkflowEditorScreen> createState() =>
      _WorkflowEditorScreenState();
}

class _WorkflowEditorScreenState extends ConsumerState<WorkflowEditorScreen> {
  final _exitGuard = DraftExitGuard();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _controllerWorkflowKey;
  bool _saving = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _messageController;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorProvider = workflowEditorProvider(
      widget.workspaceId,
      widget.workflowId,
    );
    final editorState = ref.watch(editorProvider);
    final editor = ref.watch(editorProvider.notifier);
    _syncTextFields(editorState.workflow);
    _exitGuard
      ..bind(
        readers: (
          isDirty: () => ref.read(editorProvider).isDirty,
          isSaving: () => _saving,
        ),
        confirm: (_) => UnsavedChangesDialog.confirm(context),
      )
      ..update(isDirty: editorState.isDirty, isSaving: _saving);

    return DraftExitScope(
      guard: _exitGuard,
      child: _WorkflowEditorScaffold(
        workspaceId: widget.workspaceId,
        workflowId: widget.workflowId,
        editorState: editorState,
        editor: editor,
        nameController: _nameController,
        descriptionController: _descriptionController,
        isSaving: _saving,
        onBack: _goBackToWorkflows,
        onSave: () => _save(editorState),
        onNameChanged: editor.setName,
        onDescriptionChanged: editor.setDescription,
        onAddNode: () => unawaited(_openNodePicker()),
      ),
    );
  }

  void _goBackToWorkflows() {
    WorkflowsRoute(workspaceId: widget.workspaceId).go(context);
  }

  void _syncTextFields(WorkflowDefinition? workflow) {
    if (workflow == null) return;
    final key = workflow.id.isEmpty
        ? 'new:${workflow.workspaceId}'
        : workflow.id;
    if (_controllerWorkflowKey == key) return;
    _controllerWorkflowKey = key;
    _nameController.text = workflow.name;
    _descriptionController.text = workflow.description;
  }

  Future<void> _save(WorkflowEditorState editorState) async {
    final workflow = editorState.workflow;
    if (workflow == null || _saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    _exitGuard.update(isDirty: editorState.isDirty, isSaving: true);
    WorkflowDefinition? savedWorkflow;
    Object? saveError;
    try {
      savedWorkflow = await WorkflowMutations.save.run(
        ref,
        (_) => ref
            .read(saveWorkflowUsecaseProvider(widget.workspaceId))
            .call(workflow),
      );
    } on Object catch (error) {
      saveError = error;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _exitGuard.update(
          isDirty: ref
              .read(
                workflowEditorProvider(widget.workspaceId, widget.workflowId),
              )
              .isDirty,
          isSaving: false,
        );
      }
    }
    if (!mounted) return;
    final saved = savedWorkflow;
    if (saved == null) {
      final messageKey = saveError is WorkflowValidationException
          ? LocaleKeys.workflow_editor_validation_error
          : LocaleKeys.workflow_editor_save_error;
      _showMessage(messageKey);

      return;
    }
    ref
        .read(
          workflowEditorProvider(
            widget.workspaceId,
            widget.workflowId,
          ).notifier,
        )
        .markSaved(saved);
    if (widget.workflowId == null) {
      context.go(WorkflowsRoute(workspaceId: widget.workspaceId).location);

      return;
    }
    _showMessage(LocaleKeys.workflow_editor_save_success);
  }

  Future<void> _openNodePicker() async {
    final draft = await showWorkflowNodePicker(
      context: context,
      workspaceId: widget.workspaceId,
      currentWorkflowId: widget.workflowId,
    );
    if (!mounted || draft == null) return;
    ref
        .read(
          workflowEditorProvider(
            widget.workspaceId,
            widget.workflowId,
          ).notifier,
        )
        .addNode(
          kind: draft.kind,
          targetId: draft.targetId,
          targetSource: draft.targetSource,
          label: draft.label,
          defaultInputLabel: LocaleKeys.workflow_editor_input.tr(
            context: context,
          ),
          defaultOutputLabel: LocaleKeys.workflow_editor_result.tr(
            context: context,
          ),
          inputs: draft.inputs,
          outputs: draft.outputs,
        );
  }

  void _showMessage(String messageKey) {
    final current = _messageController;
    if (current != null) current.close();
    _messageController = ScaffoldMessenger.of(context)
        .showSnackBar(.new(content: Text(messageKey.tr(context: context))));
  }
}

class const _WorkflowEditorScaffold({
  required final String workspaceId,
  required final String? workflowId,
  required final WorkflowEditorState editorState,
  required final WorkflowEditorNotifier editor,
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final bool isSaving,
  required final VoidCallback onBack,
  required final VoidCallback onSave,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final VoidCallback onAddNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workflow = editorState.workflow;
    final titleKey = workflowId == null
        ? LocaleKeys.workflow_editor_new_title
        : LocaleKeys.workflow_editor_title;

    return AuraScreen(
      child: ExcludeFocus(
        excluding: isSaving,
        child: AbsorbPointer(
          absorbing: isSaving,
          child: _WorkflowEditorBody(
            workspaceId: workspaceId,
            workflowId: workflowId,
            editorState: editorState,
            editor: editor,
            nameController: nameController,
            descriptionController: descriptionController,
            onNameChanged: onNameChanged,
            onDescriptionChanged: onDescriptionChanged,
            onAddNode: onAddNode,
          ),
        ),
      ),
      appBar: AuraAppBarWithDrawer(
        title: TextLocale(titleKey),
        actions: [
          AuraIconButton(
            icon: Icons.save_outlined,
            onPressed: onSave,
            disabled: isSaving || workflow == null,
            tooltip: LocaleKeys.workflow_editor_save.tr(context: context),
          ),
        ],
        leading: AuraIconButton(icon: Icons.arrow_back, onPressed: onBack),
      ),
    );
  }
}

class const _WorkflowEditorBody({
  required final String workspaceId,
  required final String? workflowId,
  required final WorkflowEditorState editorState,
  required final WorkflowEditorNotifier editor,
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final VoidCallback onAddNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (editorState.isLoading) return const Center(child: AuraSpinner());
    if (editorState.notFound || editorState.loadFailed) {
      return _WorkflowLoadRecovery(
        workspaceId: workspaceId,
        workflowId: workflowId,
        messageKey: editorState.notFound
            ? LocaleKeys.workflow_editor_not_found
            : LocaleKeys.workflow_editor_load_error,
        canRetry: editorState.loadFailed,
      );
    }
    final workflow = editorState.workflow;
    if (workflow == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return Column(
          children: [
            _WorkflowMetadataFields(
              nameController: nameController,
              descriptionController: descriptionController,
              onNameChanged: onNameChanged,
              onDescriptionChanged: onDescriptionChanged,
            ),
            _WorkflowEditorToolbar(
              onAddNode: onAddNode,
              onEditSignature: () =>
                  _openSignatureEditor(context, workspaceId, workflowId),
            ),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _WorkflowCanvasView(
                            workflow: workflow,
                            editorState: editorState,
                            editor: editor,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 340,
                          child: WorkflowInspectorPanel(
                            workflow: workflow,
                            editorState: editorState,
                            editor: editor,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _WorkflowCanvasView(
                            workflow: workflow,
                            editorState: editorState,
                            editor: editor,
                          ),
                        ),
                        if (editorState.selectedNodeId != null)
                          SizedBox(
                            height: 260,
                            child: WorkflowInspectorPanel(
                              workflow: workflow,
                              editorState: editorState,
                              editor: editor,
                            ),
                          ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextLocale(LocaleKeys.workflow_editor_execution_notice),
              ),
            ),
          ],
        );
      },
    );
  }
}

class const _WorkflowMetadataFields({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final nameField = TextField(
          controller: nameController,
          decoration: .new(
            labelText: LocaleKeys.workflow_editor_name.tr(context: context),
            isDense: true,
          ),
          textInputAction: .next,
          onChanged: onNameChanged,
        );
        final descriptionField = TextField(
          controller: descriptionController,
          decoration: .new(
            labelText: LocaleKeys.workflow_editor_description.tr(
              context: context,
            ),
            isDense: true,
          ),
          textInputAction: .done,
          onChanged: onDescriptionChanged,
        );
        if (constraints.maxWidth > 650) {
          return Row(
            children: [
              Expanded(flex: 2, child: nameField),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: descriptionField),
            ],
          );
        }

        return Column(
          children: [nameField, const SizedBox(height: 8), descriptionField],
        );
      },
    ),
  );
}

class const _WorkflowLoadRecovery({
  required final String workspaceId,
  required final String? workflowId,
  required final String messageKey,
  required final bool canRetry,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWorkflowId = workflowId;

    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          TextLocale(messageKey),
          const SizedBox(height: 12),
          if (canRetry && currentWorkflowId != null)
            TextButton(
              onPressed: () => ref.invalidate(
                workflowProvider(workspaceId, currentWorkflowId),
              ),
              child: const TextLocale(LocaleKeys.workflow_editor_retry),
            ),
          TextButton(
            onPressed: () =>
                WorkflowsRoute(workspaceId: workspaceId).go(context),
            child: const TextLocale(LocaleKeys.workflow_editor_back_to_list),
          ),
        ],
      ),
    );
  }
}

class const _WorkflowEditorToolbar({
  required final VoidCallback onAddNode,
  required final VoidCallback onEditSignature,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      children: [
        AuraButton(
          onPressed: onAddNode,
          child: const Row(
            mainAxisSize: .min,
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 4),
              TextLocale(LocaleKeys.workflow_editor_add_node),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onEditSignature,
          icon: const Icon(Icons.input_outlined),
          label: const TextLocale(LocaleKeys.workflow_editor_signature),
        ),
      ],
    ),
  );
}

class const _WorkflowCanvasView({
  required final WorkflowDefinition workflow,
  required final WorkflowEditorState editorState,
  required final WorkflowEditorNotifier editor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkflowCanvas(
    workflow: workflow,
    editorState: editorState,
    onSelectNode: editor.selectNode,
    onMoveNode: editor.moveNode,
    onSelectOutput: editor.selectOutput,
    onSelectInput: editor.selectInput,
  );
}

Future<void> _openSignatureEditor(
  BuildContext context,
  String workspaceId,
  String? workflowId,
) => showModalBottomSheet<void>(
  context: context,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: _WorkflowSignatureSheet(
          workspaceId: workspaceId,
          workflowId: workflowId,
        ),
      ),
    ),
  ),
  isScrollControlled: true,
);

class const _WorkflowSignatureSheet({
  required final String workspaceId,
  required final String? workflowId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider(workspaceId, workflowId));
    final workflow = state.workflow;
    if (workflow == null) return const SizedBox.shrink();

    return WorkflowSignatureEditor(
      workflow: workflow,
      editor: ref.watch(
        workflowEditorProvider(workspaceId, workflowId).notifier,
      ),
    );
  }
}
