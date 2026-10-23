import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('workspace_items_screen');

class const WorkspaceItemsScreen({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = useState(<WorkspaceFolder>[]);
    final selectedTable = useState<String?>(null);
    final tableName = useTextEditingController();
    final name = useTextEditingController();
    final pending = useState(false);
    final error = useState<Object?>(null);
    final parentId = path.value.lastOrNull?.id;
    final provider = workspaceFoldersProvider(workspaceId, parentId);
    final folders = ref.watch(provider);
    final tablesProvider = workspaceTablesProvider(workspaceId, parentId);
    final tables = ref.watch(tablesProvider);

    Future<void> createTable() async {
      if (pending.value) {
        return;
      }
      pending.value = true;
      error.value = null;
      try {
        final usecase = await ref.read(
          workspaceTableUsecaseProvider(workspaceId).future,
        );
        final created = await usecase.create(
          name: tableName.text,
          labelName: LocaleKeys.workspace_items_default_label.tr(),
          parentId: parentId,
        );
        if (!context.mounted) {
          return;
        }
        tableName.clear();
        ref.invalidate(tablesProvider);
        selectedTable.value = created.id;
      } on Object catch (failure, stackTrace) {
        _logger.warning(
          'Table creation failed: ${failure.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) error.value = failure;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    Future<void> create() async {
      if (pending.value) {
        return;
      }
      pending.value = true;
      error.value = null;
      try {
        final usecase = await ref.read(
          workspaceFolderUsecaseProvider(workspaceId).future,
        );
        final _ = await usecase.create(name: name.text, parentId: parentId);
        if (!context.mounted) {
          return;
        }
        name.clear();
        ref.invalidate(provider);
      } on Object catch (failure, stackTrace) {
        _logger.warning(
          'Folder creation failed: ${failure.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) error.value = failure;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    void refresh() {
      ref
        ..invalidate(provider)
        ..invalidate(tablesProvider);
    }

    if (selectedTable.value case final id?) {
      return WorkspaceTableScreen(
        workspaceId: workspaceId,
        tableId: id,
        onBack: () {
          selectedTable.value = null;
          ref.invalidate(tablesProvider);
        },
      );
    }

    return AppScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (path.value.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(path.value.last.name),
              onTap: pending.value
                  ? null
                  : () {
                      path.value = path.value.sublist(0, path.value.length - 1);
                      error.value = null;
                    },
            ),
          AuraInput(
            controller: name,
            label: const TextLocale(LocaleKeys.workspace_items_folder_name),
            enabled: !pending.value,
            onSubmitted: (_) => unawaited(create()),
            identifier: 'workspace_folder_name',
          ),
          AuraButton(
            onPressed: () => unawaited(create()),
            child: const TextLocale(LocaleKeys.workspace_items_create_folder),
            isLoading: pending.value,
            disabled: pending.value,
            identifier: 'workspace_folder_create',
          ),
          AuraInput(
            controller: tableName,
            label: const TextLocale(LocaleKeys.workspace_items_table_name),
            enabled: !pending.value,
            identifier: 'workspace_table_name',
          ),
          AuraButton(
            onPressed: () => unawaited(createTable()),
            child: const TextLocale(LocaleKeys.workspace_items_create_table),
            isLoading: pending.value,
            disabled: pending.value,
            identifier: 'workspace_table_create',
          ),
          switch (tables) {
            AsyncData(:final value) => Column(
              children: [
                for (final table in value)
                  ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: Text(table.name),
                    onTap: pending.value
                        ? null
                        : () => selectedTable.value = table.id,
                  ),
              ],
            ),
            AsyncError(:final error) => WorkspaceItemFailure(error: error),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
          },
          if (error.value case final failure?)
            WorkspaceItemFailure(error: failure),
          switch (folders) {
            AsyncData(:final value) when value.isEmpty => const TextLocale(
              LocaleKeys.workspace_items_empty,
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final folder in value)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    onTap: pending.value
                        ? null
                        : () {
                            path.value = [...path.value, folder];
                            error.value = null;
                          },
                  ),
              ],
            ),
            AsyncError(:final error) => WorkspaceItemFailure(error: error),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.workspace_items_title),
        actions: [AuraIconButton(icon: Icons.refresh, onPressed: refresh)],
      ),
    );
  }
}
