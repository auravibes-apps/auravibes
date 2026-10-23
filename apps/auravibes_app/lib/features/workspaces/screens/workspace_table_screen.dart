import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_type_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_access_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_action.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    final selection = useState<_Selection?>(null);
    void refresh() {
      ref
        ..invalidate(workspaceTableProvider(workspaceId, table.id))
        ..invalidate(workspaceTableRecordsProvider(workspaceId, table.id));
    }

    void close() {
      selection.value = null;
      refresh();
    }

    if (selection.value case final selected?) {
      return selected.editor(workspaceId, table, close);
    }
    return _TableBrowser(
      workspaceId: workspaceId,
      table: table,
      onBack: onBack,
      onChanged: refresh,
      onRecord: (record) => selection.value = _RecordSelection(record),
      onColumn: (column) => selection.value = _ColumnSelection(column),
    );
  }
}

sealed class _Selection {
  const _Selection();
  Widget editor(String workspaceId, WorkspaceTable table, VoidCallback onBack);
}

class const _RecordSelection(final WorkspaceRecord? record) extends _Selection {
  @override
  Widget editor(
    String workspaceId,
    WorkspaceTable table,
    VoidCallback onBack,
  ) => WorkspaceRecordEditor(
    workspaceId: workspaceId,
    table: table,
    record: record,
    onBack: onBack,
    key: ValueKey(record?.id ?? 'new'),
  );
}

class const _ColumnSelection(final WorkspaceColumn? column) extends _Selection {
  @override
  Widget editor(
    String workspaceId,
    WorkspaceTable table,
    VoidCallback onBack,
  ) => WorkspaceColumnEditor(
    workspaceId: workspaceId,
    table: table,
    column: column,
    onBack: onBack,
    key: ValueKey(column?.id ?? 'new-column'),
  );
}

class const _TableBrowser({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onBack,
  required final VoidCallback onChanged,
  required final ValueChanged<WorkspaceRecord?> onRecord,
  required final ValueChanged<WorkspaceColumn?> onColumn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ListTile(
        leading: const Icon(Icons.arrow_back),
        title: Text(table.name),
        onTap: onBack,
      ),
      if (table.canManage)
        _LabelEditor(
          workspaceId: workspaceId,
          table: table,
          onChanged: onChanged,
        ),
      if (table.canManage) _ColumnList(table: table, onColumn: onColumn),
      if (table.canManage && table.supportsSharing)
        WorkspaceTableAccessPanel(
          workspaceId: workspaceId,
          table: table,
          onChanged: onChanged,
        ),
      _TableRecords(workspaceId: workspaceId, table: table, onRecord: onRecord),
    ],
  );
}

class const _LabelEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onChanged,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController(
      text: table.columns
          .firstWhere((column) => column.id == table.labelColumnId)
          .name,
    );
    final action = WorkspaceTableActions.use(context);
    Future<void> save() async {
      final usecase = await ref.read(
        workspaceTableUsecaseProvider(workspaceId).future,
      );
      final _ = await usecase.renameLabel(table: table, name: name.text);
      if (context.mounted) onChanged();
    }

    return Column(
      children: [
        AuraInput(
          controller: name,
          label: const TextLocale(LocaleKeys.workspace_items_label_column),
          enabled: !action.pending,
          identifier: 'workspace_label_column',
        ),
        AuraButton(
          onPressed: () => unawaited(action.run(save)),
          child: const TextLocale(LocaleKeys.workspace_items_save_column),
          isLoading: action.pending,
          disabled: action.pending,
          identifier: 'workspace_label_save',
        ),
        if (action.error case final error?) WorkspaceItemFailure(error: error),
      ],
    );
  }
}

class const _ColumnList({
  required final WorkspaceTable table,
  required final ValueChanged<WorkspaceColumn?> onColumn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AuraButton(
        onPressed: () => onColumn(null),
        child: const TextLocale(LocaleKeys.workspace_items_create_column),
        identifier: 'workspace_column_create',
      ),
      for (final column in table.columns)
        ListTile(
          title: Text(column.name),
          subtitle: WorkspaceColumnTypeLabel(type: column.type),
          onTap: () => onColumn(column),
        ),
    ],
  );
}

class const _TableRecords({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final ValueChanged<WorkspaceRecord?> onRecord,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(
      workspaceTableRecordsProvider(workspaceId, table.id),
    );
    return Column(
      children: [
        if (table.canEditRecords)
          AuraButton(
            onPressed: () => onRecord(null),
            child: const TextLocale(LocaleKeys.workspace_items_create_record),
            identifier: 'workspace_record_create',
          ),
        switch (records) {
          AsyncData(:final value) => _RecordRows(
            table: table,
            records: value,
            onRecord: onRecord,
          ),
          AsyncError(:final error) => WorkspaceItemFailure(error: error),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

class const _RecordRows({
  required final WorkspaceTable table,
  required final List<WorkspaceRecord> records,
  required final ValueChanged<WorkspaceRecord?> onRecord,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => records.isEmpty
      ? const TextLocale(LocaleKeys.workspace_items_no_records)
      : Column(
          children: [
            for (final record in records)
              ListTile(
                title: Text(
                  record.values[table.labelColumnId]?.toString() ?? '',
                ),
                onTap: () => onRecord(record),
              ),
          ],
        );
}
