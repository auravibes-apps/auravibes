import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_access_panel.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('workspace_table_screen');

class const WorkspaceTableScreen({
  required final String workspaceId,
  required final String tableId,
  required final VoidCallback onBack,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(workspaceTableProvider(workspaceId, tableId));

    void refresh() {
      ref
        ..invalidate(workspaceTableProvider(workspaceId, tableId))
        ..invalidate(workspaceTableRecordsProvider(workspaceId, tableId));
    }

    return AppScreen(
      child: switch (table) {
        AsyncData(:final value) => _TableContents(
          workspaceId: workspaceId,
          table: value,
          onBack: onBack,
          key: ValueKey(value.id),
        ),
        AsyncError(:final error) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const TextLocale(LocaleKeys.workspace_items_title),
              onTap: onBack,
            ),
            WorkspaceItemFailure(error: error),
          ],
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.workspace_items_table),
        actions: [AuraIconButton(icon: Icons.refresh, onPressed: refresh)],
      ),
    );
  }
}

class const _TableContents({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onBack,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columnName = useTextEditingController(
      text: table.columns.single.name,
    );
    final editing = useState(false);
    final selected = useState<WorkspaceRecord?>(null);
    final pending = useState(false);
    final error = useState<Object?>(null);
    final recordsProvider = workspaceTableRecordsProvider(
      workspaceId,
      table.id,
    );
    final records = ref.watch(recordsProvider);
    void refresh() {
      ref
        ..invalidate(recordsProvider)
        ..invalidate(workspaceTableProvider(workspaceId, table.id));
    }

    Future<void> renameLabel() async {
      if (pending.value) {
        return;
      }
      pending.value = true;
      error.value = null;
      try {
        final usecase = await ref.read(
          workspaceTableUsecaseProvider(workspaceId).future,
        );
        final _ = await usecase.renameLabel(
          table: table,
          name: columnName.text,
        );
        if (!context.mounted) {
          return;
        }
        refresh();
      } on Object catch (failure, stackTrace) {
        _logger.warning(
          'Column edit failed: ${failure.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) error.value = failure;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    void closeRecord() {
      editing.value = false;
      selected.value = null;
      refresh();
    }

    if (editing.value) {
      return WorkspaceRecordEditor(
        workspaceId: workspaceId,
        table: table,
        record: selected.value,
        onBack: closeRecord,
        key: ValueKey(selected.value?.id ?? 'new'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(table.name),
          onTap: onBack,
        ),
        if (table.canManage)
          AuraInput(
            controller: columnName,
            label: const TextLocale(LocaleKeys.workspace_items_label_column),
            enabled: !pending.value,
            identifier: 'workspace_label_column',
          ),
        if (table.canManage)
          AuraButton(
            onPressed: () => unawaited(renameLabel()),
            child: const TextLocale(LocaleKeys.workspace_items_save_column),
            isLoading: pending.value,
            disabled: pending.value,
            identifier: 'workspace_label_save',
          ),
        if (error.value case final failure?)
          WorkspaceItemFailure(error: failure),
        if (table.canManage && table.supportsSharing)
          WorkspaceTableAccessPanel(
            workspaceId: workspaceId,
            table: table,
            onChanged: refresh,
          ),
        if (table.canEditRecords)
          AuraButton(
            onPressed: () {
              selected.value = null;
              editing.value = true;
            },
            child: const TextLocale(LocaleKeys.workspace_items_create_record),
            identifier: 'workspace_record_create',
          ),
        switch (records) {
          AsyncData(:final value) when value.isEmpty => const TextLocale(
            LocaleKeys.workspace_items_no_records,
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final record in value)
                ListTile(
                  title: Text(record.values[table.labelColumnId] ?? ''),
                  subtitle: Text(record.id),
                  onTap: () {
                    selected.value = record;
                    editing.value = true;
                  },
                ),
            ],
          ),
          AsyncError(:final error) => WorkspaceItemFailure(error: error),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}
