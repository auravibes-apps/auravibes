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
    final parent = path.value.lastOrNull?.id;
    final folders = ref.watch(workspaceFoldersProvider(workspaceId, parent));
    final tables = ref.watch(workspaceTablesProvider(workspaceId, parent));
    final views = ref.watch(workspaceViewsProvider(workspaceId, parent));
    final files = ref.watch(workspaceFilesProvider(workspaceId, parent));
    final error = folders.error ?? tables.error ?? views.error ?? files.error;
    if (error != null) return WorkspaceItemFailure(error: error);
    if (folders.isLoading ||
        tables.isLoading ||
        views.isLoading ||
        files.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final folderItems = [...?folders.value]
      ..sort((a, b) => a.name.compareTo(b.name));
    final items = <({String name, String id, String kind, IconData icon})>[
      for (final table in tables.value ?? <WorkspaceTable>[])
        (
          name: table.name,
          id: table.id,
          kind: 'table',
          icon: Icons.table_chart_outlined,
        ),
      for (final view in views.value ?? <WorkspaceView>[])
        (
          name: view.name,
          id: view.id,
          kind: 'view',
          icon: Icons.dashboard_outlined,
        ),
      for (final file in files.value ?? <WorkspaceFile>[])
        (
          name: file.name,
          id: file.id,
          kind: 'file',
          icon: Icons.insert_drive_file_outlined,
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));

    return ListView(
      children: [
        if (path.value.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: Text(path.value.last.name),
            onTap: () =>
                path.value = path.value.sublist(0, path.value.length - 1),
          ),
        if (folderItems.isEmpty && items.isEmpty)
          const TextLocale(LocaleKeys.workspace_items_empty),
        for (final folder in folderItems)
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(folder.name),
            onTap: () => path.value = [...path.value, folder],
          ),
        for (final item in items)
          ListTile(
            leading: Icon(item.icon),
            title: Text(item.name),
            onTap: () => onOpen(.new(id: item.id, kind: item.kind), item.name),
          ),
      ],
    );
  }
}
