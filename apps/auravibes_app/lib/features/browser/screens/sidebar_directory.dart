import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/providers/workspace_directory_workflows_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const SidebarDirectory({
  required final String workspaceId,
  required final void Function(WorkspaceChatItem, String) onOpen,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = useState<List<WorkspaceFolder>>([]);

    return _WatchDirectory(this, path);
  }
}

class const _WatchDirectory(
  final SidebarDirectory owner,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = path.value.lastOrNull?.id;
    final folders = ref.watch(
      workspaceFoldersProvider(owner.workspaceId, parent),
    );
    final tables = ref.watch(
      workspaceTablesProvider(owner.workspaceId, parent),
    );

    return _WatchOthers(owner, path, folders, tables);
  }
}

class const _WatchOthers(
  final SidebarDirectory owner,
  final ValueNotifier<List<WorkspaceFolder>> path,
  final AsyncValue<List<WorkspaceFolder>> folders,
  final AsyncValue<List<WorkspaceTable>> tables,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = path.value.lastOrNull?.id;
    final views = ref.watch(workspaceViewsProvider(owner.workspaceId, parent));
    final files = ref.watch(workspaceFilesProvider(owner.workspaceId, parent));

    final workflows = ref.watch(
      workspaceDirectoryWorkflowsProvider(owner.workspaceId, parent),
    );
    return _DirectoryResults(
      owner,
      path,
      folders,
      tables,
      views,
      files,
      workflows,
    );
  }
}

typedef _Entry = ({String name, String id, String kind, IconData icon});

class const _DirectoryResults(
  final SidebarDirectory owner,
  final ValueNotifier<List<WorkspaceFolder>> path,
  final AsyncValue<List<WorkspaceFolder>> folders,
  final AsyncValue<List<WorkspaceTable>> tables,
  final AsyncValue<List<WorkspaceView>> views,
  final AsyncValue<List<WorkspaceFile>> files,
  final AsyncValue<List<WorkspaceWorkflow>> workflows,
) extends StatelessWidget {
  bool get _loading =>
      folders.isLoading ||
      tables.isLoading ||
      views.isLoading ||
      files.isLoading;

  @override
  Widget build(BuildContext context) {
    final error =
        folders.error ??
        tables.error ??
        views.error ??
        files.error ??
        workflows.error;
    if (error != null) return WorkspaceItemFailure(error: error);
    if (_loading || workflows.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _DirectoryEntries(owner, path, _folders(), _items());
  }

  List<WorkspaceFolder> _folders() =>
      [...?folders.value]..sort((a, b) => a.name.compareTo(b.name));

  List<_Entry> _items() => [
    ..._tableEntries(),
    ..._viewEntries(),
    ..._fileEntries(),
    ..._workflowEntries(),
  ]..sort((a, b) => a.name.compareTo(b.name));

  Iterable<_Entry> _tableEntries() => [
    for (final table in tables.value ?? <WorkspaceTable>[])
      (
        name: table.name,
        id: table.id,
        kind: 'table',
        icon: Icons.table_chart_outlined,
      ),
  ];

  Iterable<_Entry> _viewEntries() => [
    for (final view in views.value ?? <WorkspaceView>[])
      (
        name: view.name,
        id: view.id,
        kind: 'view',
        icon: Icons.dashboard_outlined,
      ),
  ];

  Iterable<_Entry> _fileEntries() => [
    for (final file in files.value ?? <WorkspaceFile>[])
      (
        name: file.name,
        id: file.id,
        kind: 'file',
        icon: Icons.insert_drive_file_outlined,
      ),
  ];

  Iterable<_Entry> _workflowEntries() => [
    for (final workflow in workflows.value ?? <WorkspaceWorkflow>[])
      (
        name: workflow.name,
        id: workflow.id,
        kind: 'workflow',
        icon: Icons.account_tree_outlined,
      ),
  ];
}

class const _DirectoryEntries(
  final SidebarDirectory owner,
  final ValueNotifier<List<WorkspaceFolder>> path,
  final List<WorkspaceFolder> folders,
  final List<_Entry> items,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      if (path.value.isNotEmpty) _Breadcrumb(path),
      if (folders.isEmpty && items.isEmpty)
        const TextLocale(LocaleKeys.workspace_items_empty),
      for (final folder in folders) _FolderEntry(path, folder),
      for (final item in items) _FileEntry(owner, item),
    ],
  );
}

class const _Breadcrumb(final ValueNotifier<List<WorkspaceFolder>> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: .center,
    children: [
      _BreadcrumbBack(path),
      _BreadcrumbRoot(path),
      for (var index = 0; index < path.value.length; index++) ...[
        const Text('/'),
        _BreadcrumbLink(path, index),
      ],
    ],
  );
}

class const _BreadcrumbLink(
  final ValueNotifier<List<WorkspaceFolder>> path,
  final int index,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => path.value = path.value.sublist(0, index + 1),
    child: Text(path.value[index].name),
  );
}

class const _BreadcrumbBack(final ValueNotifier<List<WorkspaceFolder>> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => path.value = path.value.sublist(0, path.value.length - 1),
    icon: const Icon(Icons.arrow_back),
  );
}

class const _BreadcrumbRoot(final ValueNotifier<List<WorkspaceFolder>> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => path.value = [],
    child: const TextLocale(LocaleKeys.workspace_items_title),
  );
}

class const _FolderEntry(
  final ValueNotifier<List<WorkspaceFolder>> path,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: () => path.value = [...path.value, folder],
  );
}

class const _FileEntry(final SidebarDirectory owner, final _Entry item)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(item.icon),
    title: Text(item.name),
    onTap: () => owner.onOpen(.new(id: item.id, kind: item.kind), item.name),
  );
}
