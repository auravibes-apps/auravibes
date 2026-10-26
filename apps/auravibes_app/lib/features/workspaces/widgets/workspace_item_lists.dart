import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_duplication_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
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
  required final ValueChanged<String> onOpenFile,
  required final ValueChanged<Object> onEdit,
  final Set<WorkspaceDirectoryItemKey>? selection,
  final ValueChanged<WorkspaceDirectoryMoveItem>? onSelect,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(workspaceFoldersProvider(workspaceId, parentId));
    final tables = ref.watch(workspaceTablesProvider(workspaceId, parentId));

    final views = ref.watch(workspaceViewsProvider(workspaceId, parentId));

    return _State(
      this,
      folders,
      tables,
      views,
      ref.watch(workspaceFilesProvider(workspaceId, parentId)),
    );
  }
}

class const _State(
  final WorkspaceItemLists owner,
  final AsyncValue<List<WorkspaceFolder>> folders,
  final AsyncValue<List<WorkspaceTable>> tables,
  final AsyncValue<List<WorkspaceView>> views,
  final AsyncValue<List<WorkspaceFile>> files,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final failure = folders.error ?? tables.error ?? views.error ?? files.error;
    if (failure != null) return WorkspaceItemFailure(error: failure);

    return _Loaded(
      owner,
      folders.value,
      tables.value,
      views.value,
      files.value,
    );
  }
}

class const _Loaded(
  final WorkspaceItemLists owner,
  final List<WorkspaceFolder>? folders,
  final List<WorkspaceTable>? tables,
  final List<WorkspaceView>? views,
  final List<WorkspaceFile>? files,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch ((folders: folders, tables: tables, views: views, files: files)) {
        (
          folders: final folderItems?,
          tables: final tableItems?,
          views: final viewItems?,
          files: final fileItems?,
        ) =>
          _Contents(owner, folderItems, tableItems, viewItems, fileItems),
        _ => const Center(child: CircularProgressIndicator()),
      };
}

class const _Contents(
  final WorkspaceItemLists owner,
  final List<WorkspaceFolder> folders,
  final List<WorkspaceTable> tables,
  final List<WorkspaceView> views,
  final List<WorkspaceFile> files,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty && tables.isEmpty && views.isEmpty && files.isEmpty) {
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
      [...tables, ...views, ...files]
        ..sort((a, b) => _compare(_elementName(a), _elementName(b)));
}

String _elementName(Object element) => switch (element) {
  WorkspaceTable(:final name) ||
  WorkspaceView(:final name) ||
  WorkspaceFile(:final name) => name,
  _ => '',
};

class const _ElementRow(final WorkspaceItemLists owner, final Object element)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (element) {
    final WorkspaceTable table => _TableRow(owner, table),
    final WorkspaceView view => _ViewRow(owner, view),
    final WorkspaceFile file => _FileRow(owner, file),
    _ => const SizedBox.shrink(),
  };
}

class const _FileRow(final WorkspaceItemLists owner, final WorkspaceFile file)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ItemRow(
    owner,
    item: .file(file),
    icon: Icons.insert_drive_file_outlined,
    onOpen: () => owner.onOpenFile(file.id),
    onEdit: () => owner.onEdit(file),
  );
}

class const _ViewRow(final WorkspaceItemLists owner, final WorkspaceView view)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ItemRow(
    owner,
    item: .view(view),
    icon: Icons.dashboard_outlined,
    onOpen: () => owner.onOpenView(view.id),
    onEdit: () => owner.onEdit(view),
    source: view,
  );
}

class const _FolderRow(
  final WorkspaceItemLists owner,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ItemRow(
    owner,
    item: .folder(folder),
    icon: Icons.folder_outlined,
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
    item: .table(table),
    icon: Icons.table_chart_outlined,
    onOpen: () => owner.onOpenTable(table.id),
    onEdit: () => owner.onEdit(table),
    source: table,
  );
}

class const _ItemRow(
  final WorkspaceItemLists owner, {
  required final WorkspaceDirectoryMoveItem item,
  required final IconData icon,
  required final VoidCallback onOpen,
  required final VoidCallback onEdit,
  final Object? source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey(item.key),
    leading: _Leading(this),
    title: Text(item.name),
    trailing: _Menu(this),
    onTap: owner.selection == null ? onOpen : _select,
    onLongPress: _select,
  );
  void _select() => owner.onSelect?.call(item);
}

class const _Leading(final _ItemRow row) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (row.owner.selection) {
    final Set<WorkspaceDirectoryItemKey> selected => Checkbox(
      value: selected.contains(row.item.key),
      onChanged: (_) => row._select(),
    ),
    null => Icon(row.icon),
  };
}

class const _Menu(final _ItemRow row) extends ConsumerWidget {
  bool get _duplicable =>
      row.item.key.kind == .table || row.item.key.kind == .view;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (row.owner.selection != null || !row.item.canManage) {
      return const SizedBox.shrink();
    }

    return AuraPopupMenuButton(
      items: _items(context, ref),
      identifier: 'workspace_item_edit_${row.item.key.id}',
      tooltip: LocaleKeys.common_show_more.tr(),
    );
  }

  List<AuraPopupMenuEntry> _items(BuildContext context, WidgetRef ref) => [
    _edit(),
    if (_duplicable) _duplicate(context),
    const AuraPopupMenuDivider(),
    _trash(context, ref),
  ];

  AuraPopupMenuItem _edit() => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_edit_item),
    onTap: row.onEdit,
  );
  AuraPopupMenuItem _duplicate(BuildContext context) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_duplicate),
    onTap: () => unawaited(_copy(context)),
    identifier: 'workspace_item_duplicate_${row.item.key.id}',
  );
  Future<void> _copy(BuildContext context) async {
    final source = row.source;
    if (source == null) return;
    final id = await WorkspaceItemDuplicationActions.open(
      context,
      row.owner.workspaceId,
      source,
    );
    if (!context.mounted || id == null) return;
    _openCopy(id);
  }

  void _openCopy(String id) {
    if (row.item.key.kind == .table) {
      row.owner.onOpenTable(id);
    } else {
      row.owner.onOpenView(id);
    }
  }

  AuraPopupMenuItem _trash(BuildContext context, WidgetRef ref) =>
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_trash_action),
        onTap: () => unawaited(_delete(context, ref)),
        variant: .error,
        identifier: 'workspace_item_trash_${row.item.key.id}',
      );
  Future<bool> _delete(BuildContext context, WidgetRef ref) =>
      WorkspaceTrashActions.trash(
        context,
        ref,
        row.owner.workspaceId,
        _trashTarget(row.item),
      );
}

int _compare(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

WorkspaceTrashTarget _trashTarget(WorkspaceDirectoryMoveItem item) => .new(
  kind: switch (item.key.kind) {
    .folder => .folder,
    .table => .table,
    .view => .view,
    .file => .file,
  },
  id: item.key.id,
  revision: item.revision,
);
