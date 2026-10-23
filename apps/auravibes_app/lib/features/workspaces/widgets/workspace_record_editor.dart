import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('workspace_record_editor');

class const WorkspaceRecordEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceRecord? record,
  required final VoidCallback onBack,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = useState(
      Map<String, Object?>.of(record?.values ?? {table.labelColumnId: ''}),
    );
    final pending = useState(false);
    final error = useState<Object?>(null);
    void unsetColumn(String id) {
      final updated = Map<String, Object?>.of(draft.value)..remove(id);
      draft.value = updated;
    }

    Future<void> save() async {
      if (pending.value) {
        return;
      }
      pending.value = true;
      error.value = null;
      try {
        final usecase = await ref.read(
          workspaceTableUsecaseProvider(workspaceId).future,
        );
        final values = Map<String, Object?>.of(draft.value);
        final existing = record;
        final _ = existing == null
            ? await usecase.createRecord(table: table, values: values)
            : await usecase.updateRecord(
                table: table,
                record: existing,
                values: values,
              );
        if (context.mounted) onBack();
      } on Object catch (failure, stackTrace) {
        _logger.warning(
          'Record save failed: ${failure.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) error.value = failure;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(table.name),
          onTap: pending.value ? null : onBack,
        ),
        for (final column in table.columns)
          WorkspaceRecordField(
            column: column,
            value: draft.value[column.id],
            present: draft.value.containsKey(column.id),
            disabled: pending.value || !table.canEditRecords,
            identifier: column.id == table.labelColumnId
                ? 'workspace_record_value'
                : 'workspace_record_value_${column.id}',
            onChanged: (value) =>
                draft.value = {...draft.value, column.id: value},
            onUnset: () => unsetColumn(column.id),
            key: ValueKey(column.id),
          ),
        if (table.canEditRecords) AuraButton(
          onPressed: () => unawaited(save()),
          child: const TextLocale(LocaleKeys.workspace_items_save_record),
          isLoading: pending.value,
          disabled: pending.value,
          identifier: 'workspace_record_save',
        ),
        if (error.value case final failure?)
          WorkspaceItemFailure(error: failure),
      ],
    );
  }
}
