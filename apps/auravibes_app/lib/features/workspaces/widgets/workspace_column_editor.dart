import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_time_zones.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/preview_workspace_column_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_attachment_field.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_constraints.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_type_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_violations.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_dependency.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_field.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_target.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceColumnEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn? column,
  required final VoidCallback onBack,
  final WorkspaceColumnType initialType = .text,
  final bool compact = false,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _ColumnActions.use(context, column, initialType);

    Future<void> save() => _ColumnActions.save(ref, this, draft);
    if (compact) {
      return _CompactColumnForm(editor: this, draft: draft, onSave: save);
    }

    return _ColumnForm(editor: this, draft: draft, onSave: save);
  }
}

typedef _ColumnFields = ({
  TextEditingController name,
  TextEditingController options,
  ValueNotifier<String> timeZone,
  _ColumnReferenceDraft reference,
  ValueNotifier<WorkspaceColumnType> type,
  WorkspaceColumnConstraintDraft constraints,
});
typedef _ColumnDraft = ({
  _ColumnFields fields,
  WorkspaceTableAction action,
  ValueNotifier<List<WorkspaceRecord>> violations,
  ValueNotifier<bool> replacement,
});

abstract final class _ColumnActions {
  static _ColumnDraft use(
    BuildContext context,
    WorkspaceColumn? column,
    WorkspaceColumnType initialType,
  ) => (
    fields: _fields(column, initialType),
    action: WorkspaceTableActions.use(context),
    violations: useState<List<WorkspaceRecord>>([]),
    replacement: useState(false),
  );
  static Future<void> save(
    WidgetRef ref,
    WorkspaceColumnEditor editor,
    _ColumnDraft draft,
  ) async {
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(editor.workspaceId).future,
    );
    if (!ref.context.mounted) return;
    final input = _draftInput(editor, draft);
    if (!await _preview(ref, usecase, input, draft)) {
      return;
    }
    await _write(ref, usecase, editor, input.column);
  }

  static bool hasOptions(WorkspaceColumnType type) =>
      type == .singleSelect || type == .multiSelect;
  static ({WorkspaceTable table, WorkspaceColumn column}) _draftInput(
    WorkspaceColumnEditor editor,
    _ColumnDraft draft,
  ) => (
    table: editor.table,
    column: _column(
      draft.replacement.value ? '' : editor.column?.id ?? '',
      draft.fields,
    ),
  );

  static Future<void> _write(
    WidgetRef ref,
    OrganizeWorkspaceTablesUsecase usecase,
    WorkspaceColumnEditor editor,
    WorkspaceColumn column,
  ) async {
    final _ = await usecase.saveColumn(table: editor.table, column: column);
    if (ref.context.mounted) editor.onBack();
  }

  static Future<bool> _preview(
    WidgetRef ref,
    OrganizeWorkspaceTablesUsecase usecase,
    ({WorkspaceTable table, WorkspaceColumn column}) input,
    _ColumnDraft draft,
  ) async {
    final violations = await PreviewWorkspaceColumnUsecase(usecase)
        .call(table: input.table, column: input.column);
    if (!ref.context.mounted) return false;
    draft.violations.value = violations;

    return violations.isEmpty;
  }

  static _ColumnFields _fields(
    WorkspaceColumn? column,
    WorkspaceColumnType initialType,
  ) => (
    constraints: WorkspaceColumnConstraints.use(column),
    name: useTextEditingController(text: column?.name ?? ''),
    options: useTextEditingController(text: column?.options.join('\n') ?? ''),
    type: useState(column?.type ?? initialType),
    timeZone: useState(column?.timeZone ?? 'UTC'),
    reference: _referenceDraft(column),
  );
  static WorkspaceColumn _column(String id, _ColumnFields fields) =>
      _ColumnValue(id, fields, _referenceConfiguration(fields)).build();

  static List<String> _options(_ColumnFields fields) =>
      hasOptions(fields.type.value)
      ? fields.options.text
            .split('\n')
            .where((option) => option.trim().isNotEmpty)
            .toList()
      : const [];
}

class const _CompactColumnForm({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
  required final Future<void> Function() onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(16),
    children: [
      _CompactColumnInputs(editor: editor, draft: draft),
      if (draft.action.error case final error?)
        WorkspaceItemFailure(error: error),
      _CompactColumnButtons(editor: editor, draft: draft, onSave: onSave),
    ],
  );
}

class const _CompactColumnInputs({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ColumnBasicInputs(editor: editor, draft: draft),
      _ColumnDraftReference(editor: editor, draft: draft),
      _ColumnTimeZone(draft: draft),
      _ColumnPreviewResult(editor: editor, draft: draft),
    ],
  );
}

class const _CompactColumnButtons({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
  required final Future<void> Function() onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final action = draft.action;

    return Row(
      mainAxisAlignment: .end,
      children: [
        _CompactColumnCancel(onBack: editor.onBack, pending: action.pending),
        AuraButton(
          onPressed: () => unawaited(action.run(onSave)),
          child: const TextLocale(LocaleKeys.workspace_items_create_column),
          disabled: action.pending,
          identifier: 'workspace_column_create_confirm',
        ),
      ],
    );
  }
}

class const _CompactColumnCancel({
  required final VoidCallback onBack,
  required final bool pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onBack,
    child: const TextLocale(LocaleKeys.common_cancel),
    disabled: pending,
  );
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
      _ColumnBasicInputs(editor: editor, draft: draft),
      _ColumnDraftReference(editor: editor, draft: draft),
      _ColumnConstraintInputs(editor: editor, draft: draft),
      _ColumnPreviewResult(editor: editor, draft: draft),
      _ColumnTimeZone(draft: draft),
    ],
  );
}

