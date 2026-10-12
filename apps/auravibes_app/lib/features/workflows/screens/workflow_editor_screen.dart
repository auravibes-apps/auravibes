import 'dart:async';

import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_editor_state.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/screens/workflow_editor_save_flow.dart';
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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _WorkflowEditorIdentity = ({String workspaceId, String? workflowId});
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
  VoidCallback onEditSignature,
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
    final source = _watchEditorSource();
    _syncTextFields(source.state.workflow);
    _bindExitGuard(context, source.state);

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

  void _bindExitGuard(BuildContext context, WorkflowEditorState editorState) {
    _WorkflowEditorExitGuardBinder.bind(
      guard: _exitGuard,
      state: editorState,
      isDirty: () => ref
          .read(workflowEditorProvider(widget.workspaceId, widget.workflowId))
          .isDirty,
      isSaving: () => _saving,
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
    if (_saving || editorState.workflow == null) return;
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

  Future<void> _openNodePicker() async {
    final draft = await WorkflowNodePicker.show(
      context: context,
      workspaceId: widget.workspaceId,
      currentWorkflowId: widget.workflowId,
    );
    if (!mounted || draft == null) return;
    final editor = ref.read(
      workflowEditorProvider(widget.workspaceId, widget.workflowId).notifier,
    );
    editor.commands().nodes.add(draft);
  }

  void _showMessage(String messageKey) {
    final current = _messageController;
    if (current != null) current.close();
    _messageController = ScaffoldMessenger.of(context)
        .showSnackBar(.new(content: Text(messageKey.tr(context: context))));
  }
}

abstract final class _WorkflowEditorPresentationFactory {
  static _WorkflowEditorPresentation create({
    required _WorkflowEditorScreenState screen,
    required BuildContext context,
    required WorkflowEditorState state,
    required WorkflowEditorNotifier editor,
  }) {
    final identity = _identity(screen);
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

  static _WorkflowEditorIdentity _identity(_WorkflowEditorScreenState screen) =>
      (
        workspaceId: screen.widget.workspaceId,
        workflowId: screen.widget.workflowId,
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
    onBack: screen._goBackToWorkflows,
    onSave: () => screen._save(state),
    onAddNode: () => unawaited(screen._openNodePicker()),
    onEditSignature: () => _openSignatureEditor(
      context,
      screen.widget.workspaceId,
      screen.widget.workflowId,
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
        confirm: UnsavedChangesDialog.confirm,
      )
      ..update(isDirty: state.isDirty, isSaving: isSaving());
  }
}

class const _WorkflowEditorPage({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DraftExitScope(
    guard: presentation.guard,
    child: _WorkflowEditorScaffold(presentation: presentation),
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
        presentation.isSaving || presentation.document.state.workflow == null,
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
  required final WorkflowDefinition workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _WorkflowEditorMetadataSection(presentation: presentation),
      _WorkflowEditorToolbarSection(presentation: presentation),
      Expanded(
        child: _WorkflowEditorResponsiveSection(
          presentation: presentation,
          workflow: workflow,
        ),
      ),
      const _WorkflowExecutionNotice(),
    ],
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
    );
  }
}

class const _WorkflowEditorToolbarSection({
  required final _WorkflowEditorPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkflowEditorToolbar(
    onAddNode: presentation.actions.onAddNode,
    onEditSignature: presentation.actions.onEditSignature,
  );
}

class const _WorkflowEditorResponsiveSection({
  required final _WorkflowEditorPresentation presentation,
  required final WorkflowDefinition workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _WorkflowResponsiveEditor(presentation: presentation, workflow: workflow);
}

class const _WorkflowResponsiveEditor({
  required final _WorkflowEditorPresentation presentation,
  required final WorkflowDefinition workflow,
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
  required final WorkflowDefinition workflow,
  required final bool isWide,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isWide
      ? _WorkflowWideEditor(presentation: presentation, workflow: workflow)
      : _WorkflowCompactEditor(presentation: presentation, workflow: workflow);
}

class const _WorkflowWideEditor({
  required final _WorkflowEditorPresentation presentation,
  required final WorkflowDefinition workflow,
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
        const VerticalDivider(width: 1),
        SizedBox(
          width: _inspectorWidth,
          child: WorkflowInspectorPanel(
            workflow: workflow,
            editorState: document.state,
            editor: document.editor,
          ),
        ),
      ],
    );
  }
}

class const _WorkflowCompactEditor({
  required final _WorkflowEditorPresentation presentation,
  required final WorkflowDefinition workflow,
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

class const _WorkflowMetadataFields({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: _WorkflowMetadataConstraintLayout(
      nameController: nameController,
      descriptionController: descriptionController,
      onNameChanged: onNameChanged,
      onDescriptionChanged: onDescriptionChanged,
    ),
  );
}

class const _WorkflowMetadataConstraintLayout({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
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
    ),
  );
}

class const _WorkflowMetadataLayout({
  required final bool isWide,
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => isWide
      ? _WorkflowMetadataWideLayout(
          nameController: nameController,
          descriptionController: descriptionController,
          onNameChanged: onNameChanged,
          onDescriptionChanged: onDescriptionChanged,
        )
      : _WorkflowMetadataCompactLayout(
          nameController: nameController,
          descriptionController: descriptionController,
          onNameChanged: onNameChanged,
          onDescriptionChanged: onDescriptionChanged,
        );
}

class const _WorkflowMetadataWideLayout({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
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
      ),
      const SizedBox(width: _fieldSpacing),
      _WorkflowMetadataDescriptionCell(
        flex: _descriptionFieldFlex,
        controller: descriptionController,
        onChanged: onDescriptionChanged,
      ),
    ],
  );
}

class const _WorkflowMetadataNameCell({
  required final int flex,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: _WorkflowMetadataField(
      controller: controller,
      labelKey: LocaleKeys.workflow_editor_name,
      textInputAction: .next,
      onChanged: onChanged,
    ),
  );
}

class const _WorkflowMetadataDescriptionCell({
  required final int flex,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: _WorkflowMetadataField(
      controller: controller,
      labelKey: LocaleKeys.workflow_editor_description,
      textInputAction: .done,
      onChanged: onChanged,
    ),
  );
}

class const _WorkflowMetadataCompactLayout({
  required final TextEditingController nameController,
  required final TextEditingController descriptionController,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String> onDescriptionChanged,
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
      ),
      const SizedBox(height: _fieldSpacing),
      _WorkflowMetadataField(
        controller: descriptionController,
        labelKey: LocaleKeys.workflow_editor_description,
        textInputAction: .done,
        onChanged: onDescriptionChanged,
      ),
    ],
  );
}

