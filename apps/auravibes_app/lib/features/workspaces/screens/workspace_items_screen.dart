import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_folder_metadata_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_creation.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_lists.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_metadata_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemsScreen({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Navigation(workspaceId, useState([]), useState(null));
  }
}

class const _Navigation(
  final String workspaceId,
  final ValueNotifier<List<WorkspaceFolder>> path,
  final ValueNotifier<Object?> selected,
) extends ConsumerWidget {
  String? get _parentId => path.value.lastOrNull?.id;
  String? get _parentName => path.value.lastOrNull?.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (selected.value) {
    final WorkspaceFolder folder => _FolderEditor(this, folder),
    final WorkspaceTable table => _TableEditor(this, table),
    final String id => WorkspaceTableScreen(
      workspaceId: workspaceId,
      tableId: id,
      onBack: () {
        selected.value = null;
        _refresh(ref);
      },
    ),
    _ => _Browser(this),
  };

  void _folder(WorkspaceFolder folder) => path.value = [...path.value, folder];
  void _up() => path.value = path.value.sublist(0, path.value.length - 1);

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(workspaceFoldersProvider(workspaceId, _parentId))
      ..invalidate(workspaceTablesProvider(workspaceId, _parentId));
  }
}

class const _FolderEditor(
  final _Navigation navigation,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: WorkspaceFolderMetadataEditor(
      workspaceId: navigation.workspaceId,
      folder: folder,
      parentName: navigation._parentName,
      onBack: () => navigation.selected.value = null,
    ),
  );
}

class const _TableEditor(
  final _Navigation navigation,
  final WorkspaceTable table,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: WorkspaceTableMetadataEditor(
      workspaceId: navigation.workspaceId,
      table: table,
      parentName: navigation._parentName,
      onBack: () => navigation.selected.value = null,
    ),
  );
}

class const _Browser(final _Navigation navigation) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScreen(
    child: _BrowserBody(navigation),
    appBar: AuraAppBarWithDrawer(
      title: const TextLocale(LocaleKeys.workspace_items_title),
      actions: [
        AuraIconButton(
          icon: Icons.refresh,
          onPressed: () => navigation._refresh(ref),
        ),
      ],
    ),
  );
}

class const _BrowserBody(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (navigation.path.value.isNotEmpty) _ParentFolder(navigation),
      _Creation(navigation, table: false),
      _Creation(navigation, table: true),
      _Items(navigation),
    ],
  );
}

class const _ParentFolder(final _Navigation navigation)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.arrow_upward),
    title: Text(navigation.path.value.last.name),
    onTap: navigation._up,
  );
}

class const _Creation(final _Navigation navigation, {required final bool table})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceItemCreation(
    workspaceId: navigation.workspaceId,
    parentId: navigation._parentId,
    table: table,
    onOpenTable: (id) => navigation.selected.value = id,
    key: ValueKey((parentId: navigation._parentId, table: table)),
  );
}

class const _Items(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceItemLists(
    workspaceId: navigation.workspaceId,
    parentId: navigation._parentId,
    onOpenFolder: navigation._folder,
    onOpenTable: (id) => navigation.selected.value = id,
    onEdit: (item) => navigation.selected.value = item,
  );
}
