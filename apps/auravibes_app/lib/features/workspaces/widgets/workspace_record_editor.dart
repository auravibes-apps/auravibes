import 'package:auravibes_app/features/workspaces/widgets/workspace_reverse_references.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_field.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_field.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceRecordEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceRecord? record,
  required final VoidCallback onBack,
  final ValueChanged<WorkspaceRecord>? onSaved,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _RecordActions.use(context, record);

    return _RecordForm(
      editor: this,
      draft: draft,
      onSave: () => _RecordActions.save(ref, this, draft),
    );
  }
}

typedef _RecordDraft = ({
  ValueNotifier<Map<String, Object?>> values,
  WorkspaceTableAction action,
});

abstract final class _RecordActions {
  static _RecordDraft use(BuildContext context, WorkspaceRecord? record) => (
    values: useState<Map<String, Object?>>({...?record?.values}),
    action: WorkspaceTableActions.use(context),
  );

  static Future<void> save(
    WidgetRef ref,
    WorkspaceRecordEditor editor,
    _RecordDraft draft,
  ) async {
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(editor.workspaceId).future,
    );
    final saved = await _write(usecase, editor, .of(draft.values.value));
    if (ref.context.mounted) editor.onSaved?.call(saved);
    if (ref.context.mounted) editor.onBack();
  }

  static Future<WorkspaceRecord> _write(
    OrganizeWorkspaceTablesUsecase usecase,
    WorkspaceRecordEditor editor,
    Map<String, Object?> values,
  ) => switch (editor.record) {
    final record? => usecase.updateRecord(
      table: editor.table,
      record: record,
      values: values,
    ),
    null => usecase.createRecord(table: editor.table, values: values),
  };
}

class const _RecordForm({
  required final WorkspaceRecordEditor editor,
  required final _RecordDraft draft,
  required final Future<void> Function() onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceTableEditor(
    table: editor.table,
    onBack: editor.onBack,
    action: draft.action,
    onSave: onSave,
    kind: .record,
    children: [_RecordDraftFields(editor: editor, draft: draft),
      if (editor.record case final record?) WorkspaceReverseReferences(workspaceId: editor.workspaceId, record: record),
    ],
  );
}

class const _RecordDraftFields({
  required final WorkspaceRecordEditor editor,
  required final _RecordDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _RecordFields(
    table: editor.table,
    workspaceId: editor.workspaceId,
    restricted: editor.record?.restrictedReferenceColumns ?? const [],
    draft: draft.values,
    disabled: draft.action.pending || !editor.table.canEditRecords,
  );
}

class const _RecordFields({
  required final WorkspaceTable table,
  required final String workspaceId,
  required final List<String> restricted,
  required final ValueNotifier<Map<String, Object?>> draft,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final column in table.columns) ...[
        _RecordConstraintHints(column: column),
        _RecordValue(
          table: table,
          workspaceId: workspaceId,
          restricted: restricted.contains(column.id),
          column: column,
          draft: draft,
          disabled: disabled,
        ),
      ],
    ],
  );
}

class const _RecordValue({
  required final WorkspaceTable table,
  required final WorkspaceColumn column,
  required final String workspaceId,
  required final bool restricted,
  required final ValueNotifier<Map<String, Object?>> draft,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => column.type == .reference
    ? WorkspaceReferenceField(workspaceId: workspaceId, table: table, column: column,
        value: draft.value[column.id], disabled: disabled, restricted: restricted,
        onChanged: _change, onUnset: _unset)
    : WorkspaceRecordField(
    column: column,
    value: draft.value[column.id],
    present: draft.value.containsKey(column.id),
    disabled: disabled,
    identifier: column.id == table.labelColumnId
        ? 'workspace_record_value'
        : 'workspace_record_value_${column.id}',
    onChanged: _change,
    onUnset: _unset,
    key: ValueKey(column.id),
  );
  void _change(Object? value) =>
      draft.value = {...draft.value, column.id: value};
  void _unset() => draft.value = Map.of(draft.value)..remove(column.id);
}

class const _RecordConstraintHints({required final WorkspaceColumn column})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (column.isRequired)
        const TextLocale(LocaleKeys.workspace_items_required),
      if (column.isUnique) const TextLocale(LocaleKeys.workspace_items_unique),
    ],
  );
}
