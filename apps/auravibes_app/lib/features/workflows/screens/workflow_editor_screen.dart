import 'dart:async';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/screens/workflow_editor_save_flow.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_canvas.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_inspector_panel.dart';
import 'package:auravibes_app/features/workflows/widgets/workflow_node_picker.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _WorkflowEditorIdentity = ({
  String workspaceId,
  String? workflowId,
  bool compact,
  VoidCallback onBack,
});
typedef _WorkflowEditorDocument = ({
  WorkflowEditorState state,
  WorkflowEditorNotifier editor,
  WorkflowEditorCommands commands,
});
typedef _WorkflowEditorSource = ({
  WorkflowEditorState state,
  WorkflowEditorNotifier editor,
});
typedef _WorkflowEditorMetadata = ({
  TextEditingController nameController,
  TextEditingController descriptionController,
  ValueChanged<String> onNameChanged,
  ValueChanged<String> onDescriptionChanged,
});
typedef _WorkflowEditorActions = ({
  VoidCallback onBack,
  VoidCallback onSave,
  VoidCallback onAddNode,
  void Function(String sourceNodeId, WorkflowConditionBranch? branch)
  onAddNodeAfter,
});
typedef _WorkflowEditorPresentation = ({
  DraftExitGuard guard,
  _WorkflowEditorIdentity identity,
  _WorkflowEditorDocument document,
  _WorkflowEditorMetadata metadata,
  bool isSaving,
  _WorkflowEditorActions actions,
});

class WorkflowEditorScreen extends ConsumerStatefulWidget {
  const new({
    required this.workspaceId,
    this.workflowId,
    this.compact = false,
    this.onBack,
    super.key,
  });

  final String workspaceId;
  final String? workflowId;
  final bool compact;
  final VoidCallback? onBack;

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
  VoidCallback? _closeMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _watchEditorSource();
    _syncTextFields(source.state.workflow);
    _bindExitGuard(source.state);

    return _WorkflowEditorPage(
      presentation: _WorkflowEditorPresentationFactory.create(
        screen: this,
        context: context,
        state: source.state,
        editor: source.editor,
      ),
    );
  }

  _WorkflowEditorSource _watchEditorSource() {
    final provider = workflowEditorProvider(
      widget.workspaceId,
      widget.workflowId,
    );

    return (state: ref.watch(provider), editor: ref.watch(provider.notifier));
  }

  void _bindExitGuard(WorkflowEditorState editorState) {
    _WorkflowEditorExitGuardBinder.bind(
      guard: _exitGuard,
      state: editorState,
      isDirty: () => ref
          .read(workflowEditorProvider(widget.workspaceId, widget.workflowId))
          .isDirty,
      isSaving: () => _saving,
    );
  }

  void _goBack(BuildContext context) {
    final onBack = widget.onBack;
    if (onBack == null) {
      Navigator.of(context).maybePop();

      return;
    }
    unawaited(_guardedBack(context, onBack));
  }

  void _backFromInspector(BuildContext context) {
    final provider = workflowEditorProvider(
      widget.workspaceId,
      widget.workflowId,
    );
    if (ref.read(provider).selectedNodeId != null) {
      ref.read(provider.notifier).commands().nodes.clearSelection();

      return;
    }
    _goBack(context);
  }

  Future<void> _guardedBack(BuildContext context, VoidCallback onBack) async {
    if (!await _exitGuard.canExit(context) || !context.mounted) return;
    onBack();
  }

  void _syncTextFields(WorkspaceWorkflow? workflow) {
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
    if (_saving || editorState.workflow?.canManage != true) return;
    await WorkflowEditorSaveFlow.save(_saveRequest(editorState));
  }

  WorkflowEditorSaveRequest _saveRequest(WorkflowEditorState editorState) => (
    ref: ref,
    context: context,
    workspaceId: widget.workspaceId,
    workflowId: widget.workflowId,
    editorState: editorState,
    exitGuard: _exitGuard,
    setSaving: ({required saving}) {
      if (!mounted) return;
      setState(() => _saving = saving);
    },
    showMessage: _showMessage,
  );

  Future<void> _openNodePicker({
    String? sourceNodeId,
    WorkflowConditionBranch? conditionBranch,
  }) async {
    if (ref
            .read(workflowEditorProvider(widget.workspaceId, widget.workflowId))
            .workflow
            ?.canManage !=
        true) {
      return;
    }
    final draft = await WorkflowNodePicker.show(
      context: context,
      workspaceId: widget.workspaceId,
      currentWorkflowId: widget.workflowId,
      sourceNodeId: sourceNodeId,
      conditionBranch: conditionBranch,
    );
    if (!mounted || draft == null) return;
    final editor = ref.read(
      workflowEditorProvider(widget.workspaceId, widget.workflowId).notifier,
    );
    editor.commands().nodes.add(draft);
  }

  void _showMessage(String messageKey) {
    _closeMessage?.call();
    final controller = AuraSnackBars.show(
      context: context,
      content: Text(messageKey.tr(context: context)),
    );
    _closeMessage = controller.close;
  }
}

