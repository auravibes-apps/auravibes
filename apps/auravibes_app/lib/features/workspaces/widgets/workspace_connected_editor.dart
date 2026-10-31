import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_inputs.dart';
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
  final bool embedded = false,
  super.key,
}) extends HookWidget {
  void submit(WidgetRef ref, _ReadTool? target, _EditState state) {
    if (target == null) return;
    unawaited(state.action.run(() => _save(ref, target, state)));
  }

  Future<void> remove(WidgetRef ref) => _persist(ref, null);

  @override
  Widget build(BuildContext context) =>
      _EditorForm(this, _editState(context, view));

  Future<void> _save(WidgetRef ref, _ReadTool target, _EditState state) =>
      _persist(ref, _binding(target, state), edited: _edited(state));

  WorkspaceView _edited(_EditState state) {
    if (!view.isConnectedOnly) return view;

    return view.edited(
      name: view.name,
      definition: _definition(
        state.layout.text,
        requiresUserAction: view.action != null,
      ),
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

typedef _EditState = ({
  ValueNotifier<String?> tool,
  ValueNotifier<String?> connection,
  TextEditingController inputs,
  TextEditingController bindings,
  TextEditingController layout,
  WorkspaceTableAction action,
});

_EditState _editState(BuildContext context, WorkspaceView view) => (
  tool: useState(view.connected?.toolId),
  connection: useState(view.connected?.connectionId),
  inputs: _useJsonController(view.connected?.inputs ?? const {}),
  bindings: _useJsonController(view.bindings),
  layout: _useJsonController(view.definition.toJson()),
  action: WorkspaceTableActions.use(context),
);

TextEditingController _useJsonController(Object value) =>
    useTextEditingController(text: jsonEncode(value));

const _inputLines = 8;
const _bindingLines = 5;
const _buttonSpacing = 8.0;

class const _EditorForm(
  final WorkspaceConnectedEditor owner,
  final _EditState state,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(workspaceToolsProvider(owner.workspaceId));

    return switch (tools) {
      AsyncData(:final value) => _ReadyEditor(owner, state, _choices(value)),
      AsyncError(:final error) => WorkspaceItemFailure(error: error),
      AsyncLoading() => const CircularProgressIndicator(),
    };
  }
}

class const _ReadyEditor(
  final WorkspaceConnectedEditor owner,
  final _EditState state,
  final List<_ReadTool> choices,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final target = choices
        .where((item) => _id(item) == state.tool.value)
        .firstOrNull;

    return _EditorBody(
      _EditorFields(owner, state, choices, target),
      embedded: owner.embedded,
    );
  }
}

class _EditorFields extends Column {
  new(
    WorkspaceConnectedEditor owner,
    _EditState state,
    List<_ReadTool> choices,
    _ReadTool? target,
  ) : super(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          const TextLocale(LocaleKeys.workspace_connected_configure),
          const TextLocale(LocaleKeys.workspace_connected_disclosure),
          if (choices.isEmpty)
            const TextLocale(LocaleKeys.workspace_connected_no_reads)
          else
            _ToolPicker(state, choices, target),
          if (target?.tool.requiresConnection == true)
            _ConnectionPicker(owner.workspaceId, state, target),
          if (target != null)
            WorkspaceConnectedInputs(
              tool: target.tool,
              controller: state.inputs,
              key: ValueKey(_id(target)),
            ),
          if (owner.view.isConnectedOnly) _ProjectionFields(state),
          if (state.action.error case final error?)
            WorkspaceItemFailure(error: error),
          _EditorActions(owner, state, target),
        ],
      );
}

class const _EditorBody(final Widget child, {required final bool embedded})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => embedded
      ? child
      : SingleChildScrollView(padding: const EdgeInsets.all(16), child: child);
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
    if (state.tool.value == value) return;
    state.tool.value = value;
    state.connection.value = null;
    state.inputs.text = '{}';
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
      AsyncData(:final value) => _ConnectionSelector(value, state.connection),
      AsyncError(:final error) => WorkspaceItemFailure(error: error),
      AsyncLoading() => const CircularProgressIndicator(),
    };
  }
}

class _ConnectionSelector extends AuraDropdownSelector<String> {
  new(
    List<ConnectorConnectionCandidate> choices,
    ValueNotifier<String?> selected,
  ) : super(
        options: choices
            .map<AuraDropdownOption<String>>(_ConnectionOption.new)
            .toList(),
        value: _currentConnection(choices, selected.value),
        onChanged: (value) => selected.value = value,
        label: const TextLocale(LocaleKeys.workspace_connected_connection),
        identifier: 'workspace_connected_connection',
      );
}

class _ConnectionOption extends AuraDropdownOption<String> {
  new(ConnectorConnectionCandidate choice)
    : super(value: choice.id, child: Text(choice.name));
}

String? _currentConnection(
  List<ConnectorConnectionCandidate> choices,
  String? selected,
) => choices.any((choice) => choice.id == selected) ? selected : null;

class const _ProjectionFields(final _EditState state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const TextLocale(LocaleKeys.workspace_views_bindings),
    children: [
      AuraInput(
        controller: state.bindings,
        label: const TextLocale(LocaleKeys.workspace_views_bindings),
        maxLines: _bindingLines,
      ),
      AuraInput(
        controller: state.layout,
        label: const TextLocale(LocaleKeys.workspace_views_edit),
        maxLines: _inputLines,
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
  Widget build(BuildContext context, WidgetRef ref) =>
      _Buttons(owner, state, target, ref);
}

class _Buttons extends Wrap {
  new(
    WorkspaceConnectedEditor owner,
    _EditState state,
    _ReadTool? target,
    WidgetRef ref,
  ) : super(
        spacing: _buttonSpacing,
        children: [
          AuraButton(
            onPressed: () => owner.submit(ref, target, state),
            child: const TextLocale(LocaleKeys.common_save),
            isLoading: state.action.pending,
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
              onPressed: () =>
                  unawaited(state.action.run(() => owner.remove(ref))),
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
A2uiSavedDefinition _definition(
  String value, {
  required bool requiresUserAction,
}) => .fromJson(
  Map<String, Object?>.from(jsonDecode(value) as Map),
  requiresUserAction: requiresUserAction,
);

class _ReadOption extends AuraDropdownOption<String> {
  new(_ReadTool choice)
    : super(
        value: _id(choice),
        child: Text('${choice.connector.title}: ${choice.tool.title}'),
      );
}

String _id(_ReadTool value) => connectorToolId(value.connector, value.tool);
List<_ReadTool> _choices(List<WorkspaceToolEntity> tools) {
  final ids = _enabledIds(tools);

  return _tools().where((target) => ids.contains(_id(target))).toList();
}

Set<String> _enabledIds(List<WorkspaceToolEntity> tools) => {
  for (final tool in tools)
    if (tool.isEnabled && tool.permissionMode != .alwaysDeny) tool.toolId,
};
List<_ReadTool> _tools() => [
  for (final connector in connectorDefinitions)
    for (final tool in connector.tools)
      if (tool.urlTemplate != null && !connectorToolWrites(tool))
        (connector: connector, tool: tool),
];
