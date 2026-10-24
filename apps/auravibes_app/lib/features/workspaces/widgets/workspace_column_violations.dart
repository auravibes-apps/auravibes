import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceColumnViolations({
  required final List<WorkspaceRecord> records,
  required final WorkspaceTable table,
  required final VoidCallback onCorrect,
  required final VoidCallback? onReplace,
  required final bool replacement,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (replacement)
        const TextLocale(LocaleKeys.workspace_items_replacement_column),
      if (records.isNotEmpty) _ViolationDetails(view: this),
    ],
  );
}

class const _ViolationDetails({required final WorkspaceColumnViolations view})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_items_constraint_violations),
      for (final record in view.records)
        _ViolationRecord(
          record: record,
          labelColumnId: view.table.labelColumnId,
        ),
      AuraButton(
        onPressed: view.onCorrect,
        child: const TextLocale(LocaleKeys.workspace_items_correct_records),
      ),
      if (view.onReplace case final replace?)
        AuraButton(
          onPressed: replace,
          child: const TextLocale(
            LocaleKeys.workspace_items_replacement_column,
          ),
        ),
    ],
  );
}

class const _ViolationRecord({
  required final WorkspaceRecord record,
  required final String labelColumnId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text('${record.values[labelColumnId] ?? ''} (${record.id})');
}
