import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
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
  required final ValueChanged<String> onOpenView,
  required final ValueChanged<Object> onEdit,
  final Set<String>? selection,
  final ValueChanged<String>? onSelect,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(workspaceFoldersProvider(workspaceId, parentId));
    final tables = ref.watch(workspaceTablesProvider(workspaceId, parentId));

    final views = ref.watch(workspaceViewsProvider(workspaceId, parentId));

    return _State(this, folders, tables, views);
  }
}

class const _State(
  final WorkspaceItemLists owner,
  final AsyncValue<List<WorkspaceFolder>> folders,
  final AsyncValue<List<WorkspaceTable>> tables,
  final AsyncValue<List<WorkspaceView>> views,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final failure = folders.error ?? tables.error ?? views.error;
    if (failure != null) return WorkspaceItemFailure(error: failure);

    return _Loaded(owner, folders.value, tables.value, views.value);
  }
}

class const _Loaded(
  final WorkspaceItemLists owner,
  final List<WorkspaceFolder>? folders,
  final List<WorkspaceTable>? tables,
  final List<WorkspaceView>? views,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch ((folders: folders, tables: tables, views: views)) {
        (
          folders: final folderItems?,
          tables: final tableItems?,
          views: final viewItems?,
        ) =>
          _Contents(owner, folderItems, tableItems, viewItems),
        _ => const Center(child: CircularProgressIndicator()),
      };
}

class const _Contents(
  final WorkspaceItemLists owner,
  final List<WorkspaceFolder> folders,
  final List<WorkspaceTable> tables,
  final List<WorkspaceView> views,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty && tables.isEmpty && views.isEmpty) {
      return const TextLocale(LocaleKeys.workspace_items_empty);
    }

    return Column(
      children: [
        for (final folder in _folders()) _FolderRow(owner, folder),
        for (final element in _elements()) _ElementRow(owner, element),
      ],
    );
  }

  List<WorkspaceFolder> _folders() =>
      folders.toList()..sort((a, b) => _compare(a.name, b.name));
  List<Object> _elements() =>
      [...tables, ...views]
        ..sort((a, b) => _compare(_elementName(a), _elementName(b)));
}

String _elementName(Object element) => switch (element) {
  WorkspaceTable(:final name) || WorkspaceView(:final name) => name,
  _ => '',
};

class const _ElementRow(final WorkspaceItemLists owner, final Object element)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (element) {
    final WorkspaceTable table => _TableRow(owner, table),
    final WorkspaceView view => _ViewRow(owner, view),
    _ => const SizedBox.shrink(),
  };
}

class const _ViewRow(final WorkspaceItemLists owner, final WorkspaceView view)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ItemRow(
    owner,
    id: view.id,
    name: view.name,
    icon: Icons.dashboard_outlined,
    canManage: false,
    onOpen: () => owner.onOpenView(view.id),
    onEdit: () => owner.onOpenView(view.id),
  );
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
    if (row.owner.selection != null || !row.canManage) {
      return const SizedBox.shrink();
    }

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
