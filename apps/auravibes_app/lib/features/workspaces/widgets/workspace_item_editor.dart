import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_form_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemEditor({
  required final String workspaceId,
  required final String name,
  required final String? parentId,
  required final String? parentName,
  required final VoidCallback onBack,
  required final Future<void> Function(String, String?) onSave,
  final String? excludedFolderId,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => _EditorBody(
    .new(
      this,
      context,
      .use(name: name),
      useState(parentId),
      useState(parentName),
    ),
  );
}

class const _EditorState(
  final WorkspaceItemEditor widget,
  final BuildContext context,
  final WorkspaceItemFormState form,
  final ValueNotifier<String?> destination,
  final ValueNotifier<String?> destinationName,
) {
  void changeDestination(WorkspaceFolder? folder) {
    destination.value = folder?.id;
    destinationName.value = folder?.name;
  }

  Future<void> save() => form.run(context, () async {
    await widget.onSave(form.name.text, destination.value);
    if (context.mounted) widget.onBack();
  });
}

class const _EditorBody(final _EditorState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _Header(state),
      _NameInput(state),
      _DestinationSection(state),
      _Actions(state),
    ],
  );
}

class const _Header(final _EditorState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.arrow_back),
    title: const TextLocale(LocaleKeys.workspace_items_edit_item),
    onTap: state.form.pending.value ? null : state.widget.onBack,
  );
}

class const _NameInput(final _EditorState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: state.form.name,
    label: const TextLocale(LocaleKeys.workspace_items_item_name),
    enabled: !state.form.pending.value,
    identifier: 'workspace_item_name',
  );
}

class const _DestinationSection(final _EditorState state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_items_destination),
      if (state.destinationName.value case final current?) Text(current),
      _Picker(state),
    ],
  );
}

class const _Picker(final _EditorState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Destinations(
    workspaceId: state.widget.workspaceId,
    parentId: state.destination.value,
    excludedId: state.widget.excludedFolderId,
    enabled: !state.form.pending.value,
    onChanged: state.changeDestination,
  );
}

class const _Actions(final _EditorState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (state.form.error.value case final failure?)
        WorkspaceItemFailure(error: failure),
      _Save(state),
      AuraButton(
        onPressed: state.widget.onBack,
        child: const TextLocale(LocaleKeys.common_cancel),
        disabled: state.form.pending.value,
      ),
    ],
  );
}

class const _Save(final _EditorState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(state.save()),
    child: const TextLocale(LocaleKeys.common_save),
    isLoading: state.form.pending.value,
    disabled: state.form.pending.value,
    identifier: 'workspace_item_save',
  );
}

class const _Destinations({
  required final String workspaceId,
  required final String? parentId,
  required final String? excludedId,
  required final bool enabled,
  required final ValueChanged<WorkspaceFolder?> onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: const TextLocale(LocaleKeys.workspace_items_root),
        onTap: enabled ? () => onChanged(null) : null,
      ),
      _FolderOptions(
        this,
        ref.watch(workspaceFoldersProvider(workspaceId, parentId)),
      ),
    ],
  );
}

class const _FolderOptions(
  final _Destinations picker,
  final AsyncValue<List<WorkspaceFolder>> folders,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (folders) {
    AsyncData(:final value) => Column(
      children: [
        for (final folder in value)
          if (folder.id != picker.excludedId) _DestinationRow(picker, folder),
      ],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _DestinationRow(
  final _Destinations picker,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: picker.enabled ? () => picker.onChanged(folder) : null,
  );
}
