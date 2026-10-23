import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_type_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('workspace_column_editor');

class const WorkspaceColumnEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn? column,
  required final VoidCallback onBack,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController(text: column?.name ?? '');
    final type = useState(column?.type ?? WorkspaceColumnType.text);
    final options = useTextEditingController(
      text: column?.options.join('\n') ?? '',
    );
    final pending = useState(false);
    final error = useState<Object?>(null);
    final isLabel = column?.id == table.labelColumnId;
    Future<void> save() async {
      if (pending.value) return;
      pending.value = true;
      error.value = null;
      try {
        final usecase = await ref.read(
          workspaceTableUsecaseProvider(workspaceId).future,
        );
        final _ = await usecase.saveColumn(
          table: table,
          column: WorkspaceColumn(
            id: column?.id ?? '',
            name: name.text,
            type: type.value,
            options: type.value == .singleSelect || type.value == .multiSelect
                ? options.text
                      .split('\n')
                      .where((option) => option.trim().isNotEmpty)
                      .toList()
                : const [],
          ),
        );
        if (context.mounted) onBack();
      } on Object catch (failure, stackTrace) {
        _logger.warning(
          'Column save failed: ${failure.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) error.value = failure;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(table.name),
          onTap: pending.value ? null : onBack,
        ),
        AuraInput(
          controller: name,
          label: const TextLocale(LocaleKeys.workspace_items_column_name),
          enabled: !pending.value,
          identifier: 'workspace_column_name',
        ),
        AuraDropdownSelector<WorkspaceColumnType>(
          options: [
            for (final value in WorkspaceColumnType.values)
              if (!isLabel || value == .text)
                AuraDropdownOption(
                  value: value,
                  child: WorkspaceColumnTypeLabel(type: value),
                ),
          ],
          value: type.value,
          onChanged: pending.value
              ? null
              : (value) {
                  if (value != null) type.value = value;
                },
          label: const TextLocale(LocaleKeys.workspace_items_column_type),
          isEnabled: !pending.value,
          identifier: 'workspace_column_type',
        ),
        if (type.value == .singleSelect || type.value == .multiSelect)
          AuraInput(
            controller: options,
            label: const TextLocale(LocaleKeys.workspace_items_column_options),
            hint: const TextLocale(LocaleKeys.workspace_items_options_hint),
            enabled: !pending.value,
            maxLines: 6,
            identifier: 'workspace_column_options',
          ),
        AuraButton(
          onPressed: () => unawaited(save()),
          child: const TextLocale(LocaleKeys.workspace_items_save_typed_column),
          isLoading: pending.value,
          disabled: pending.value,
          identifier: 'workspace_column_save',
        ),
        if (error.value case final failure?)
          WorkspaceItemFailure(error: failure),
      ],
    );
  }
}
