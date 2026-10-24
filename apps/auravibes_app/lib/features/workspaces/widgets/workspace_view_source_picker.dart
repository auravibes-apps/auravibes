import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceViewSourcePicker({
  required final String workspaceId,
  required final WorkspaceTable? selected,
  required final ValueChanged<WorkspaceTable> onSelected,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) =>
      _Source(this, useState<List<WorkspaceFolder>>(const []));
}

class const _Source(
  final WorkspaceViewSourcePicker owner,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends ConsumerWidget {
  String? get parentId => path.value.lastOrNull?.id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    mainAxisSize: .min,
    children: [
      _Parent(path),
      _Folders(
        ref.watch(workspaceFoldersProvider(owner.workspaceId, parentId)),
        path,
      ),
      _Tables(
        owner,
        ref.watch(workspaceTablesProvider(owner.workspaceId, parentId)),
      ),
    ],
  );
}

class const _Parent(final ValueNotifier<List<WorkspaceFolder>> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.arrow_back),
    title: _PathTitle(path.value),
    onTap: path.value.isEmpty ? null : _back,
  );
  void _back() => path.value = path.value.sublist(0, path.value.length - 1);
}

class const _Folders(
  final AsyncValue<List<WorkspaceFolder>> folders,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (folders) {
    AsyncData(:final value) => Column(
      mainAxisSize: .min,
      children: [for (final folder in value) _Folder(folder, path)],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _Folder(
  final WorkspaceFolder folder,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: () => path.value = [...path.value, folder],
  );
}

class const _Tables(
  final WorkspaceViewSourcePicker owner,
  final AsyncValue<List<WorkspaceTable>> tables,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (tables) {
    AsyncData(:final value) =>
      _noEditableTables(value)
          ? const TextLocale(LocaleKeys.workspace_views_no_tables)
          : Column(
              mainAxisSize: .min,
              children: [
                for (final table in value.where((table) => table.canManage))
                  _Table(owner, table),
              ],
            ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _Table(
  final WorkspaceViewSourcePicker owner,
  final WorkspaceTable table,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.table_chart_outlined),
    title: Text(table.name),
    onTap: () => owner.onSelected(table),
    selected: owner.selected?.id == table.id,
  );
}

class const _PathTitle(final List<WorkspaceFolder> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => path.isEmpty
      ? const TextLocale(LocaleKeys.workspace_items_title)
      : Text(path.last.name);
}

bool _noEditableTables(List<WorkspaceTable> tables) =>
    !tables.any((table) => table.canManage);
