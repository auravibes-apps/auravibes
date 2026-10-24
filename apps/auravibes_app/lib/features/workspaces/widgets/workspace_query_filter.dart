import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_query_filter_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_query_collection_filter.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceQueryFilter({
  required final WorkspaceTable table,
  required final String workspaceId,
  required final ValueNotifier<WorkspaceRecordQuery> query,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => _FilterFields(.new(this));
}

class _FilterDraft {
  new(this.owner)
    : columnId = useState(owner.query.value.filterColumnId),
      operator = useState(owner.query.value.filterOperator),
      value = useState<Object?>(_initial(owner).values.firstOrNull);
  final WorkspaceQueryFilter owner;
  final ValueNotifier<String?> columnId;
  final ValueNotifier<WorkspaceRecordFilterOperator> operator;
  final ValueNotifier<Object?> value;
  WorkspaceColumn? get column => owner.table.columns
      .where((column) => column.id == columnId.value)
      .firstOrNull;
  bool get contains => operator.value == .contains;
  bool get valid => switch (column) {
    final WorkspaceColumn current => WorkspaceQueryFilterValidation.accepts(
      current,
      value.value,
      contains: contains,
    ),
    _ => false,
  };
  void select(String? id) {
    columnId.value = id;
    operator.value = column?.type == .multiSelect ? .contains : .equals;
    value.value = switch (column?.type) {
      .checkbox => false,
      .text => '',
      _ => null,
    };
    owner.query.value = owner.query.value.filter(null, '');
  }

  void apply() {
    if (!valid) return;
    final encoded = column?.type == .money
        ? jsonEncode(value.value)
        : value.value.toString();
    owner.query.value = owner.query.value.filter(
      columnId.value,
      encoded,
      operator: operator.value,
    );
  }

  static Map<String, Object?> _initial(WorkspaceQueryFilter owner) {
    final column = _initialColumn(owner);
    if (column == null) return {};

    return WorkspaceQueryFilterValidation.parse(
      column,
      owner.query.value.filterValue ?? '',
      contains: owner.query.value.filterOperator == .contains,
    );
  }

  static WorkspaceColumn? _initialColumn(WorkspaceQueryFilter owner) => owner
      .table
      .columns
      .where((column) => column.id == owner.query.value.filterColumnId)
      .firstOrNull;
}

class const _FilterFields(final _FilterDraft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _FilterColumn(draft),
      if (draft.column case final column?) ...[
        _Operator(draft, column),
        _Value(draft, column),
        if (draft.value.value != null && !draft.valid)
          const TextLocale(LocaleKeys.workspace_items_filter_invalid_value),
        _FilterActions(draft),
      ],
    ],
  );
}

class const _FilterColumn(final _FilterDraft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      const AuraDropdownOption(
        value: '',
        child: TextLocale(LocaleKeys.workspace_items_all_columns),
      ),
      for (final column in draft.owner.table.columns)
        _FilterColumnOption(column),
    ],
    value: draft.columnId.value ?? '',
    onChanged: draft.select,
    label: const TextLocale(LocaleKeys.common_filters),
  );
}

class _FilterColumnOption extends AuraDropdownOption<String> {
  new(WorkspaceColumn column)
    : super(
        value: column.id,
        child: Text(column.name),
        isEnabled: WorkspaceQueryFilterValidation.supportsFilter(column),
      );
}

class const _Operator(final _FilterDraft draft, final WorkspaceColumn column)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraDropdownSelector<WorkspaceRecordFilterOperator>(
        options: [
          if (column.type != .multiSelect) _OperatorOption(.equals),
          if (WorkspaceQueryFilterValidation.supportsContains(column))
            _OperatorOption(.contains),
        ],
        value: draft.operator.value,
        onChanged: _change,
        label: const TextLocale(LocaleKeys.workspace_items_filter_operator),
      );
  void _change(WorkspaceRecordFilterOperator? value) {
    if (value != null) draft.operator.value = value;
  }
}

class _OperatorOption
    extends AuraDropdownOption<WorkspaceRecordFilterOperator> {
  new(WorkspaceRecordFilterOperator operator)
    : super(
        value: operator,
        child: TextLocale(
          operator == .equals
              ? LocaleKeys.workspace_items_filter_equals
              : LocaleKeys.workspace_items_filter_contains,
        ),
      );
}

class const _Value(final _FilterDraft draft, final WorkspaceColumn column)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      column.type == .multiSelect || column.type == .reference
      ? _CollectionValue(draft, column)
      : _ScalarValue(draft, column);
}

class const _CollectionValue(
  final _FilterDraft draft,
  final WorkspaceColumn column,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final owner = draft.owner;

    return WorkspaceQueryCollectionFilter(
      workspaceId: owner.workspaceId,
      table: owner.table,
      column: column,
      value: draft.value.value as String?,
      onChanged: (value) => draft.value.value = value,
      key: ValueKey(column.id),
    );
  }
}

class const _ScalarValue(final _FilterDraft draft, final WorkspaceColumn column)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceRecordField(
    column: column,
    value: draft.value.value,
    present: true,
    disabled: false,
    identifier: 'workspace_filter_value',
    onChanged: (value) => draft.value.value = value,
    onUnset: _unset,
    showPresence: false,
    key: ValueKey(column.id),
  );
  void _unset() => draft.value.value = null;
}

class const _FilterActions(final _FilterDraft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      AuraButton(
        onPressed: draft.apply,
        child: const TextLocale(LocaleKeys.workspace_items_filter_apply),
        disabled: !draft.valid,
        identifier: 'workspace_filter_apply',
      ),
      AuraButton(
        onPressed: _clear,
        child: const TextLocale(LocaleKeys.workspace_items_filter_clear),
        identifier: 'workspace_filter_clear',
      ),
    ],
  );
  void _clear() => draft.select(null);
}
