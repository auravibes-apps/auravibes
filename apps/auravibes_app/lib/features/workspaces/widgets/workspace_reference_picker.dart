import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/browse_workspace_references_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_record_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_row.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReferencePicker({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final WorkspaceColumn column,
  required final List<String> selected,
  required final ValueChanged<List<String>> onSelected,
  final bool schemaDefault = false,
  final bool queryFilter = false,
  final String? parentId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _PickerState.use(this, ref);
    final references = ref.watch(
      workspaceReferencesUsecaseProvider(workspaceId).future,
    );
    final page = useFuture(
      useMemoized(state.load, [references, ...state.dependencies]),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _PickerBody(state: state, page: page),
    );
  }
}

class const _PickerState(
  final WorkspaceReferencePicker picker,
  final WidgetRef ref,
  final _PickerDraft draft,
) {
  factory use(WorkspaceReferencePicker picker, WidgetRef ref) =>
      _PickerState(picker, ref, (
        selected: useState(_initialSelection(picker)),
        search: useState(''),
        cursor: useState<String?>(null),
        refresh: useState(0),
      ));
  bool get multiple => !picker.queryFilter && picker.column.referenceMultiple;
  String? get selectedId => multiple || draft.selected.value.isEmpty
      ? null
      : draft.selected.value.first;
  List<Object?> get dependencies => [
    draft.search.value,
    draft.cursor.value,
    draft.refresh.value,
  ];
  Future<WorkspaceReferencePage> load() async {
    final usecase = await ref.read(
      workspaceReferencesUsecaseProvider(picker.workspaceId).future,
    );

    if (picker.schemaDefault || picker.queryFilter) {
      return await _defaultPage(this, usecase);
    }

    return await _sourcePage(this, usecase);
  }

  void search(String value) {
    draft.search.value = value;
    draft.cursor.value = null;
  }

  void retry() => draft.refresh.value++;
  void select(String id) {
    if (picker.queryFilter || !picker.column.referenceMultiple) {
      draft.selected.value = {id};

      return;
    }
    final next = {...draft.selected.value};
    if (!next.remove(id)) {
      final _ = next.add(id);
    }
    draft.selected.value = next;
  }

  Future<void> create(BuildContext context, WorkspaceTable table) =>
      WorkspaceReferenceRecordDialog.open(context, picker.workspaceId, (
        table: table,
        record: null,
        onSaved: _created,
      ));
  void done() => picker.onSelected(draft.selected.value.toList());
  void clear() => draft.selected.value = {};

  void _created(WorkspaceRecord record) {
    select(record.id);
    retry();
  }
}

Set<String> _initialSelection(WorkspaceReferencePicker picker) =>
    (!picker.queryFilter && picker.column.referenceMultiple
            ? picker.selected
            : picker.selected.take(1))
        .toSet();

typedef _PickerDraft = ({
  ValueNotifier<Set<String>> selected,
  ValueNotifier<String> search,
  ValueNotifier<String?> cursor,
  ValueNotifier<int> refresh,
});

class const _PickerBody({
  required final _PickerState state,
  required final AsyncSnapshot<WorkspaceReferencePage> page,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _PickerHeader(state: state),
      Expanded(
        child: _ReferenceResults(state: state, page: page),
      ),
      _PickerPages(state: state, nextId: page.data?.nextId),
    ],
  );
}

class const _PickerHeader({required final _PickerState state})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(
      workspaceTableProvider(
        state.picker.workspaceId,
        state.picker.column.targetTableId ?? '',
      ),
    );
    final name = target.asData?.value.name ?? state.picker.column.name;

    return Column(
      children: [
        TextLocale(
          LocaleKeys.workspace_items_reference_picker_title,
          args: [name],
        ),
        AuraInput(
          label: const TextLocale(LocaleKeys.workspace_items_reference_search),
          onChanged: state.search,
        ),
        _PickerCreate(state: state),
      ],
    );
  }
}