abstract final class _WorkflowEditorPresentationFactory {
  static _WorkflowEditorPresentation create({
    required _WorkflowEditorScreenState screen,
    required BuildContext context,
    required WorkflowEditorState state,
    required WorkflowEditorNotifier editor,
  }) {
    final identity = _identity(screen, context);
    final document = _document(state, editor);

    return (
      guard: screen._exitGuard,
      identity: identity,
      document: document,
      metadata: _metadata(screen, document),
      isSaving: screen._saving,
      actions: _actions(screen, context, state),
    );
  }

  static _WorkflowEditorIdentity _identity(
    _WorkflowEditorScreenState screen,
    BuildContext context,
  ) => (
    workspaceId: screen.widget.workspaceId,
    workflowId: screen.widget.workflowId,
    compact: screen.widget.compact,
    onBack: () => screen._goBack(context),
  );

  static _WorkflowEditorDocument _document(
    WorkflowEditorState state,
    WorkflowEditorNotifier editor,
  ) => (state: state, editor: editor, commands: editor.commands());

  static _WorkflowEditorMetadata _metadata(
    _WorkflowEditorScreenState screen,
    _WorkflowEditorDocument document,
  ) => (
    nameController: screen._nameController,
    descriptionController: screen._descriptionController,
    onNameChanged: document.commands.metadata.setName,
    onDescriptionChanged: document.commands.metadata.setDescription,
  );

  static _WorkflowEditorActions _actions(
    _WorkflowEditorScreenState screen,
    BuildContext context,
    WorkflowEditorState state,
  ) => (
    onBack: () => screen._backFromInspector(context),
    onSave: () => screen._save(state),
    onAddNode: () => unawaited(screen._openNodePicker()),
    onAddNodeAfter: (sourceNodeId, branch) => unawaited(
      screen._openNodePicker(
        sourceNodeId: sourceNodeId,
        conditionBranch: branch,
      ),
    ),
  );
}

abstract final class _WorkflowEditorExitGuardBinder {
  static void bind({
    required DraftExitGuard guard,
    required WorkflowEditorState state,
    required bool Function() isDirty,
    required bool Function() isSaving,
  }) {
    guard
      ..bind(
        readers: (isDirty: isDirty, isSaving: isSaving),
        callbacks: const .new(confirm: UnsavedChangesDialog.confirm),
      )
      ..update(isDirty: state.isDirty, isSaving: isSaving());
  }
}

class const _WorkflowEditorPage({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasSelectedNode = presentation.document.state.selectedNodeId != null;
    return DraftExitScope(
      guard: presentation.guard,
      onBack: presentation.actions.onBack,
      child: PopScope<Object?>(
        canPop: !hasSelectedNode,
        child: presentation.identity.compact
            ? _WorkflowCompactScaffold(presentation: presentation)
            : _WorkflowEditorScaffold(presentation: presentation),
      ),
    );
  }
}

class const _WorkflowCompactScaffold({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          AuraIconButton(
            icon: Icons.close,
            onPressed: presentation.actions.onBack,
            tooltip: LocaleKeys.common_close.tr(),
          ),
          Expanded(
            child: _WorkflowEditorTitle(
              workflowId: presentation.identity.workflowId,
            ),
          ),
          _WorkflowSaveAction(presentation: presentation),
        ],
      ),
      Expanded(child: _WorkflowEditorScaffoldBody(presentation: presentation)),
    ],
  );
}

class const _WorkflowEditorScaffold({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _WorkflowEditorScaffoldBody(presentation: presentation),
    appBar: _WorkflowEditorAppBar(presentation: presentation),
  );
}

