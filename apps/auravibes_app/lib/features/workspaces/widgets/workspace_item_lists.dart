import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemLists({
  required final String workspaceId,
  required final String? parentId,
  required final ValueChanged<WorkspaceFolder> onOpenFolder,
  required final ValueChanged<String> onOpenTable,
  required final ValueChanged<Object> onEdit,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Column(children: [_Tables(this), _Folders(this)]);
}

class const _Tables(final WorkspaceItemLists items) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceTablesProvider(items.workspaceId, items.parentId),
  )) {
    AsyncData(:final value) => Column(
      children: [for (final table in value) _TableRow(items, table)],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _Folders(final WorkspaceItemLists items) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceFoldersProvider(items.workspaceId, items.parentId),
  )) {
    AsyncData(:final value) when value.isEmpty => const TextLocale(
      LocaleKeys.workspace_items_empty,
    ),
    AsyncData(:final value) => Column(
      children: [for (final folder in value) _FolderRow(items, folder)],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _FolderRow(
  final WorkspaceItemLists items,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    trailing: _Edit(
      folder.id,
      () => items.onEdit(folder),
      enabled: folder.canManage,
    ),
    onTap: () => items.onOpenFolder(folder),
  );
}

class const _TableRow(
  final WorkspaceItemLists items,
  final WorkspaceTable table,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.table_chart_outlined),
    title: Text(table.name),
    trailing: _Edit(
      table.id,
      () => items.onEdit(table),
      enabled: table.canManage,
    ),
    onTap: () => items.onOpenTable(table.id),
  );
}

class const _Edit(
  final String id,
  final VoidCallback edit, {
  required final bool enabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.edit_outlined,
    onPressed: edit,
    disabled: !enabled,
    identifier: 'workspace_item_edit_$id',
    tooltip: LocaleKeys.workspace_items_edit_item.tr(),
  );
}
