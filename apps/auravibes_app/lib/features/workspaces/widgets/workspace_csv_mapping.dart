import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceCsvMapping({
  required final WorkspaceCsvInput input,
  required final WorkspaceTable table,
  required final Map<int, String> mapping,
  required final ValueChanged<Map<int, String>> onChanged,
  required final bool enabled,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      for (var index = 0; index < input.headers.length; index++)
        _ColumnMapping(owner: this, index: index),
    ],
  );

  Map<int, String> _updated(int index, String? value) {
    final next = {...mapping};
    if (value == null || value.isEmpty) {
      final _ = next.remove(index);
    } else {
      next[index] = value;
    }

    return next;
  }
}

class const _ColumnMapping({
  required final WorkspaceCsvMapping owner,
  required final int index,
}) extends StatelessWidget {
  static const _skip = TextLocale('workspace_csv.skip');

  String get _title => owner.input.headers[index];

  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      const AuraDropdownOption(value: '', child: _skip),
      for (final column in owner.table.columns) _ColumnOption(column),
    ],
    value: owner.mapping[index],
    onChanged: _changed,
    placeholder: _skip,
    label: Text(_title),
    isEnabled: owner.enabled,
    identifier: 'workspace_csv_mapping_$index',
  );
  void _changed(String? value) => owner.onChanged(owner._updated(index, value));
}

class _ColumnOption extends AuraDropdownOption<String> {
  new(WorkspaceColumn column)
    : super(value: column.id, child: Text(column.name));
}
