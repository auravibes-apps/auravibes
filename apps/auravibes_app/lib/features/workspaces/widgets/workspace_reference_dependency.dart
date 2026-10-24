import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceDependency({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final String? columnId,
  required final String? targetTableId,
  required final ValueNotifier<String?> parent,
  required final ValueNotifier<String?> match,
  required final bool disabled,
  super.key,
}) extends ConsumerWidget {
  List<WorkspaceColumn> get parents => table.columns
      .where((column) => column.id != columnId && _parent(column))
      .toList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = targetTableId;
    final schema = target == null
        ? null
        : ref.watch(workspaceTableProvider(workspaceId, target));

    return Column(
      children: [
        _SourceDependency(field: this),
        _TargetDependency(field: this, target: schema),
      ],
    );
  }
}

class const _SourceDependency({
  required final WorkspaceReferenceDependency field,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DependencyChoice(
    label: const TextLocale(LocaleKeys.workspace_items_reference_parent),
    columns: field.parents,
    value: field.parent.value,
    disabled: field.disabled,
    onChanged: _change,
  );
  void _change(String? value) {
    field.parent.value = value;
    field.match.value = null;
  }
}

class const _TargetDependency({
  required final WorkspaceReferenceDependency field,
  required final AsyncValue<WorkspaceTable>? target,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final parent = _selectedParent(field);
    if (parent == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (target case AsyncData(value: final table))
          _MatchDependency(field: field, table: table, parent: parent),
        const TextLocale(LocaleKeys.workspace_items_reference_dependency_hint),
      ],
    );
  }
}

class const _MatchDependency({
  required final WorkspaceReferenceDependency field,
  required final WorkspaceTable table,
  required final WorkspaceColumn parent,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DependencyChoice(
    label: const TextLocale(LocaleKeys.workspace_items_reference_match),
    columns: _matches(table, parent),
    value: field.match.value,
    disabled: field.disabled,
    onChanged: (value) => field.match.value = value,
  );
}

List<WorkspaceColumn> _matches(WorkspaceTable table, WorkspaceColumn parent) =>
    table.columns
        .where(
          (column) =>
              _parent(column) && column.targetTableId == parent.targetTableId,
        )
        .toList();

bool _parent(WorkspaceColumn column) =>
    column.type == .reference &&
    !column.referenceMultiple &&
    column.dependsOnColumnId == null;

class const _DependencyChoice({
  required final Widget label,
  required final List<WorkspaceColumn> columns,
  required final String? value,
  required final bool disabled,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  String? get _selectedValue =>
      columns.any((column) => column.id == value) ? value : '';
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      _noDependency,
      for (final column in columns)
        AuraDropdownOption(value: column.id, child: Text(column.name)),
    ],
    value: _selectedValue,
    onChanged: disabled ? null : _change,
    label: label,
    isEnabled: !disabled,
  );
  void _change(String? value) => onChanged(value == '' ? null : value);
}

WorkspaceColumn? _selectedParent(WorkspaceReferenceDependency field) => field
    .parents
    .where((column) => column.id == field.parent.value)
    .firstOrNull;

const _noDependency = AuraDropdownOption<String>(
  value: '',
  child: TextLocale(LocaleKeys.workspace_items_reference_no_dependency),
);
