import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_picker.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// Selects one permitted option or one currently authorized linked record.
class const WorkspaceQueryCollectionFilter({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn column,
  required final String? value,
  required final ValueChanged<String?> onChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      column.type == .multiSelect ? _Options(this) : _Reference(this);
}

class const _Options(final WorkspaceQueryCollectionFilter owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [
      for (final option in owner.column.options)
        AuraDropdownOption(value: option, child: Text(option)),
    ],
    value: owner.value,
    onChanged: owner.onChanged,
    label: Text(owner.column.name),
    identifier: 'workspace_filter_option',
  );
}

class const _Reference(final WorkspaceQueryCollectionFilter owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [Text(owner.column.name), _Selected(owner), _Choose(owner)],
  );
}

class const _Selected(final WorkspaceQueryCollectionFilter owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (owner.value) {
    final String id => WorkspaceReferenceLabel(
      workspaceId: owner.workspaceId,
      targetTableId: owner.column.targetTableId ?? '',
      recordId: id,
    ),
    _ => const SizedBox.shrink(),
  };
}

class const _Choose(final WorkspaceQueryCollectionFilter owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => _pick(context),
    child: const TextLocale(LocaleKeys.workspace_items_reference_choose),
    identifier: 'workspace_filter_reference',
  );
  Future<void> _pick(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => _ReferenceDialog(owner),
  );
}

class const _ReferenceDialog(final WorkspaceQueryCollectionFilter owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Dialog(child: SizedBox(width: 720, height: 620, child: _Picker(owner)));
}

class const _Picker(final WorkspaceQueryCollectionFilter owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceReferencePicker(
    workspaceId: owner.workspaceId,
    table: owner.table,
    column: owner.column,
    selected: [?owner.value],
    onSelected: (ids) => _select(context, ids),
    queryFilter: true,
  );
  void _select(BuildContext context, List<String> ids) {
    owner.onChanged(ids.firstOrNull);
    Navigator.of(context).pop();
  }
}