class const _WorkflowMetadataField({
  required final TextEditingController controller,
  required final String labelKey,
  required final TextInputAction textInputAction,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(labelText: labelKey.tr(context: context), isDense: true),
    textInputAction: textInputAction,
    onChanged: onChanged,
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
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          TextLocale(messageKey),
          _WorkflowRecoveryActions(
            workspaceId: workspaceId,
            workflowId: workflowId,
            canRetry: canRetry,
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
        _WorkflowBackToListButton(workspaceId: workspaceId),
      ],
    );
  }
}

class const _WorkflowRetryButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.workflow_editor_retry),
  );
}

class const _WorkflowBackToListButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => WorkflowsRoute(workspaceId: workspaceId).go(context),
    child: const TextLocale(LocaleKeys.workflow_editor_back_to_list),
  );
}

class const _WorkflowEditorToolbar({
  required final VoidCallback onAddNode,
  required final VoidCallback onEditSignature,
}) extends StatelessWidget {
  static const _toolbarSpacing = 8.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      children: [
        _WorkflowAddNodeButton(onPressed: onAddNode),
        const SizedBox(width: _toolbarSpacing),
        _WorkflowEditSignatureButton(onPressed: onEditSignature),
      ],
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

class const _WorkflowEditSignatureButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.input_outlined),
    label: const TextLocale(LocaleKeys.workflow_editor_signature),
  );
}

class const _WorkflowCanvasView({
  required final _WorkflowEditorPresentation presentation,
  required final WorkflowDefinition workflow,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkflowCanvas(
    workflow: workflow,
    editorState: presentation.document.state,
    onSelectNode: presentation.document.commands.nodes.select,
    onMoveNode: presentation.document.commands.nodes.move,
    onSelectOutput: presentation.document.commands.connections.selectOutput,
    onSelectInput: presentation.document.commands.connections.selectInput,
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
