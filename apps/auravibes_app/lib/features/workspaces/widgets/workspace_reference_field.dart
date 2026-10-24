import 'package:auravibes_app/features/workspaces/models/workspace_reference_value.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_picker.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceField({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn column,
  required final Object? value,
  required final bool disabled,
  required final bool restricted,
  required final ValueChanged<Object?> onChanged,
  required final VoidCallback onUnset,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Text(column.name),
      if (restricted)
        const TextLocale(LocaleKeys.workspace_items_reference_unavailable)
      else ...[
        for (final id in WorkspaceReferenceValue.ids(value))
          _SelectedRecord(
            workspaceId: workspaceId,
            tableId: column.targetTableId ?? '',
            id: id,
          ),
        AuraButton(
          onPressed: disabled ? null : () => _pick(context),
          child: const TextLocale(LocaleKeys.workspace_items_reference_choose),
        ),
        if (!disabled && value != null)
          AuraButton(
            onPressed: onUnset,
            child: const TextLocale(
              LocaleKeys.workspace_items_reference_remove,
            ),
          ),
      ],
    ],
  );

  Future<void> _pick(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: 720,
        height: 620,
        child: WorkspaceReferencePicker(
          workspaceId: workspaceId,
          table: table,
          column: column,
          selected: WorkspaceReferenceValue.ids(value),
          onSelected: (ids) {
            if (ids.isEmpty) {
              onUnset();
            } else {
              onChanged(column.referenceMultiple ? ids : ids.single);
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    ),
  );
}

class const _SelectedRecord({
  required final String workspaceId,
  required final String tableId,
  required final String id,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(workspaceTableProvider(workspaceId, tableId));
    final rows = ref.watch(workspaceTableRecordsProvider(workspaceId, tableId));
    return switch ((table, rows)) {
      (AsyncData(value: final table), AsyncData(value: final records)) => Text(
        records
                .where((row) => row.id == id)
                .firstOrNull
                ?.values[table.labelColumnId]
                ?.toString() ??
            LocaleKeys.workspace_items_reference_unavailable.tr(),
      ),
      (AsyncError(), _) || (_, AsyncError()) => const TextLocale(
        LocaleKeys.workspace_items_reference_unavailable,
      ),
      _ => const CircularProgressIndicator(),
    };
  }
}