class const _WorkflowEditorScaffoldBody({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExcludeFocus(
    excluding: presentation.isSaving,
    child: AbsorbPointer(
      absorbing: presentation.isSaving,
      child: _WorkflowEditorBody(presentation: presentation),
    ),
  );
}

class const _WorkflowEditorAppBar({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: _WorkflowEditorTitle(workflowId: presentation.identity.workflowId),
    actions: [_WorkflowSaveAction(presentation: presentation)],
    leading: _WorkflowBackAction(onPressed: presentation.actions.onBack),
  );
}

class const _WorkflowEditorTitle({required final String? workflowId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    workflowId == null
        ? LocaleKeys.workflow_editor_new_title
        : LocaleKeys.workflow_editor_title,
  );
}

class const _WorkflowSaveAction({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.save_outlined,
    onPressed: presentation.actions.onSave,
    disabled:
        presentation.isSaving ||
        presentation.document.state.workflow?.canManage != true,
    tooltip: LocaleKeys.workflow_editor_save.tr(context: context),
  );
}

class const _WorkflowBackAction({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraIconButton(icon: Icons.arrow_back, onPressed: onPressed);
}

class const _WorkflowEditorBody({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => presentation.document.state.isLoading
      ? const Center(child: AuraSpinner())
      : _WorkflowEditorLoadedContent(presentation: presentation);
}

class const _WorkflowEditorLoadedContent({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = presentation.document.state;
    if (state.notFound) {
      return _WorkflowNotFoundRecovery(identity: presentation.identity);
    }
    if (state.loadFailed) {
      return _WorkflowLoadFailedRecovery(identity: presentation.identity);
    }

    return _WorkflowEditorLoadedWorkflow(
      presentation: presentation,
      state: state,
    );
  }
}

class const _WorkflowNotFoundRecovery({
  required final _WorkflowEditorIdentity identity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLoadRecovery(
    workspaceId: identity.workspaceId,
    workflowId: identity.workflowId,
    messageKey: LocaleKeys.workflow_editor_not_found,
    canRetry: false,
    onBack: identity.onBack,
  );
}

class const _WorkflowLoadFailedRecovery({
  required final _WorkflowEditorIdentity identity,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowLoadRecovery(
    workspaceId: identity.workspaceId,
    workflowId: identity.workflowId,
    messageKey: LocaleKeys.workflow_editor_load_error,
    canRetry: true,
    onBack: identity.onBack,
  );
}

class const _WorkflowEditorLoadedWorkflow({
  required final _WorkflowEditorPresentation presentation,
  required final WorkflowEditorState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workflow = state.workflow;
    if (workflow == null) return const SizedBox.shrink();

    return _WorkflowEditorReadyView(
      presentation: presentation,
      workflow: workflow,
    );
  }
}

class const _WorkflowEditorReadyView({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape):
          presentation.document.commands.nodes.clearSelection,
    },
    child: Column(
      children: [
        _WorkflowEditorMetadataSection(presentation: presentation),
        if (!workflow.canManage) const _WorkflowReadOnlyNotice(),
        _WorkflowEditorToolbarSection(presentation: presentation),
        Expanded(
          child: _WorkflowEditorResponsiveSection(
            presentation: presentation,
            workflow: workflow,
          ),
        ),
        const _WorkflowExecutionNotice(),
      ],
    ),
  );
}

class const _WorkflowEditorMetadataSection({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final metadata = presentation.metadata;

    return _WorkflowMetadataFields(
      nameController: metadata.nameController,
      descriptionController: metadata.descriptionController,
      onNameChanged: metadata.onNameChanged,
      onDescriptionChanged: metadata.onDescriptionChanged,
      readOnly: presentation.document.state.workflow?.canManage != true,
    );
  }
}

class const _WorkflowEditorToolbarSection({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      presentation.document.state.workflow?.canManage == true
      ? _WorkflowEditorToolbar(onAddNode: presentation.actions.onAddNode)
      : const SizedBox.shrink();
}

class const _WorkflowEditorResponsiveSection({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _WorkflowResponsiveEditor(presentation: presentation, workflow: workflow);
}

class const _WorkflowResponsiveEditor({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  static const _wideLayoutBreakpoint = 980.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _WorkflowEditorLayout(
      presentation: presentation,
      workflow: workflow,
      isWide: constraints.maxWidth >= _wideLayoutBreakpoint,
    ),
  );
}

class const _WorkflowEditorLayout({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
  required final bool isWide,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isWide
      ? _WorkflowWideEditor(presentation: presentation, workflow: workflow)
      : _WorkflowCompactEditor(presentation: presentation, workflow: workflow);
}

class const _WorkflowWideEditor({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  static const _inspectorWidth = 340.0;

  @override
  Widget build(BuildContext context) {
    final document = presentation.document;

    return Row(
      children: [
        Expanded(
          child: _WorkflowCanvasView(
            presentation: presentation,
            workflow: workflow,
          ),
        ),
        const AuraDivider.vertical(thickness: 1),
        SizedBox(
          width: _inspectorWidth,
          child: WorkflowInspectorPanel(
            workflow: workflow,
            editorState: document.state,
            editor: document.editor,
            canEdit: workflow.canManage,
            isWide: true,
          ),
        ),
      ],
    );
  }
}

class const _WorkflowCompactEditor({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  static const _inspectorHeight = 260.0;

  @override
  Widget build(BuildContext context) {
    final document = presentation.document;

    return Column(
      children: [
        Expanded(
          child: _WorkflowCanvasView(
            presentation: presentation,
            workflow: workflow,
          ),
        ),
        if (document.state.selectedNodeId != null)
          SizedBox(
            height: _inspectorHeight,
            child: WorkflowInspectorPanel(
              workflow: workflow,
              editorState: document.state,
              editor: document.editor,
              canEdit: workflow.canManage,
              isWide: false,
            ),
          ),
      ],
    );
  }
}

class const _WorkflowExecutionNotice() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextLocale(LocaleKeys.workflow_editor_execution_notice),
    ),
  );
}

class const _WorkflowReadOnlyNotice() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextLocale(LocaleKeys.workflow_editor_read_only),
    ),
  );
}

class const _WorkflowMetadataFields({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: _WorkflowMetadataConstraintLayout(
      nameController: nameController,
      descriptionController: descriptionController,
      onNameChanged: onNameChanged,
      onDescriptionChanged: onDescriptionChanged,
      readOnly: readOnly,
    ),
  );
}

class const _WorkflowMetadataConstraintLayout({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  static const _wideLayoutBreakpoint = 650.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _WorkflowMetadataLayout(
      isWide: constraints.maxWidth > _wideLayoutBreakpoint,
      nameController: nameController,
      descriptionController: descriptionController,
      onNameChanged: onNameChanged,
      onDescriptionChanged: onDescriptionChanged,
      readOnly: readOnly,
    ),
  );
}

class const _WorkflowMetadataLayout({
  required final bool isWide,
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isWide
      ? _WorkflowMetadataWideLayout(
          nameController: nameController,
          descriptionController: descriptionController,
          onNameChanged: onNameChanged,
          onDescriptionChanged: onDescriptionChanged,
          readOnly: readOnly,
        )
      : _WorkflowMetadataCompactLayout(
          nameController: nameController,
          descriptionController: descriptionController,
          onNameChanged: onNameChanged,
          onDescriptionChanged: onDescriptionChanged,
          readOnly: readOnly,
        );
}

class const _WorkflowMetadataWideLayout({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  static const _nameFieldFlex = 2;
  static const _descriptionFieldFlex = 3;
  static const _fieldSpacing = 12.0;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _WorkflowMetadataNameCell(
        flex: _nameFieldFlex,
        controller: nameController,
        onChanged: onNameChanged,
        readOnly: readOnly,
      ),
      const SizedBox(width: _fieldSpacing),
      _WorkflowMetadataDescriptionCell(
        flex: _descriptionFieldFlex,
        controller: descriptionController,
        onChanged: onDescriptionChanged,
        readOnly: readOnly,
      ),
    ],
  );
}

class const _WorkflowMetadataNameCell({
  required final int flex,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: _WorkflowMetadataField(
      controller: controller,
      labelKey: LocaleKeys.workflow_editor_name,
      textInputAction: .next,
      onChanged: onChanged,
      readOnly: readOnly,
    ),
  );
}

class const _WorkflowMetadataDescriptionCell({
  required final int flex,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: _WorkflowMetadataField(
      controller: controller,
      labelKey: LocaleKeys.workflow_editor_description,
      textInputAction: .done,
      onChanged: onChanged,
      readOnly: readOnly,
    ),
  );
}

class const _WorkflowMetadataCompactLayout({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  static const _fieldSpacing = 8.0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _WorkflowMetadataField(
        controller: nameController,
        labelKey: LocaleKeys.workflow_editor_name,
        textInputAction: .next,
        onChanged: onNameChanged,
        readOnly: readOnly,
      ),
      const SizedBox(height: _fieldSpacing),
      _WorkflowMetadataField(
        controller: descriptionController,
        labelKey: LocaleKeys.workflow_editor_description,
        textInputAction: .done,
        onChanged: onDescriptionChanged,
        readOnly: readOnly,
      ),
    ],
  );
}

class const _WorkflowMetadataField({
  required final TextEditingController controller,
  required final String labelKey,
  required final TextInputAction textInputAction,
  required final ValueChanged<String> onChanged,
  required final bool readOnly,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: Text(labelKey.tr(context: context)),
    size: .small,
    textInputAction: textInputAction,
    onChanged: onChanged,
    readOnly: readOnly,
  );
}

class const _WorkflowLoadRecovery({
  required final String workspaceId,
  required final String? workflowId,
  required final String messageKey,
  required final bool canRetry,
  required final VoidCallback onBack,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          TextLocale(messageKey),
          _WorkflowRecoveryActions(
            workspaceId: workspaceId,
            workflowId: workflowId,
            canRetry: canRetry,
            onBack: onBack,
          ),
        ],
      ),
    );
  }
}

