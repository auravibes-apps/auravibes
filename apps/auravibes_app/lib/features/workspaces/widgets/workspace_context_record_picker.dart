import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _PickerState = ({
  ValueNotifier<String> search,
  ValueNotifier<int> offset,
  ValueNotifier<Set<String>> selected,
});

class const WorkspaceContextRecordPicker({
  required final String workspaceId,
  required final WorkspaceTable table,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final state = (
      search: useState(''),
      offset: useState(0),
      selected: useState(<String>{}),
    );

    return _PickerFrame(_PickerContents(workspaceId, table, state));
  }
}

class const _PickerFrame(final Widget content) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const .new(maxWidth: 560, maxHeight: 650),
      child: SingleChildScrollView(
        child: Padding(padding: const .all(16), child: content),
      ),
    ),
  );
}

class const _PickerContents(
  final String workspaceId,
  final WorkspaceTable table,
  final _PickerState state,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _PickerHeader(state),
      _RecordPage(workspaceId, table, state),
      _PickerFooter(workspaceId, table.id, state),
    ],
  );
}

class const _PickerHeader(final _PickerState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_chat_records),
      TextField(
        decoration: InputDecoration(
          labelText: LocaleKeys.workspace_items_search.tr(),
        ),
        onChanged: _search,
      ),
    ],
  );

  void _search(String value) {
    state.search.value = value;
    state.offset.value = 0;
  }
}

class const _PickerFooter(
  final String workspaceId,
  final String tableId,
  final _PickerState state,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        children: [
          _PreviousPage(state),
          _NextPage(workspaceId, tableId, state),
        ],
      ),
      _SelectionCount(state.selected.value.length),
      _PickerActions(state.selected.value),
    ],
  );
}

class const _PreviousPage(final _PickerState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: state.offset.value == 0 ? null : _previous,
    child: const TextLocale(LocaleKeys.workspace_items_previous_page),
  );

  void _previous() {
    final offset = state.offset.value;
    final previous = offset - const WorkspaceRecordQuery().limit;
    state.offset.value = previous.clamp(0, offset);
  }
}

class const _NextPage(
  final String workspaceId,
  final String tableId,
  final _PickerState state,
) extends ConsumerWidget {
  WorkspaceRecordQuery get query =>
      .new(search: state.search.value, offset: state.offset.value);

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: _enabled(_page(ref)) ? _next : null,
    child: const TextLocale(LocaleKeys.workspace_items_next_page),
  );

  AsyncValue<WorkspaceRecordPage> _page(WidgetRef ref) =>
      ref.watch(workspaceRecordQueryProvider(workspaceId, tableId, query));

  bool _enabled(AsyncValue<WorkspaceRecordPage> page) =>
      !page.isLoading && page.value?.hasMore == true;

  void _next() => state.offset.value += query.limit;
}

class const _SelectionCount(final int count) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.workspace_items_bulk_selected.tr(namedArgs: {'count': '$count'}),
  );
}

class const _PickerActions(final Set<String> selected) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const TextLocale(LocaleKeys.common_cancel),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(selected.toList()),
        child: const TextLocale(LocaleKeys.workspace_chat_share),
      ),
    ],
  );
}

class const _RecordPage(
  final String workspaceId,
  final WorkspaceTable table,
  final _PickerState state,
) extends ConsumerWidget {
  WorkspaceRecordQuery get query =>
      .new(search: state.search.value, offset: state.offset.value);

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (_page(ref)) {
    AsyncData(:final value) => _RowsContent(
      value.records,
      state.selected,
      table.labelColumnId,
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };

  AsyncValue<WorkspaceRecordPage> _page(WidgetRef ref) =>
      ref.watch(workspaceRecordQueryProvider(workspaceId, table.id, query));
}

class const _RowsContent(
  final List<WorkspaceRecord> records,
  final ValueNotifier<Set<String>> selected,
  final String labelColumnId,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      const TextLocale(LocaleKeys.workspace_chat_scope),
      const TextLocale(LocaleKeys.workspace_chat_structure),
      for (final record in records)
        _RecordChoice(record, selected, labelColumnId),
    ],
  );
}

class const _RecordChoice(
  final WorkspaceRecord record,
  final ValueNotifier<Set<String>> selected,
  final String labelColumnId,
) extends StatelessWidget {
  static const maximumSelected = 50;
  bool get checked => selected.value.contains(record.id);
  bool get locked => !checked && selected.value.length >= maximumSelected;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: checked,
    onChanged: locked ? null : _toggle,
    title: _RecordTitle(record, labelColumnId),
    subtitle: Text(record.id, overflow: .ellipsis, maxLines: 1),
  );

  void _toggle(bool? value) {
    final next = {...selected.value};
    if (value == true) {
      final _ = next.add(record.id);
    } else {
      final _ = next.remove(record.id);
    }
    selected.value = next;
  }
}

class const _RecordTitle(final WorkspaceRecord record, final String columnId)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    '${record.values[columnId] ?? record.id}',
    overflow: .ellipsis,
    maxLines: 2,
  );
}
