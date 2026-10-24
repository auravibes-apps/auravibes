import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkspaceViewEditor({
  required final String workspaceId,
  required final WorkspaceViewData data,
  required final VoidCallback onDone,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => _Form(this, .use(context, data));
}

class const _EditState(
  final TextEditingController name,
  final TextEditingController layout,
  final ValueNotifier<Set<String>> selected,
  final WorkspaceTableAction action,
) {
  factory use(BuildContext context, WorkspaceViewData data) => _EditState(
    useTextEditingController(text: data.view.name),
    useTextEditingController(
      text: const JsonEncoder.withIndent('  ')
          .convert(data.view.definition.toJson()),
    ),
    useState(data.view.bindings.values.toSet()),
    WorkspaceTableActions.use(context),
  );

  WorkspaceView edited(WorkspaceViewData data) => data.view.edited(
    name: name.text,
    definition: _definition(),
    bindings: _bindings(data.view.bindings),
    columnTypes: _types(data),
  );
  void toggle(String id, {required bool checked}) {
    final next = {...selected.value};
    if (checked) {
      final _ = next.add(id);
    } else {
      final _ = next.remove(id);
    }
    selected.value = next;
  }

  A2uiSavedDefinition _definition() => A2uiSavedDefinition.fromJson(
    Map<String, Object?>.from(jsonDecode(layout.text) as Map),
  );
  Map<String, String> _types(WorkspaceViewData data) => {
    for (final column in data.table.columns)
      if (selected.value.contains(column.id)) column.id: column.type.name,
  };
  Map<String, String> _bindings(Map<String, String> existing) {
    final result = _selectedBindings(existing);
    for (final id in selected.value.where((id) => !result.containsValue(id))) {
      _addBinding(result, id);
    }

    return result;
  }

  Map<String, String> _selectedBindings(Map<String, String> existing) =>
      Map<String, String>.fromEntries(
        existing.entries.where((entry) => selected.value.contains(entry.value)),
      );

  void _addBinding(Map<String, String> bindings, String id) {
    var index = 0;
    while (bindings.containsKey('field$index')) {
      index++;
    }
    bindings['field$index'] = id;
  }
}

class const _Form(final WorkspaceViewEditor owner, final _EditState state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _Back(owner, state),
      _Name(state),
      _Fields(owner, state),
      _Layout(state),
      _Save(owner, state),
      if (state.action.error case final error?)
        WorkspaceItemFailure(error: error),
    ],
  );
}

class const _Back(final WorkspaceViewEditor owner, final _EditState state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: const ValueKey('workspace_view_editor_back'),
    leading: const Icon(Icons.arrow_back),
    title: Text(owner.data.view.name),
    onTap: state.action.pending ? null : owner.onDone,
  );
}

class const _Name(final _EditState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: state.name,
    label: const TextLocale(LocaleKeys.workspace_views_name),
    identifier: 'workspace_view_edit_name',
  );
}

class const _Fields(final WorkspaceViewEditor owner, final _EditState state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const TextLocale(LocaleKeys.workspace_views_bindings),
      for (final column in owner.data.table.columns)
        _Field(state, column.id, column.name),
    ],
  );
}

class const _Field(final _EditState state, final String id, final String name)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: state.selected.value.contains(id),
    onChanged: state.action.pending
        ? null
        : (value) => state.toggle(id, checked: value == true),
    title: Text(name),
  );
}

class const _Layout(final _EditState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_views_definition),
    children: [AuraInput(controller: state.layout, maxLines: 12)],
  );
}

class const _Save(final WorkspaceViewEditor owner, final _EditState state)
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operationId = useMemoized(const UuidV7().generate);

    return AuraButton(
      onPressed: () => _submit(context, ref, operationId),
      child: const TextLocale(LocaleKeys.workspace_views_save),
      isLoading: state.action.pending,
      disabled: state.action.pending,
      identifier: 'workspace_view_save',
    );
  }

  void _submit(BuildContext context, WidgetRef ref, String operationId) =>
      unawaited(state.action.run(() => _save(context, ref, operationId)));

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    String operationId,
  ) async {
    final usecase = await ref.read(
      workspaceViewUsecaseProvider(owner.workspaceId).future,
    );
    final _ = await usecase.save(
      state.edited(owner.data),
      requestId: operationId,
    );
    if (context.mounted) owner.onDone();
  }
}