class const _ColumnConstraintInputs({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ColumnConstraintSettings(
    editor: editor,
    draft: draft,
    defaultEditor: switch (draft.fields.type.value) {
      .attachment => _AttachmentDefault(editor: editor, draft: draft),
      .reference => _ColumnReferenceDefault(editor: editor, draft: draft),
      _ => null,
    },
  );
}

class const _ColumnConstraintSettings({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
  required final Widget? defaultEditor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fields = draft.fields;

    return WorkspaceColumnConstraints(
      draft: fields.constraints,
      column: _ColumnActions._column(editor.column?.id ?? '', fields),
      disabled: draft.action.pending,
      defaultEditor: defaultEditor,
    );
  }
}

class const _ColumnPreviewResult({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceColumnViolations(
    records: draft.violations.value,
    table: editor.table,
    onCorrect: editor.onBack,
    onReplace: editor.column?.id == editor.table.labelColumnId
        ? null
        : _replace,
    replacement: draft.replacement.value,
  );
  void _replace() {
    draft.replacement.value = true;
    draft.violations.value = [];
  }
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

typedef _ColumnReferenceDraft = ({
  ValueNotifier<String?> tableId,
  ValueNotifier<bool> multiple,
  ValueNotifier<String?> parent,
  ValueNotifier<String?> match,
});
_ColumnReferenceDraft _referenceDraft(WorkspaceColumn? column) => (
  tableId: useState(column?.targetTableId),
  multiple: useState(column?.referenceMultiple ?? false),
  parent: useState(column?.dependsOnColumnId),
  match: useState(column?.targetMatchColumnId),
);
({String? tableId, bool multiple}) _referenceConfiguration(
  _ColumnFields fields,
) => fields.type.value == .reference
    ? (
        tableId: fields.reference.tableId.value,
        multiple: fields.reference.multiple.value,
      )
    : (tableId: null, multiple: false);

class const _ColumnDraftReference({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => draft.fields.type.value != .reference
      ? const SizedBox.shrink()
      : Column(
          children: [
            _ReferenceTargetDraft(editor: editor, draft: draft),
            _ReferenceDependencyDraft(editor: editor, draft: draft),
          ],
        );
}

class const _ReferenceTargetDraft({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceReferenceTarget(
    workspaceId: editor.workspaceId,
    targetTableId: draft.fields.reference.tableId,
    multiple: draft.fields.reference.multiple,
    disabled: draft.action.pending,
  );
}

class const _ReferenceDependencyDraft({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reference = draft.fields.reference;

    return WorkspaceReferenceDependency(
      workspaceId: editor.workspaceId,
      table: editor.table,
      columnId: editor.column?.id,
      targetTableId: reference.tableId.value,
      parent: reference.parent,
      match: reference.match,
      disabled: draft.action.pending,
    );
  }
}

class const _ColumnBasicInputs({
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
    ],
  );
}

class _ColumnValue {
  new(this.id, this.fields, ({String? tableId, bool multiple}) reference)
    : _target = reference.tableId,
      _multiple = reference.multiple,
      _parent = fields.type.value == .reference
          ? fields.reference.parent.value
          : null,
      _match = fields.type.value == .reference
          ? fields.reference.match.value
          : null;
  final String id;
  final _ColumnFields fields;
  final String? _target;
  final bool _multiple;
  final String? _parent;
  final String? _match;
  String get _name => fields.name.text;
  WorkspaceColumnType get _type => fields.type.value;
  List<String> get _options => _ColumnActions._options(fields);
  bool get _required => fields.constraints.required.value;
  bool get _unique => fields.constraints.unique.value;
  String get _timeZone => fields.timeZone.value;
  WorkspaceColumn build() => WorkspaceColumn(
    id: id,
    name: _name,
    type: _type,
    options: _options,
    isRequired: _required,
    isUnique: _unique,
    defaultValue: _defaultValue(fields),
    timeZone: _timeZone,
    targetTableId: _target,
    referenceMultiple: _multiple,
    dependsOnColumnId: _parent,
    targetMatchColumnId: _match,
  );
}

class const _ColumnReferenceDefault({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final column = _ColumnActions._column(
      editor.column?.id ?? '',
      draft.fields,
    );

    return column.targetTableId == null
        ? const TextLocale(LocaleKeys.workspace_items_reference_choose_target)
        : _ReferenceDefaultChoice(editor: editor, draft: draft, column: column);
  }
}

class const _ReferenceDefaultChoice({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
  required final WorkspaceColumn column,
}) extends StatelessWidget {
  ValueNotifier<Object?> get _value => draft.fields.constraints.defaultValue;
  @override
  Widget build(BuildContext context) => WorkspaceReferenceField(
    workspaceId: editor.workspaceId,
    table: editor.table,
    column: column,
    value: _value.value,
    disabled: draft.action.pending,
    restricted: false,
    onChanged: (value) => _value.value = value,
    onUnset: _unset,
    schemaDefault: true,
  );
  void _unset() => _value.value = null;
}

Object? _defaultValue(_ColumnFields fields) =>
    fields.constraints.defaultValue.value;

class const _AttachmentDefault({
  required final WorkspaceColumnEditor editor,
  required final _ColumnDraft draft,
}) extends StatelessWidget {
  ValueNotifier<Object?> get _value => draft.fields.constraints.defaultValue;

  @override
  Widget build(BuildContext context) {
    final value = _value.value;

    return WorkspaceAttachmentField(
      workspaceId: editor.workspaceId,
      label: LocaleKeys.workspace_items_default_value.tr(),
      value: value,
      present: value != null,
      disabled: draft.action.pending,
      restricted: false,
      onChanged: (value) => _value.value = value,
      onUnset: _unset,
    );
  }

  void _unset() => _value.value = null;
}
