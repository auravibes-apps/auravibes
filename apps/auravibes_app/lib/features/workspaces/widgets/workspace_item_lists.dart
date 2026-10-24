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
  final Set<String>? selection,
  final ValueChanged<String>? onSelect,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(workspaceFoldersProvider(workspaceId, parentId));
    final tables = ref.watch(workspaceTablesProvider(workspaceId, parentId));

    return _State(this, folders, tables);
  }
}

class const _State(
  final WorkspaceItemLists owner,
  final AsyncValue<List<WorkspaceFolder>> folders,
  final AsyncValue<List<WorkspaceTable>> tables,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch ((folders: folders, tables: tables)) {
        (folders: AsyncError(:final error), tables: _) ||
        (
          folders: _,
          tables: AsyncError(:final error),
        ) => WorkspaceItemFailure(error: error),
        (
          folders: AsyncData(value: final folderItems),
          tables: AsyncData(value: final tableItems),
        ) =>
          _Contents(owner, folderItems, tableItems),
        _ => const Center(child: CircularProgressIndicator()),
      };
}

class const _Contents(
  final WorkspaceItemLists owner,
  final List<WorkspaceFolder> folders,
  final List<WorkspaceTable> tables,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty && tables.isEmpty) {
      return const TextLocale(LocaleKeys.workspace_items_empty);
    }

    return Column(
      children: [
        for (final folder in _folders()) _FolderRow(owner, folder),
        for (final table in _tables()) _TableRow(owner, table),
      ],
    );
  }

  List<WorkspaceFolder> _folders() =>
      folders.toList()..sort((a, b) => _compare(a.name, b.name));
  List<WorkspaceTable> _tables() =>
      tables.toList()..sort((a, b) => _compare(a.name, b.name));
}

class const _FolderRow(
  final WorkspaceItemLists owner,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ItemRow(
    owner,
    id: folder.id,
    name: folder.name,
    icon: Icons.folder_outlined,
    canManage: folder.canManage,
    onOpen: () => owner.onOpenFolder(folder),
    onEdit: () => owner.onEdit(folder),
  );
}

class const _TableRow(
  final WorkspaceItemLists owner,
  final WorkspaceTable table,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ItemRow(
    owner,
    id: table.id,
    name: table.name,
    icon: Icons.table_chart_outlined,
    canManage: table.canManage,
    onOpen: () => owner.onOpenTable(table.id),
    onEdit: () => owner.onEdit(table),
  );
}

class const _ItemRow(
  final WorkspaceItemLists owner, {
  required final String id,
  required final String name,
  required final IconData icon,
  required final bool canManage,
  required final VoidCallback onOpen,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('directory_item_$id'),
    leading: _Leading(this),
    title: Text(name),
    trailing: _Menu(this),
    onTap: owner.selection == null ? onOpen : _select,
    onLongPress: _select,
  );
  void _select() => owner.onSelect?.call(id);
}

class const _Leading(final _ItemRow row) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (row.owner.selection) {
    final Set<String> selected => Checkbox(
      value: selected.contains(row.id),
      onChanged: (_) => row._select(),
    ),
    null => Icon(row.icon),
  };
}

class const _Menu(final _ItemRow row) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (row.owner.selection != null || !row.canManage)
      return const SizedBox.shrink();

    return AuraPopupMenuButton(
      items: [
        AuraPopupMenuItem(
          title: const TextLocale(LocaleKeys.workspace_items_edit_item),
          onTap: row.onEdit,
        ),
      ],
      identifier: 'workspace_item_edit_${row.id}',
      tooltip: LocaleKeys.common_show_more.tr(),
    );
  }
}

int _compare(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
