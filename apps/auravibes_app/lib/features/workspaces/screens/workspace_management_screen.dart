// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/models/management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/usecases.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

/// A dedicated screen for managing workspaces.
///
/// Displays all workspaces and provides create, edit, and delete actions.
class WorkspaceManagementScreen extends HookConsumerWidget {
  /// Creates a [WorkspaceManagementScreen].
  const WorkspaceManagementScreen({required this.workspaceId, super.key});

  /// The current workspace ID from the route.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(allWorkspacesProvider);
    final modeState = ref.watch(workspaceManagementModeProvider);

    return AuraScreen(
      child: switch (workspacesAsync) {
        AsyncData(:final value) => _WorkspaceManagementBody(
          workspaces: value,
          modeState: modeState,
          activeWorkspaceId: workspaceId,
          onCreateWorkspace: _createWorkspace,
          onEditWorkspace: _editWorkspace,
          onDeleteWorkspace: _confirmDelete,
        ),
        AsyncLoading(:final value?) => _WorkspaceManagementBody(
          workspaces: value,
          modeState: modeState,
          activeWorkspaceId: workspaceId,
          onCreateWorkspace: _createWorkspace,
          onEditWorkspace: _editWorkspace,
          onDeleteWorkspace: _confirmDelete,
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError() => const Center(
          child: AuraText(
            child: TextLocale(LocaleKeys.workspace_management_load_error),
          ),
        ),
      },
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.workspace_management_title),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _createWorkspace(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final _ = await createWorkspaceMutation.run(ref, (transaction) {
      final usecase = ref.read(createWorkspaceUseCaseProvider);

      return usecase.call(name: name);
    });

    if (!context.mounted) return;

    final mutationState = ref.read(createWorkspaceMutation);
    switch (mutationState) {
      case MutationSuccess():
        ref.read(workspaceManagementModeProvider.notifier).clearEditing();
      case MutationError(:final error):
        _showError(context, error);
      case _:
        break;
    }
  }

  Future<void> _editWorkspace(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final _ = await editWorkspaceMutation.run(ref, (transaction) {
      final usecase = ref.read(editWorkspaceUseCaseProvider);

      return usecase.call(id: id, name: name);
    });

    if (!context.mounted) return;

    final mutationState = ref.read(editWorkspaceMutation);
    switch (mutationState) {
      case MutationSuccess():
        ref.read(workspaceManagementModeProvider.notifier).clearEditing();
      case MutationError(:final error):
        _showError(context, error);
      case _:
        break;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    List<WorkspaceEntity> workspaces,
  ) async {
    final workspace = workspaces.firstWhereOrNull((w) => w.id == id);
    if (workspace == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TextLocale(LocaleKeys.workspace_management_delete_title),
        content: Text(
          LocaleKeys.workspace_management_delete_confirm.tr(
            namedArgs: {'name': workspace.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TextLocale(
              LocaleKeys.common_delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await deleteWorkspaceMutation.run(ref, (transaction) {
        final usecase = ref.read(deleteWorkspaceUseCaseProvider);

        return usecase.call(
          id: id,
          workspaceCount: workspaces.length,
          activeWorkspaceId: workspaceId,
        );
      });

      if (!context.mounted) return;

      final mutationState = ref.read(deleteWorkspaceMutation);
      if (mutationState is MutationError) {
        _showError(context, mutationState.error);
      }
    }
  }

  void _showError(BuildContext context, Object error) {
    final message = error is WorkspaceException
        ? error.localizationKey?.tr() ?? error.message
        : LocaleKeys.workspace_management_unexpected_error.tr();

    if (error is! WorkspaceException) {
      debugPrint('Workspace management unexpected error: $error');
    }

    final _ = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _WorkspaceManagementBody extends ConsumerWidget {
  const _WorkspaceManagementBody({
    required this.workspaces,
    required this.modeState,
    required this.activeWorkspaceId,
    required this.onCreateWorkspace,
    required this.onEditWorkspace,
    required this.onDeleteWorkspace,
  });

  final List<WorkspaceEntity> workspaces;
  final WorkspaceManagementState modeState;
  final String activeWorkspaceId;
  final Future<void> Function(BuildContext context, WidgetRef ref, String name)
  onCreateWorkspace;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  )
  onEditWorkspace;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    String id,
    List<WorkspaceEntity> workspaces,
  )
  onDeleteWorkspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = modeState.mode;

    return mode == ManagementMode.create
        ? _CreateWorkspaceForm(
            onCancel: () => ref
                .read(workspaceManagementModeProvider.notifier)
                .setMode(ManagementMode.list),
            onSubmit: (name) => onCreateWorkspace(context, ref, name),
          )
        : _WorkspaceList(
            workspaces: workspaces,
            activeWorkspaceId: activeWorkspaceId,
            onEdit: (workspace) => ref
                .read(workspaceManagementModeProvider.notifier)
                .setMode(
                  ManagementMode.edit,
                  editingWorkspace: workspace,
                ),
            onDelete: (id) => onDeleteWorkspace(context, ref, id, workspaces),
            onStartCreate: () => ref
                .read(workspaceManagementModeProvider.notifier)
                .setMode(ManagementMode.create),
            onSaveEdit: (id, name) => onEditWorkspace(context, ref, id, name),
            onCancelEdit: () => ref
                .read(workspaceManagementModeProvider.notifier)
                .clearEditing(),
            editingWorkspace: modeState.editingWorkspace,
          );
  }
}

class _WorkspaceList extends StatelessWidget {
  const _WorkspaceList({
    required this.workspaces,
    required this.activeWorkspaceId,
    required this.onEdit,
    required this.onDelete,
    required this.onStartCreate,
    required this.onSaveEdit,
    required this.onCancelEdit,
    this.editingWorkspace,
  });

  final List<WorkspaceEntity> workspaces;
  final String activeWorkspaceId;
  final void Function(WorkspaceEntity) onEdit;
  final void Function(String) onDelete;
  final VoidCallback onStartCreate;
  final void Function(String, String) onSaveEdit;
  final VoidCallback onCancelEdit;
  final WorkspaceEntity? editingWorkspace;

  @override
  Widget build(BuildContext context) {
    if (workspaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextLocale(LocaleKeys.workspace_management_no_workspaces),
            const SizedBox(height: 16),
            AuraButton(
              onPressed: onStartCreate,
              child: const TextLocale(
                LocaleKeys.workspace_management_create_button,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemBuilder: (context, index) {
        if (index == workspaces.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _CreateButton(onPressed: onStartCreate),
          );
        }

        final workspace = workspaces[index];
        final isEditing = editingWorkspace?.id == workspace.id;

        if (isEditing) {
          return _EditWorkspaceTile(
            workspace: workspace,
            onSave: (name) => onSaveEdit(workspace.id, name),
            onCancel: onCancelEdit,
            key: ValueKey(workspace.id),
          );
        }

        return _WorkspaceListTile(
          workspace: workspace,
          isActive: workspace.id == activeWorkspaceId,
          onEdit: () => onEdit(workspace),
          onDelete: () => onDelete(workspace.id),
          key: ValueKey(workspace.id),
        );
      },
      itemCount: workspaces.length + 1,
    );
  }
}

class _WorkspaceListTile extends StatelessWidget {
  const _WorkspaceListTile({
    required this.workspace,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final WorkspaceEntity workspace;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(workspace.name),
      subtitle: isActive
          ? const TextLocale(LocaleKeys.workspace_management_active_label)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuraIconButton(
            icon: Icons.edit,
            onPressed: onEdit,
            tooltip: LocaleKeys.workspace_management_edit_tooltip.tr(
              namedArgs: {'name': workspace.name},
            ),
          ),
          AuraIconButton(
            icon: Icons.delete,
            onPressed: onDelete,
            tooltip: LocaleKeys.workspace_management_delete_tooltip.tr(
              namedArgs: {'name': workspace.name},
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AuraButton(
      onPressed: onPressed,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add),
          SizedBox(width: 8),
          TextLocale(LocaleKeys.workspace_management_create_button),
        ],
      ),
    );
  }
}

class _CreateWorkspaceForm extends StatefulWidget {
  const _CreateWorkspaceForm({
    required this.onCancel,
    required this.onSubmit,
  });

  final VoidCallback onCancel;
  final void Function(String) onSubmit;

  @override
  State<_CreateWorkspaceForm> createState() => _CreateWorkspaceFormState();
}

class _CreateWorkspaceFormState extends State<_CreateWorkspaceForm> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.length < 3) {
      setState(() {
        _errorText = LocaleKeys.workspace_management_name_too_short_error.tr(
          namedArgs: {'min': '3'},
        );
      });

      return;
    }
    if (name.length > 20) {
      setState(() {
        _errorText = LocaleKeys.workspace_management_name_too_long_error.tr(
          namedArgs: {'max': '20'},
        );
      });

      return;
    }
    setState(() => _errorText = null);
    widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.workspace_management_create_title),
            style: AuraTextStyle.heading6,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: LocaleKeys.workspace_management_name_label.tr(),
              helperText: LocaleKeys.workspace_management_name_placeholder.tr(),
              errorText: _errorText,
            ),
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AuraButton(
                  onPressed: widget.onCancel,
                  child: const TextLocale(LocaleKeys.common_cancel),
                  variant: AuraButtonVariant.outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AuraButton(
                  onPressed: _submit,
                  child: const TextLocale(
                    LocaleKeys.workspace_management_create_button,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditWorkspaceTile extends StatefulWidget {
  const _EditWorkspaceTile({
    required this.workspace,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final WorkspaceEntity workspace;
  final void Function(String) onSave;
  final VoidCallback onCancel;

  @override
  State<_EditWorkspaceTile> createState() => _EditWorkspaceTileState();
}

class _EditWorkspaceTileState extends State<_EditWorkspaceTile> {
  TextEditingController? _controller;

  TextEditingController get _requiredController {
    final controller = _controller;
    if (controller == null) {
      throw StateError('_controller is not initialized');
    }

    return controller;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.workspace.name);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _requiredController,
              decoration: InputDecoration(
                helperText: LocaleKeys.workspace_management_name_placeholder
                    .tr(),
              ),
              textInputAction: TextInputAction.done,
              autofocus: true,
              onSubmitted: (value) => widget.onSave(value.trim()),
            ),
          ),
          AuraIconButton(
            icon: Icons.check,
            onPressed: () => widget.onSave(_requiredController.text.trim()),
            tooltip: LocaleKeys.common_save.tr(),
          ),
          AuraIconButton(
            icon: Icons.close,
            onPressed: widget.onCancel,
            tooltip: LocaleKeys.common_cancel.tr(),
          ),
        ],
      ),
    );
  }
}
