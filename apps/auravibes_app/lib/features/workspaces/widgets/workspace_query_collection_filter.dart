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
  Widget build(BuildContext context) => column.type == .multiSelect
      ? AuraDropdownSelector<String>(
          identifier: 'workspace_filter_option',
          value: value,
          label: Text(column.name),
          options: [
            for (final option in column.options)
              AuraDropdownOption(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        )
      : Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(column.name),
            if (value case final String id)
              WorkspaceReferenceLabel(
                workspaceId: workspaceId,
                targetTableId: column.targetTableId ?? '',
                recordId: id,
              ),
            AuraButton(
              identifier: 'workspace_filter_reference',
              onPressed: () => _pick(context),
              child: const TextLocale(
                LocaleKeys.workspace_items_reference_choose,
              ),
            ),
          ],
        );
  Future<void> _pick(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: SizedBox(
        width: 720,
        height: 620,
        child: WorkspaceReferencePicker(
          workspaceId: workspaceId,
          table: table,
          column: column,
          selected: [if (value case final id?) id],
          queryFilter: true,
          onSelected: (ids) {
            onChanged(ids.firstOrNull);
            Navigator.of(dialogContext).pop();
          },
        ),
      ),
    ),
  );
}
