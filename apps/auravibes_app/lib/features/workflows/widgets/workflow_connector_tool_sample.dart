import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/service_connections/models/connector_connection_candidate.dart';
import 'package:auravibes_app/features/service_connections/models/connector_tool_catalog_item.dart';
import 'package:auravibes_app/features/service_connections/providers/connector_tool_catalog_provider.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workflows/models/workflow_connector_output_inference.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workflows/models/workflow_field_schema_codec.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/usecases/workflow_connector_tool_sample_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_inputs.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class WorkflowConnectorToolSample extends ConsumerStatefulWidget {
  const new({
    required this.workspaceId,
    required this.workflow,
    required this.node,
    required this.editor,
    super.key,
  });

  final String workspaceId;
  final WorkspaceWorkflow workflow;
  final WorkflowNode node;
  final WorkflowEditorNotifier editor;

  @override
  ConsumerState<WorkflowConnectorToolSample> createState() =>
      _WorkflowConnectorToolSampleState();
}

class _WorkflowConnectorToolSampleState
    extends ConsumerState<WorkflowConnectorToolSample> {
  final _inputs = TextEditingController(text: '{}');
  final _outputSample = TextEditingController();
  String? _connectionId;
  bool _pending = false;
  bool _invalidSample = false;
  bool _failed = false;

  @override
  void dispose() {
    _inputs.dispose();
    _outputSample.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref
        .watch(connectorToolCatalogProvider)
        .where((candidate) => candidate.toolId == widget.node.targetId)
        .firstOrNull;
    final definition = item?.toolDefinition;
    final connectorId = item?.connectorId;
    if (item == null || definition == null || connectorId == null) {
      return const TextLocale(LocaleKeys.workflow_editor_tool_unavailable);
    }

    final isWrite = connectorToolWrites(definition);
    final workspaceTools = ref.watch(
      workspaceToolsProvider(widget.workspaceId),
    );
    final workspaceTool = switch (workspaceTools) {
      AsyncData(:final value) =>
        value.where((tool) => tool.toolId == item.toolId).firstOrNull,
      AsyncLoading() || AsyncError() => null,
    };
    final hasWorkspaceAccess =
        workspaceTool?.isEnabled == true &&
        workspaceTool?.permissionMode != ToolPermissionMode.alwaysDeny;
    final connections = !isWrite && item.requiresConnection
        ? ref.watch(
            workspaceConnectedConnectionsProvider(
              widget.workspaceId,
              connectorId,
            ),
          )
        : null;
    final canSample =
        isWrite || (hasWorkspaceAccess && _hasUsableConnection(connections));

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const Divider(),
        const TextLocale(LocaleKeys.workflow_editor_sample_outputs),
        const TextLocale(LocaleKeys.workflow_editor_samples_not_saved),
        const SizedBox(height: 8),
        if (isWrite) ...[
          AuraInput(
            controller: _outputSample,
            label: const TextLocale(
              LocaleKeys.workflow_editor_output_sample_json,
            ),
            maxLines: 8,
          ),
          if (_invalidSample)
            const TextLocale(LocaleKeys.workflow_editor_invalid_json_sample),
          AuraButton(
            onPressed: _inferPastedSample,
            child: const TextLocale(LocaleKeys.workflow_editor_infer_outputs),
            disabled: _pending,
          ),
        ] else ...[
          const TextLocale(LocaleKeys.workflow_editor_sample_inputs),
          WorkspaceConnectedInputs(tool: definition, controller: _inputs),
          if (workspaceTools.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: AuraSpinner()),
            )
          else if (workspaceTools.hasError)
            const TextLocale(LocaleKeys.workflow_editor_sample_failed)
          else if (!hasWorkspaceAccess)
            const TextLocale(
              LocaleKeys.workflow_editor_sample_requires_tool_access,
            ),
          if (item.requiresConnection)
            _WorkflowSampleConnectionPicker(
              connections: connections,
              connectionId: _connectionId,
              onChanged: (value) => setState(() => _connectionId = value),
              onRetry: () => ref.invalidate(
                workspaceConnectedConnectionsProvider(
                  widget.workspaceId,
                  connectorId,
                ),
              ),
            ),
          if (_invalidSample)
            const TextLocale(LocaleKeys.workflow_editor_invalid_sample_inputs),
          AuraButton(
            onPressed: _startReadSample,
            child: const TextLocale(LocaleKeys.workflow_editor_run_read_sample),
            isLoading: _pending,
            disabled: _pending || !canSample,
          ),
        ],
        if (_failed) const TextLocale(LocaleKeys.workflow_editor_sample_failed),
      ],
    );
  }

  bool _hasUsableConnection(
    AsyncValue<List<ConnectorConnectionCandidate>>? connections,
  ) => switch (connections) {
    null => true,
    AsyncData(value: [final _]) => true,
    AsyncData(:final value) => value.any(
      (connection) => connection.id == _connectionId,
    ),
    AsyncLoading() || AsyncError() => false,
  };

  void _inferPastedSample() {
    Object? sample;
    try {
      sample = jsonDecode(_outputSample.text);
    } on FormatException {
      setState(() {
        _invalidSample = true;
        _failed = false;
      });

      return;
    }

    unawaited(_applySample(sample));
  }

  void _startReadSample() => unawaited(_runReadSample());

  Future<void> _runReadSample() async {
    final arguments = _decodeInputs(_inputs.text);
    if (arguments == null) {
      setState(() {
        _invalidSample = true;
        _failed = false;
      });

      return;
    }
    final item = ref
        .read(connectorToolCatalogProvider)
        .where((candidate) => candidate.toolId == widget.node.targetId)
        .firstOrNull;
    if (item == null) return;
    final connectionId = _resolvedConnectionId(item);
    setState(() {
      _pending = true;
      _invalidSample = false;
      _failed = false;
    });

    try {
      final sample = await ref.read(
        workflowConnectorToolSampleUsecaseProvider(widget.workspaceId).future,
      );
      final result = await sample(
        workspaceId: widget.workspaceId,
        toolId: item.toolId,
        arguments: arguments,
        connectionId: connectionId,
      );
      if (!mounted) return;
      await _applySample(result);
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  String? _resolvedConnectionId(ConnectorToolCatalogItem item) {
    final connectorId = item.connectorId;
    if (!item.requiresConnection || connectorId == null) return null;
    final connections = ref.read(
      workspaceConnectedConnectionsProvider(widget.workspaceId, connectorId),
    );

    return switch (connections) {
      AsyncData(value: [final only]) => only.id,
      AsyncData() || AsyncLoading() || AsyncError() => _connectionId,
    };
  }

  Future<void> _applySample(Object? sample) async {
    final current = _currentSchema();
    final outputs = WorkflowConnectorOutputInference.merge(
      current: current,
      sample: sample,
      hasSampledOutputs: widget.node.hasSampledOutputs,
    );
    try {
      if (current.isEmpty) {
        widget.editor.commands().nodes.inferOutputs(widget.node.id, outputs);
      } else if (WorkflowFieldSchemaCodec.encode(current) !=
          WorkflowFieldSchemaCodec.encode(outputs)) {
        final choice = await _chooseSchemaScope();
        if (!mounted) return;
        switch (choice) {
          case _SampleSchemaChoice.local:
            widget.editor.commands().nodes.inferOutputs(
              widget.node.id,
              outputs,
            );
          case _SampleSchemaChoice.shared:
            await ref
                .read(workspaceToolsProvider(widget.workspaceId).notifier)
                .updateToolOutputSchema(
                  widget.node.targetId,
                  WorkflowFieldSchemaCodec.encode(outputs),
                );
            if (!widget.workflow.definition.localConnectorSchemas.containsKey(
              widget.node.targetId,
            )) {
              widget.editor.commands().nodes.useSharedConnectorSchema(
                widget.node.id,
                outputs,
              );
            }
          case _SampleSchemaChoice.keep || null:
            break;
        }
      }
      if (mounted) setState(() => _failed = false);
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        _inputs.text = '{}';
        _outputSample.clear();
        setState(() => _invalidSample = false);
      }
    }
  }

  List<WorkflowField> _currentSchema() {
    final local =
        widget.workflow.definition.localConnectorSchemas[widget.node.targetId];
    if (local != null) return local;
    final tools = ref.read(workspaceToolsProvider(widget.workspaceId));
    final tool = switch (tools) {
      AsyncData(:final value) =>
        value.where((item) => item.toolId == widget.node.targetId).firstOrNull,
      AsyncLoading(:final value?) =>
        value.where((item) => item.toolId == widget.node.targetId).firstOrNull,
      AsyncLoading() || AsyncError() => null,
    };
    return WorkflowFieldSchemaCodec.parse(tool?.outputSchemaJson) ??
        widget.node.outputFields;
  }

  Future<_SampleSchemaChoice?> _chooseSchemaScope() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const TextLocale(LocaleKeys.workflow_editor_schema_drift_title),
      content: const TextLocale(
        LocaleKeys.workflow_editor_schema_drift_message,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_SampleSchemaChoice.keep),
          child: const TextLocale(
            LocaleKeys.workflow_editor_schema_keep_current,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_SampleSchemaChoice.local),
          child: const TextLocale(
            LocaleKeys.workflow_editor_schema_create_local,
          ),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_SampleSchemaChoice.shared),
          child: const TextLocale(
            LocaleKeys.workflow_editor_schema_edit_shared,
          ),
        ),
      ],
    ),
  );
}

