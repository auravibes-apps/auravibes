import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
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

typedef _ReadTool = ({
  ConnectorDefinition connector,
  ConnectorToolDefinition tool,
});

class const WorkspaceConnectedEditor({
  required final String workspaceId,
  required final WorkspaceView view,
  required final VoidCallback onDone,
  final ValueChanged<WorkspaceView>? onSaved,
  super.key,
}) extends HookWidget {
  void submit(WidgetRef ref, _ReadTool? target, _EditState state) {
    if (target == null) return;
    unawaited(state.action.run(() => _save(ref, target, state)));
  }

  Future<void> remove(WidgetRef ref) => _persist(ref, null);

  @override
  Widget build(BuildContext context) => _EditorForm(this, .use(context, view));

  Future<void> _save(WidgetRef ref, _ReadTool target, _EditState state) =>
      _persist(ref, _binding(target, state), edited: _edited(state));

  WorkspaceView _edited(_EditState state) {
    if (!view.isConnectedOnly) return view;

    return view.edited(
      name: view.name,
      definition: _definition(state.layout.text),
      bindings: Map<String, String>.from(
        jsonDecode(state.bindings.text) as Map,
      ),
      columnTypes: const {},
    );
  }

  Future<void> _persist(
    WidgetRef ref,
    WorkspaceConnectedBinding? binding, {
    WorkspaceView? edited,
  }) async {
    final usecase = await ref.read(
      workspaceViewUsecaseProvider(workspaceId).future,
    );
    final saved = await usecase.save((edited ?? view).withConnected(binding));
    if (!ref.context.mounted) return;
    ref.invalidate(workspaceViewDataProvider(workspaceId, view.id));
    _complete(saved);
  }

  void _complete(WorkspaceView saved) {
    final callback = onSaved;
    if (callback == null) {
      onDone();
      return;
    }
    callback(saved);
  }
}

class const _EditState(
  final ValueNotifier<String?> tool,
  final ValueNotifier<String?> connection,
  final TextEditingController inputs,
  final TextEditingController bindings,
  final TextEditingController layout,
  final WorkspaceTableAction action,
) {
  factory use(BuildContext context, WorkspaceView view) => .new(
    useState(view.connected?.toolId),
    useState(view.connected?.connectionId),
    useTextEditingController(
      text: jsonEncode(view.connected?.inputs ?? const {}),
    ),
    useTextEditingController(text: jsonEncode(view.bindings)),
    useTextEditingController(text: jsonEncode(view.definition.toJson())),
    WorkspaceTableActions.use(context),
  );
}

class const _EditorForm(
  final WorkspaceConnectedEditor owner,
  final _EditState state,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = _enabled(ref, owner.workspaceId);
    final target = choices
        .where((item) => _id(item) == state.tool.value)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TextLocale(LocaleKeys.workspace_connected_configure),
        const TextLocale(LocaleKeys.workspace_connected_disclosure),
        _ToolPicker(state, choices, target),
        if (target?.tool.requiresConnection == true)
          _ConnectionPicker(owner.workspaceId, state, target),
        AuraInput(
          controller: state.inputs,
          label: const TextLocale(LocaleKeys.workspace_connected_inputs),
          maxLines: 8,
        ),
        if (owner.view.isConnectedOnly) _ProjectionFields(state),
        if (state.action.error case final error?)
          WorkspaceItemFailure(error: error),
        _EditorActions(owner, state, target),
      ],
    );
  }
}

class const _ToolPicker(
  final _EditState state,
  final List<_ReadTool> choices,
  final _ReadTool? target,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: [for (final choice in choices) _ReadOption(choice)],
    value: target == null ? null : state.tool.value,
    onChanged: _select,
    label: const TextLocale(LocaleKeys.workspace_connected_tool),
    identifier: 'workspace_connected_tool',
  );
  void _select(String? value) {
    state.tool.value = value;
    state.connection.value = null;
  }
}

class const _ConnectionPicker(
  final String workspaceId,
  final _EditState state,
  final _ReadTool? target,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = target?.connector.identifier;
    if (id == null) return const SizedBox.shrink();
    final choices = ref.watch(
      workspaceConnectedConnectionsProvider(workspaceId, id),
    );

    return switch (choices) {
      AsyncData(:final value) => AuraDropdownSelector<String>(
        options: [
          for (final item in value)
            AuraDropdownOption(value: item.id, child: Text(item.name)),
        ],
        value: value.any((item) => item.id == state.connection.value)
            ? state.connection.value
            : null,
        onChanged: (value) => state.connection.value = value,
        label: const TextLocale(LocaleKeys.workspace_connected_connection),
        identifier: 'workspace_connected_connection',
      ),
      AsyncError(:final error) => WorkspaceItemFailure(error: error),
      AsyncLoading() => const CircularProgressIndicator(),
    };
  }
}

class const _ProjectionFields(final _EditState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_views_bindings),
    children: [
      AuraInput(
        controller: state.bindings,
        label: const TextLocale(LocaleKeys.workspace_views_bindings),
        maxLines: 5,
      ),
      AuraInput(
        controller: state.layout,
        label: const TextLocale(LocaleKeys.workspace_views_edit),
        maxLines: 8,
      ),
    ],
  );
}

class const _EditorActions(
  final WorkspaceConnectedEditor owner,
  final _EditState state,
  final _ReadTool? target,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    children: [
      AuraButton(
        onPressed: () => owner.submit(ref, target, state),
        child: const TextLocale(LocaleKeys.common_save),
        disabled: state.action.pending || target == null,
        identifier: 'workspace_connected_save',
      ),
      AuraButton(
        onPressed: owner.onDone,
        child: const TextLocale(LocaleKeys.common_cancel),
        disabled: state.action.pending,
      ),
      if (owner.view.connected != null && !owner.view.isConnectedOnly)
        AuraButton(
          onPressed: () => unawaited(state.action.run(() => owner.remove(ref))),
          child: const TextLocale(LocaleKeys.workspace_connected_remove),
          disabled: state.action.pending,
        ),
    ],
  );
}

WorkspaceConnectedBinding _binding(_ReadTool target, _EditState state) => .new(
  toolId: _id(target),
  revision: connectorToolRevision(target.connector, target.tool),
  inputs: Map<String, Object?>.from(jsonDecode(state.inputs.text) as Map),
  connectionId: state.connection.value,
);
A2uiSavedDefinition _definition(String value) =>
    .fromJson(Map<String, Object?>.from(jsonDecode(value) as Map));

class _ReadOption extends AuraDropdownOption<String> {
  _ReadOption(_ReadTool choice)
    : super(
        value: _id(choice),
        child: Text('${choice.connector.title}: ${choice.tool.title}'),
      );
}

String _id(_ReadTool value) => connectorToolId(value.connector, value.tool);
List<_ReadTool> _enabled(WidgetRef ref, String workspaceId) {
  final enabled =
      ref.watch(workspaceToolsProvider(workspaceId)).value ?? const [];

  return _tools()
      .where(
        (target) =>
            enabled.any((tool) => tool.toolId == _id(target) && tool.isEnabled),
      )
      .toList();
}

List<_ReadTool> _tools() => [
  for (final connector in connectorDefinitions)
    for (final tool in connector.tools)
      if (tool.urlTemplate != null && !connectorToolWrites(tool))
        (connector: connector, tool: tool),
];
