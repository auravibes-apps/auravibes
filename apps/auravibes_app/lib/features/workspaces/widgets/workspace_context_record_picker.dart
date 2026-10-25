import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_minimum_viewport.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceContextRecordPicker({
  required final String workspaceId,
  required final WorkspaceTable table,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = useState('');
    final offset = useState(0);
    final selected = useState(<String>{});
    final query = WorkspaceRecordQuery(
      search: search.value,
      offset: offset.value,
    );
    final page = ref.watch(
      workspaceRecordQueryProvider(workspaceId, table.id, query),
    );
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 650),
        child: WorkspaceMinimumViewport(
          minimumHeight: enlarged ? 600 : 440,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TextLocale(LocaleKeys.workspace_chat_records),
                const TextLocale(LocaleKeys.workspace_chat_scope),
                TextField(
                  decoration: InputDecoration(
                    labelText: LocaleKeys.workspace_items_search.tr(),
                  ),
                  onChanged: (value) {
                    search.value = value;
                    offset.value = 0;
                  },
                ),
                Expanded(child: _records(page, selected)),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: offset.value == 0
                          ? null
                          : () => offset.value = (offset.value - query.limit)
                                .clamp(0, offset.value),
                      child: const TextLocale(
                        LocaleKeys.workspace_items_previous_page,
                      ),
                    ),
                    TextButton(
                      onPressed: page.value?.hasMore == true && !page.isLoading
                          ? () => offset.value += query.limit
                          : null,
                      child: const TextLocale(
                        LocaleKeys.workspace_items_next_page,
                      ),
                    ),
                  ],
                ),
                Text(
                  LocaleKeys.workspace_items_bulk_selected.tr(
                    namedArgs: {'count': '${selected.value.length}'},
                  ),
                ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const TextLocale(LocaleKeys.common_cancel),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(selected.value.toList()),
                      child: const TextLocale(LocaleKeys.workspace_chat_share),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(ValueNotifier<Set<String>> selected, String id, bool? value) {
    final next = {...selected.value};
    if (value == true) {
      next.add(id);
    } else {
      next.remove(id);
    }
    selected.value = next;
  }

  Widget _records(
    AsyncValue<WorkspaceRecordPage> page,
    ValueNotifier<Set<String>> selected,
  ) {
    if (page.isLoading) return const Center(child: CircularProgressIndicator());
    return switch (page) {
      AsyncData(:final value) => ListView(
        children: [
          const TextLocale(LocaleKeys.workspace_chat_structure),
          for (final record in value.records)
            CheckboxListTile(
              title: Text('${record.values[table.labelColumnId] ?? record.id}'),
              subtitle: Text(record.id),
              value: selected.value.contains(record.id),
              onChanged:
                  !selected.value.contains(record.id) &&
                      selected.value.length >= 50
                  ? null
                  : (value) => _toggle(selected, record.id, value),
            ),
        ],
      ),
      AsyncError(:final error) => WorkspaceItemFailure(error: error),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}