enum _SampleSchemaChoice { keep, local, shared }

class const _WorkflowSampleConnectionPicker({
  required final AsyncValue<List<ConnectorConnectionCandidate>>? connections,
  required final String? connectionId,
  required final ValueChanged<String?> onChanged,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (connections) {
    null => const SizedBox.shrink(),
    AsyncLoading() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(child: AuraSpinner()),
    ),
    AsyncError() => Row(
      children: [
        const Expanded(
          child: TextLocale(LocaleKeys.workflow_editor_sample_failed),
        ),
        TextButton(
          onPressed: onRetry,
          child: const TextLocale(LocaleKeys.workflow_editor_retry),
        ),
      ],
    ),
    AsyncData(value: []) => const TextLocale(
      LocaleKeys.workflow_editor_sample_needs_connection,
    ),
    AsyncData(value: [final only]) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        LocaleKeys.workflow_editor_sample_using_connection.tr(
          context: context,
          namedArgs: {'name': only.name},
        ),
      ),
    ),
    AsyncData(:final value) => AuraDropdownSelector<String>(
      options: [
        for (final connection in value)
          AuraDropdownOption<String>(
            value: connection.id,
            child: Text(connection.name),
          ),
      ],
      value: value.any((item) => item.id == connectionId) ? connectionId : null,
      onChanged: onChanged,
      label: const TextLocale(LocaleKeys.workflow_editor_sample_connection),
      identifier: 'workflow_connector_sample_connection',
    ),
  };
}

Map<String, dynamic>? _decodeInputs(String source) {
  try {
    final value = jsonDecode(source);
    if (value is! Map || value.keys.any((key) => key is! String)) return null;

    return Map<String, dynamic>.from(value);
  } on FormatException {
    return null;
  }
}
