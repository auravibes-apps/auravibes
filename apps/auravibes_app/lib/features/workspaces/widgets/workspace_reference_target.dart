import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceTarget({
  required final String workspaceId,
  required final ValueNotifier<String?> targetTableId,
  required final ValueNotifier<bool> multiple,
  required final bool disabled,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _TargetBody((picker: this, parent: useState<String?>(null)));
}

typedef _TargetState = ({
  WorkspaceReferenceTarget picker,
  ValueNotifier<String?> parent,
});

class const _TargetBody(final _TargetState state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_items_reference_table),
      if (state.picker.targetTableId.value case final id?)
        _SelectedTable(workspaceId: state.picker.workspaceId, id: id),
      _TargetNavigation(state),
      _TargetTables(state),
      _Cardinality(state),
    ],
  );
}

class const _TargetNavigation(final _TargetState state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: const TextLocale(LocaleKeys.workspace_items_root),
        onTap: state.picker.disabled ? null : () => state.parent.value = null,
      ),
      _TargetFolders(state),
    ],
  );
}

class const _TargetFolders(final _TargetState state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceFoldersProvider(state.picker.workspaceId, state.parent.value),
  )) {
    AsyncData(value: final folders) => Column(
      children: folders.map(_folder).toList(),
    ),
    AsyncError() => const TextLocale(
      LocaleKeys.workspace_items_reference_unavailable,
    ),
    AsyncLoading() => const CircularProgressIndicator(),
  };
  Widget _folder(WorkspaceFolder folder) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: state.picker.disabled ? null : () => state.parent.value = folder.id,
  );
}

class const _TargetTables(final _TargetState state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceTablesProvider(state.picker.workspaceId, state.parent.value),
  )) {
    AsyncData(value: final tables) => Column(
      children: tables.map(_table).toList(),
    ),
    AsyncError() => const TextLocale(
      LocaleKeys.workspace_items_reference_unavailable,
    ),
    AsyncLoading() => const CircularProgressIndicator(),
  };
  Widget _table(WorkspaceTable table) => AuraCheckboxListTile(
    value: state.picker.targetTableId.value == table.id,
    onChanged: (_) => state.picker.targetTableId.value = table.id,
    title: Text(table.name),
    disabled: state.picker.disabled,
    semanticLabel: table.name,
  );
}

class const _Cardinality(final _TargetState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: state.picker.multiple.value,
    onChanged: (value) => state.picker.multiple.value = value,
    title: const TextLocale(LocaleKeys.workspace_items_reference_multiple),
    disabled: state.picker.disabled,
  );
}

class const _SelectedTable({
  required final String workspaceId,
  required final String id,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(workspaceTableProvider(workspaceId, id))) {
        AsyncData(value: final table) => Text(table.name),
        AsyncError() => const TextLocale(
          LocaleKeys.workspace_items_reference_unavailable,
        ),
        AsyncLoading() => const CircularProgressIndicator(),
      };
}