class const _WorkflowRecoveryActions({
  required final String workspaceId,
  required final String? workflowId,
  required final bool canRetry,
  required final VoidCallback onBack,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = workflowId;

    return Column(
      children: [
        const SizedBox(height: 12),
        if (canRetry && id != null)
          _WorkflowRetryButton(
            onPressed: () => ref.invalidate(workflowProvider(workspaceId, id)),
          ),
        _WorkflowBackToListButton(onBack: onBack),
      ],
    );
  }
}

class const _WorkflowRetryButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    variant: .text,
    size: .small,
    child: const TextLocale(LocaleKeys.workflow_editor_retry),
  );
}

class const _WorkflowBackToListButton({required final VoidCallback onBack})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onBack,
    variant: .text,
    size: .small,
    child: const TextLocale(LocaleKeys.common_back),
  );
}

class const _WorkflowEditorToolbar({required final VoidCallback onAddNode})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Align(
      alignment: Alignment.centerLeft,
      child: _WorkflowAddNodeButton(onPressed: onAddNode),
    ),
  );
}

class const _WorkflowAddNodeButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  static const _iconSize = 18.0;
  static const _iconLabelSpacing = 4.0;

  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const Row(
      mainAxisSize: .min,
      children: [
        Icon(Icons.add, size: _iconSize),
        SizedBox(width: _iconLabelSpacing),
        TextLocale(LocaleKeys.workflow_editor_add_node),
      ],
    ),
  );
}

