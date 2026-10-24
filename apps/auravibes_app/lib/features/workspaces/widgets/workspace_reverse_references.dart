import 'package:auravibes_app/features/workspaces/models/workspace_reference_page.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_row.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceReverseReferences({
  required final String workspaceId,
  required final WorkspaceRecord record,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _ReverseState(this, ref, (
      expanded: useState(false),
      cursor: useState<String?>(null),
    ));
    final page = useFuture(useMemoized(state.load, state.dependencies));

    return _ReverseBody(state: state, page: page);
  }
}

typedef _ReverseDraft = ({
  ValueNotifier<bool> expanded,
  ValueNotifier<String?> cursor,
});

class const _ReverseState(
  final WorkspaceReverseReferences widget,
  final WidgetRef ref,
  final _ReverseDraft draft,
) {
  List<Object?> get dependencies => [draft.expanded.value, draft.cursor.value];
  set next(String id) => draft.cursor.value = id;
  Future<WorkspaceReferencePage?> load() async {
    if (!draft.expanded.value) return null;
    final references = await ref.read(
      workspaceReferencesUsecaseProvider(widget.workspaceId).future,
    );

    return await references.reverse(
      tableId: widget.record.tableId,
      recordId: widget.record.id,
      afterId: draft.cursor.value,
    );
  }

  void toggle() => draft.expanded.value = !draft.expanded.value;
}

class const _ReverseBody({
  required final _ReverseState state,
  required final AsyncSnapshot<WorkspaceReferencePage?> page,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AuraButton(
        onPressed: state.toggle,
        child: const TextLocale(LocaleKeys.workspace_items_reference_reverse),
      ),
      if (state.draft.expanded.value) _ReverseResults(state: state, page: page),
    ],
  );
}

class const _ReverseResults({
  required final _ReverseState state,
  required final AsyncSnapshot<WorkspaceReferencePage?> page,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (page.hasError) {
      return const TextLocale(LocaleKeys.workspace_items_reference_unavailable);
    }
    if (page.connectionState != ConnectionState.done) {
      return const CircularProgressIndicator();
    }

    return _ReverseList(
      state: state,
      page: page.data ?? const WorkspaceReferencePage(records: []),
    );
  }
}

class const _ReverseList({
  required final _ReverseState state,
  required final WorkspaceReferencePage page,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (page.records.isEmpty)
        const TextLocale(LocaleKeys.workspace_items_reference_empty),
      for (final record in page.records)
        WorkspaceReferenceRow(
          workspaceId: state.widget.workspaceId,
          record: record,
        ),
      _ReverseNext(state: state, nextId: page.nextId),
    ],
  );
}

class const _ReverseNext({
  required final _ReverseState state,
  required final String? nextId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => nextId == null
      ? const SizedBox.shrink()
      : AuraButton(
          onPressed: () => state.next = nextId ?? '',
          child: const TextLocale(LocaleKeys.workspace_items_reference_next),
        );
}