class const _PickerCreate({required final _PickerState state})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => state.picker.queryFilter
      ? const SizedBox.shrink()
      : _CreateTarget(
          state: state,
          target: ref.watch(
            workspaceTableProvider(
              state.picker.workspaceId,
              state.picker.column.targetTableId ?? '',
            ),
          ),
        );
}

class const _CreateTarget({
  required final _PickerState state,
  required final AsyncValue<WorkspaceTable> target,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (target) {
    AsyncData(value: final table) when table.canEditRecords => AuraButton(
      onPressed: () => state.create(context, table),
      child: const TextLocale(LocaleKeys.workspace_items_create_record),
    ),
    AsyncData() || AsyncLoading() || AsyncError() => const SizedBox.shrink(),
  };
}

class const _PickerPages({
  required final _PickerState state,
  required final String? nextId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _NextPage(state: state, nextId: nextId),
      _FirstPage(state: state),
      Row(
        children: [
          if (state.draft.selected.value.isNotEmpty) ...[
            TextLocale(
              LocaleKeys.workspace_items_reference_selection_count,
              args: ['${state.draft.selected.value.length}'],
            ),
            const Spacer(),
            AuraButton(
              onPressed: state.clear,
              child: const TextLocale(
                LocaleKeys.workspace_items_reference_remove,
              ),
            ),
          ] else
            const Spacer(),
          AuraButton(
            onPressed: state.done,
            child: const TextLocale(LocaleKeys.workspace_items_reference_apply),
          ),
        ],
      ),
    ],
  );
}

class const _ReferenceResults({
  required final _PickerState state,
  required final AsyncSnapshot<WorkspaceReferencePage> page,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (page.hasError) {
      return _PickerFailure(state: state);
    }
    if (page.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    return _ReferenceList(
      state: state,
      records: page.data?.records ?? const [],
    );
  }
}

class const _PickerFailure({required final _PickerState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_items_reference_unavailable),
      AuraButton(
        onPressed: state.retry,
        child: const TextLocale(LocaleKeys.quick_switcher_retry),
      ),
    ],
  );
}

class const _ReferenceList({
  required final _PickerState state,
  required final List<WorkspaceRecord> records,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => records.isEmpty
      ? const TextLocale(LocaleKeys.workspace_items_reference_empty)
      : ListView(
          children: [
            for (final record in records)
              _PickerRow(state: state, record: record),
          ],
        );
}

class const _PickerRow({
  required final _PickerState state,
  required final WorkspaceRecord record,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceReferenceRow(
    workspaceId: state.picker.workspaceId,
    record: record,
    selected: state.draft.selected.value.contains(record.id),
    selectedId: state.selectedId,
    multiple: state.multiple,
    onSelect: () => state.select(record.id),
  );
}

class const _NextPage({
  required final _PickerState state,
  required final String? nextId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => nextId == null
      ? const SizedBox.shrink()
      : AuraButton(
          onPressed: () => state.draft.cursor.value = nextId,
          child: const TextLocale(LocaleKeys.workspace_items_reference_next),
        );
}

class const _FirstPage({required final _PickerState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => state.draft.cursor.value == null
      ? const SizedBox.shrink()
      : AuraButton(
          onPressed: () => state.draft.cursor.value = null,
          child: const TextLocale(
            LocaleKeys.workspace_items_reference_previous,
          ),
        );
}

Future<WorkspaceReferencePage> _defaultPage(
  _PickerState state,
  BrowseWorkspaceReferencesUsecase usecase,
) => usecase.tableTargets(
  tableId: state.picker.column.targetTableId ?? '',
  search: state.draft.search.value,
  afterId: state.draft.cursor.value,
);
Future<WorkspaceReferencePage> _sourcePage(
  _PickerState state,
  BrowseWorkspaceReferencesUsecase usecase,
) => usecase.targets(
  parentId: state.picker.parentId,
  source: (tableId: state.picker.table.id, columnId: state.picker.column.id),
  search: state.draft.search.value,
  afterId: state.draft.cursor.value,
);
