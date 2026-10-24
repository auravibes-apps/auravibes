import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_type_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceColumnEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn? column,
  required final VoidCallback onBack,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _ColumnActions.use(context, column);

    return _ColumnForm(
      editor: this,
      draft: draft,
      onSave: () => _ColumnActions.save(ref, this, draft),
    );
  }
}

typedef _ColumnFields = ({
  TextEditingController name,
  TextEditingController options,
  ValueNotifier<String> timeZone,
  ValueNotifier<WorkspaceColumnType> type,
});
typedef _ColumnDraft = ({_ColumnFields fields, WorkspaceTableAction action});

abstract final class _ColumnActions {
  static _ColumnDraft use(BuildContext context, WorkspaceColumn? column) =>
      (fields: _fields(column), action: WorkspaceTableActions.use(context));
  static Future<void> save(
    WidgetRef ref,
    WorkspaceColumnEditor editor,
    _ColumnDraft draft,
  ) async {
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(editor.workspaceId).future,
    );
    final _ = await usecase.saveColumn(
      table: editor.table,
      column: _column(editor.column, draft.fields),
    );
    if (ref.context.mounted) editor.onBack();
  }

  static bool hasOptions(WorkspaceColumnType type) =>
      type == .singleSelect || type == .multiSelect;
  static _ColumnFields _fields(WorkspaceColumn? column) => (
    name: useTextEditingController(text: column?.name ?? ''),
    options: useTextEditingController(text: column?.options.join('\n') ?? ''),
    type: useState(column?.type ?? WorkspaceColumnType.text),
    timeZone: useState(column?.timeZone ?? 'UTC'),
  );
  static WorkspaceColumn _column(
    WorkspaceColumn? column,
    _ColumnFields fields,
  ) => WorkspaceColumn(
    id: column?.id ?? '',
    name: fields.name.text,
    type: fields.type.value,
    options: _options(fields),
    timeZone: fields.timeZone.value,
  );
  static List<String> _options(_ColumnFields fields) =>
      hasOptions(fields.type.value)
      ? fields.options.text
            .split('\n')
            .where((option) => option.trim().isNotEmpty)
            .toList()
      : const [];
}

class const _ColumnForm({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
  required final Future<void> Function() onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceTableEditor(
    table: editor.table,
    onBack: editor.onBack,
    action: draft.action,
    onSave: onSave,
    kind: .column,
    children: [_ColumnInputs(editor: editor, draft: draft)],
  );
}

class const _ColumnInputs({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ColumnName(
        controller: draft.fields.name,
        disabled: draft.action.pending,
      ),
      _ColumnDraftType(editor: editor, draft: draft),
      _ColumnDraftOptions(fields: draft.fields, disabled: draft.action.pending),
      _ColumnTimeZone(draft: draft),
    ],
  );
}

class const _ColumnDraftType({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ColumnType(
    type: draft.fields.type,
    disabled: draft.action.pending,
    isLabel: editor.column?.id == editor.table.labelColumnId,
  );
}

class const _ColumnDraftOptions({
  required final _ColumnFields fields,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _ColumnActions.hasOptions(fields.type.value)
      ? _ColumnOptions(controller: fields.options, disabled: disabled)
      : const SizedBox.shrink();
}

class const _ColumnName({
  required final TextEditingController controller,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: const TextLocale(LocaleKeys.workspace_items_column_name),
    enabled: !disabled,
    identifier: 'workspace_column_name',
  );
}

class const _ColumnType({
  required final ValueNotifier<WorkspaceColumnType> type,
  required final bool disabled,
  required final bool isLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraDropdownSelector<WorkspaceColumnType>(
        options: [
          for (final value in WorkspaceColumnType.values.where(_allowed))
            AuraDropdownOption(
              value: value,
              child: WorkspaceColumnTypeLabel(type: value),
            ),
        ],
        value: type.value,
        onChanged: disabled ? null : _change,
        label: const TextLocale(LocaleKeys.workspace_items_column_type),
        isEnabled: !disabled,
        identifier: 'workspace_column_type',
      );
  bool _allowed(WorkspaceColumnType value) => !isLabel || value == .text;
  void _change(WorkspaceColumnType? value) {
    if (value != null) type.value = value;
  }
}

class const _ColumnOptions({
  required final TextEditingController controller,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: const TextLocale(LocaleKeys.workspace_items_column_options),
    hint: const TextLocale(LocaleKeys.workspace_items_options_hint),
    enabled: !disabled,
    maxLines: 6,
    identifier: 'workspace_column_options',
  );
}

class const _TimeZoneInput({
  required final _ColumnFields fields,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_items_timezone),
      AuraDropdownSelector<String>(
        options: [
          for (final zone in WorkspaceTimeZones.names)
            AuraDropdownOption(value: zone, child: Text(zone)),
        ],
        value: fields.timeZone.value,
        onChanged: _change,
        isEnabled: !disabled,
        identifier: 'workspace_column_timezone',
      ),
    ],
  );
  void _change(String? value) {
    if (value != null) fields.timeZone.value = value;
  }
}

class const _ColumnTimeZone({required final _ColumnDraft draft})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => draft.fields.type.value == .timestamp
      ? _TimeZoneInput(fields: draft.fields, disabled: draft.action.pending)
      : const SizedBox.shrink();
}
