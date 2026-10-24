import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferenceTarget({
  required final String workspaceId,
  required final ValueNotifier<String?> targetTableId,
  required final ValueNotifier<bool> multiple,
  required final bool disabled,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parent = useState<String?>(null);
    return Column(
      children: [
        const TextLocale(LocaleKeys.workspace_items_reference_table),
        if (targetTableId.value case final id?)
          _SelectedTable(workspaceId: workspaceId, id: id),
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: const TextLocale(LocaleKeys.workspace_items_root),
          onTap: disabled ? null : () => parent.value = null,
        ),
        switch (ref.watch(
          workspaceFoldersProvider(workspaceId, parent.value),
        )) {
          AsyncData(value: final folders) => Column(
            children: [
              for (final folder in folders)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  onTap: disabled ? null : () => parent.value = folder.id,
                ),
            ],
          ),
          AsyncError() => const TextLocale(
            LocaleKeys.workspace_items_reference_unavailable,
          ),
          AsyncLoading() => const CircularProgressIndicator(),
        },
        switch (ref.watch(workspaceTablesProvider(workspaceId, parent.value))) {
          AsyncData(value: final tables) => Column(
            children: [
              for (final table in tables)
                AuraCheckboxListTile(
                  value: targetTableId.value == table.id,
                  onChanged: (_) => targetTableId.value = table.id,
                  title: Text(table.name),
                  semanticLabel: table.name,
                  disabled: disabled,
                ),
            ],
          ),
          AsyncError() => const TextLocale(
            LocaleKeys.workspace_items_reference_unavailable,
          ),
          AsyncLoading() => const CircularProgressIndicator(),
        },
        AuraCheckboxListTile(
          value: multiple.value,
          onChanged: (value) => multiple.value = value,
          title: const TextLocale(
            LocaleKeys.workspace_items_reference_multiple,
          ),
          disabled: disabled,
        ),
      ],
    );
  }
}

class const _SelectedTable({
  required final String workspaceId,
  required final String id,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(workspaceTableProvider(workspaceId, id))) {
        AsyncData(value: final WorkspaceTable table) => Text(table.name),
        AsyncError() => const TextLocale(
          LocaleKeys.workspace_items_reference_unavailable,
        ),
        AsyncLoading() => const CircularProgressIndicator(),
      };
}
