import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_attachment_field.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_field.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceRecordFields({
  required final WorkspaceTable table,
  required final String workspaceId,
  required final List<String> restricted,
  required final ValueNotifier<Map<String, Object?>> draft,
  required final bool disabled,
  final String? columnId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final column in table.columns.where(
        (column) => columnId == null || column.id == columnId,
      ))
        _RecordColumn(this, column),
    ],
  );
}

class const _RecordColumn(
  final WorkspaceRecordFields fields,
  final WorkspaceColumn column,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _RecordValue(
        table: fields.table,
        column: column,
        workspaceId: fields.workspaceId,
        restricted: fields.restricted.contains(column.id),
        draft: fields.draft,
        disabled: fields.disabled,
      ),
      _RecordConstraintHints(column: column),
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
  bool get present => draft.value[column.id] != null;
  String get identifier => column.id == table.labelColumnId
      ? 'workspace_record_value'
      : 'workspace_record_value_${column.id}';
  void change(Object? value) =>
      draft.value = {...draft.value, column.id: value};
  void unset() => draft.value = Map.of(draft.value)..remove(column.id);
  @override
  Widget build(BuildContext context) => switch (column.type) {
    .reference => _ReferenceRecordValue(this),
    .attachment => WorkspaceAttachmentField(
      workspaceId: workspaceId,
      label: column.name,
      value: _recordValue(this),
      present: present,
      disabled: disabled,
      restricted: restricted,
      onChanged: change,
      onUnset: unset,
    ),
    _ => _ScalarRecordValue(this),
  };
}

class const _RecordConstraintHints({required final WorkspaceColumn column})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (column.isUnique) const TextLocale(LocaleKeys.workspace_items_unique),
    ],
  );
}

class const _ReferenceRecordValue(final _RecordValue field)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceReferenceField(
    workspaceId: field.workspaceId,
    table: field.table,
    column: field.column,
    value: _recordValue(field),
    disabled: field.disabled,
    restricted: field.restricted,
    onChanged: field.change,
    onUnset: field.unset,
    parentId: field.draft.value[field.column.dependsOnColumnId] as String?,
  );
}

class const _ScalarRecordValue(final _RecordValue field)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceRecordField(
    column: field.column,
    value: _recordValue(field),
    present: field.present,
    disabled: field.disabled,
    identifier: field.identifier,
    onChanged: field.change,
    onUnset: field.unset,
    key: ValueKey(field.column.id),
  );
}

Object? _recordValue(_RecordValue field) => field.draft.value[field.column.id];