class const _WorkflowCanvasView({
  required final _WorkflowEditorPresentation presentation,
  required final WorkspaceWorkflow workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final commands = presentation.document.commands;
    final canEdit = workflow.canManage;

    return WorkflowCanvas(
      workflow: workflow,
      editorState: presentation.document.state,
      onSelectNode: commands.nodes.select,
      onClearSelection: commands.nodes.clearSelection,
      onMoveNode: canEdit ? commands.nodes.move : _ignoreMove,
      onAddNode: canEdit ? presentation.actions.onAddNodeAfter : _ignoreAddNode,
      onConnect: canEdit ? _connect(commands) : _ignoreConnect,
      onRemoveConnection: canEdit
          ? commands.connections.remove
          : _ignoreRemoveConnection,
    );
  }

  static void _ignoreMove(String nodeId, double x, double y) {}

  static void _ignoreAddNode(String nodeId, WorkflowConditionBranch? branch) {}

  static void _ignoreConnect(
    String sourceNodeId,
    String targetNodeId,
    WorkflowConditionBranch? branch,
  ) {}

  static void _ignoreRemoveConnection(WorkflowConnection connection) {}

  static void Function(String, String, WorkflowConditionBranch?) _connect(
    WorkflowEditorCommands commands,
  ) =>
      (sourceNodeId, targetNodeId, branch) => commands.connections.connect(
        sourceNodeId: sourceNodeId,
        targetNodeId: targetNodeId,
        branch: branch,
      );
}
