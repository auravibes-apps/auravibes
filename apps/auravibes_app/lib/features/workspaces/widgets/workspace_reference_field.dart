import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_picker.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const _pickerWidth = 720.0;
const _pickerHeight = 620.0;

class const WorkspaceReferenceField({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn column,
  required final Object? value,
  required final bool disabled,
  required final bool restricted,
  required final ValueChanged<Object?> onChanged,
  required final VoidCallback onUnset,
  final bool schemaDefault = false,
  final String? parentId,
  super.key,
}) extends StatelessWidget {
  List<String> get ids => WorkspaceReferenceValue.ids(value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Text(column.name),
      if (restricted)
        const TextLocale(LocaleKeys.workspace_items_reference_unavailable)
      else
        _ReferenceChoices(field: this),
      _ReferenceParentHint(field: this),
    ],
  );
  Future<void> _pick(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(child: _ReferencePickerDialog(field: this)),
  );
  void _selected(BuildContext context, List<String> ids) {
    if (ids.isEmpty) {
      onUnset();
    } else {
      onChanged(column.referenceMultiple ? ids : ids.single);
    }
    Navigator.of(context).pop();
  }
}

class const _ReferenceChoices({required final WorkspaceReferenceField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      for (final id in field.ids)
        WorkspaceReferenceLabel(
          workspaceId: field.workspaceId,
          targetTableId: field.column.targetTableId ?? '',
          recordId: id,
        ),
      _ReferenceActions(field: field),
    ],
  );
}

class const _ReferenceActions({required final WorkspaceReferenceField field})
    extends StatelessWidget {
  bool get available =>
      field.schemaDefault ||
      field.column.dependsOnColumnId == null ||
      field.parentId != null;
  bool get _canRemove => !field.disabled && field.value != null;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AuraButton(
        onPressed: () => field._pick(context),
        child: const TextLocale(LocaleKeys.workspace_items_reference_choose),
        disabled: field.disabled || !available,
      ),

      if (_canRemove)
        AuraButton(
          onPressed: field.onUnset,
          child: const TextLocale(LocaleKeys.workspace_items_reference_remove),
        ),
    ],
  );
}

class const _ReferencePickerDialog({
  required final WorkspaceReferenceField field,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _pickerWidth,
    height: _pickerHeight,
    child: _ReferencePickerContent(field: field),
  );
}

class const _ReferencePickerContent({
  required final WorkspaceReferenceField field,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceReferencePicker(
    workspaceId: field.workspaceId,
    table: field.table,
    column: field.column,
    selected: field.ids,
    onSelected: (ids) => field._selected(context, ids),
    schemaDefault: field.schemaDefault,
    parentId: field.parentId,
  );
}

class const _ReferenceParentHint({required final WorkspaceReferenceField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      !field.schemaDefault &&
          field.column.dependsOnColumnId != null &&
          field.parentId == null
      ? const TextLocale(LocaleKeys.workspace_items_reference_select_parent)
      : const SizedBox.shrink();
}
