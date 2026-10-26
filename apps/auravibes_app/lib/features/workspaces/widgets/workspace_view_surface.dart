import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_view_action_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/submit_workspace_view_action_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface_data.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart'
    show CloudWorkspaceException;
import 'package:auravibes_ui/ui.dart';
import 'package:genui/genui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Renders a saved surface. Only a view with an explicit saved action is
/// interactive, and its action still goes through the host authorization path.
class WorkspaceViewSurface extends ConsumerStatefulWidget {
  const new({
    required this.data,
    this.connectedModel,
    this.workspaceId,
    this.recordId,
    super.key,
  });
  final Map<String, Object?>? connectedModel;
  final WorkspaceViewData data;
  final String? workspaceId;
  final String? recordId;

  @override
  ConsumerState<WorkspaceViewSurface> createState() =>
      _WorkspaceViewSurfaceState();
}

class _WorkspaceViewSurfaceState extends ConsumerState<WorkspaceViewSurface> {
  SurfaceController _controller = .new(catalogs: auraChatCatalogs());
  var _failed = false;
  var _submitting = false;
  String? _statusKey;
  Map<String, String> _formErrors = const {};

  bool get _canSubmit {
    final action = widget.data.view.action;

    return widget.workspaceId != null &&
        action != null &&
        (action.type != A2uiSavedActionType.updateSelectedRecord ||
            widget.recordId != null);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WorkspaceViewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) ||
        !identical(oldWidget.connectedModel, widget.connectedModel)) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const TextLocale(LocaleKeys.workspace_views_repair);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _SurfaceUpdates(
          _controller,
          interactive: _canSubmit,
          submitting: _submitting,
        ),
        if (_canSubmit) ...[
          AuraButton(
            onPressed: _pressSubmit,
            child: _submitting
                ? const TextLocale(LocaleKeys.workspace_views_action_submitting)
                : const TextLocale(LocaleKeys.workspace_views_action_submit),
            key: const ValueKey('workspace_view_action_submit'),
            isFullWidth: true,
            disabled: _submitting,
          ),
          if (_statusKey case final status?) TextLocale(status),
          for (final error in _formErrors.entries)
            Text('${error.key}: ${error.value}'),
        ],
      ],
    );
  }

  void _load() {
    _reset();
    try {
      _render();
    } on Object {
      _failed = true;
    }
  }

  void _reset() {
    _disposeController();
    _controller = .new(catalogs: auraChatCatalogs());
    _failed = false;
  }

  void _disposeController() => _controller.dispose();

  void _pressSubmit() => unawaited(_submit());

  void _render() {
    activeA2uiWireCodec
        .decodeAll(
          WorkspaceViewSurfaceData.envelope(widget.data, widget.connectedModel),
        )
        .forEach(_handle);
  }

  void _handle(A2uiDecodeResult decoded) {
    final operation = decoded.envelope?.operation;
    if (operation == null) {
      _failed = true;

      return;
    }
    _controller.handleMessage(.fromJson(operation.json));
  }

  Future<void> _submit() async {
    final workspaceId = widget.workspaceId;
    final view = widget.data.view;
    final action = view.action;
    if (workspaceId == null || action == null || _submitting) return;
    setState(() {
      _submitting = true;
      _statusKey = null;
      _formErrors = const {};
    });
    try {
      final root = _controller
          .contextFor('view')
          .dataModel
          .getValue<Object?>(.root);
      if (root is! Map) throw const WorkspaceTableException();
      final values = Map<String, Object?>.from(root);
      final usecase = await ref.read(
        workspaceViewActionUsecaseProvider(workspaceId).future,
      );
      final result = await usecase.call(
        workspaceId: workspaceId,
        viewId: view.id,
        expectedRevision: view.revision,
        formValues: values,
        recordId: widget.recordId,
        approve: _approve,
      );
      if (!mounted) return;
      final resultStatus = _resultStatus(result);
      if (resultStatus == 'cancelled') return;
      setState(() {
        _statusKey = _statusKeyFor(resultStatus);
        if (result is Map && result['errorsByPath'] is Map) {
          _formErrors = Map<String, String>.from(
            result['errorsByPath']! as Map,
          );
        }
      });
      if (resultStatus == 'completed') {
        ref
          ..invalidate(workspaceViewDataProvider(workspaceId, view.id))
          ..invalidate(workspaceConnectedViewProvider(workspaceId, view.id));
      }
    } on WorkspaceViewFormValidationException catch (error) {
      if (!mounted) return;
      setState(() {
        _statusKey = LocaleKeys.workspace_views_action_invalid;
        _formErrors = error.errorsByPath;
      });
    } on WorkspaceTableException catch (error) {
      if (!mounted) return;
      setState(() => _statusKey = _tableErrorKey(error));
    } on CloudWorkspaceException catch (error) {
      if (!mounted) return;
      setState(() => _statusKey = _cloudErrorKey(error));
    } on AgentToolExecutionFailure catch (error) {
      if (!mounted) return;
      setState(() => _statusKey = _connectorErrorKey(error));
    } on Object {
      if (!mounted) return;
      setState(() => _statusKey = LocaleKeys.workspace_connected_failed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _approve({
    required WorkspaceView view,
    required A2uiSavedAction action,
    required Map<String, Object?> values,
  }) async {
    final details = _approvalValues(action, values, widget.data.table.columns);

    return await showDialog<bool>(
          context: context,
          builder: (_) =>
              _ActionApprovalDialog(viewName: view.name, details: details),
        ) ??
        false;
  }
}

Map<String, Object?> _approvalValues(
  A2uiSavedAction action,
  Map<String, Object?> values,
  List<WorkspaceColumn> columns,
) {
  final columnNames = {for (final column in columns) column.id: column.name};

  return {
    for (final entry in action.inputs.entries)
      columnNames[entry.key] ?? entry.key: values[entry.key],
  };
}

String _resultStatus(Object? result) {
  if (result == false) return 'cancelled';
  if (result == true) return 'completed';
  if (result is Map && result['status'] is String) {
    final status = result['status']! as String;
    final code = result['code'];

    return switch (status) {
      'completed' when result['viewChangedDuringExecution'] == true =>
        'completedChanged',
      'completed' => 'completed',
      'partial' => 'partial',
      'validationFailed' => 'invalid',
      'denied' => 'denied',
      'uncertain' => 'uncertain',
      'failed'
          when code == 'stale_contract' ||
              code == 'invalid_tool_arguments' ||
              code == 'unknown_tool' =>
        'repair',
      'failed'
          when code == 'connection_unavailable' ||
              code == 'connection_required' ||
              code == 'connection_selection_required' =>
        'disconnected',
      'failed' => 'failed',
      _ => 'failed',
    };
  }
  if (result is Map && result['outcome'] is String) {
    return switch (result['outcome']) {
      'completed' => 'completed',
      'uncertain' when result['statusCode'] == 207 => 'partial',
      'uncertain' => 'uncertain',
      'failed' => 'failed',
      _ => 'failed',
    };
  }

  return 'failed';
}

String _statusKeyFor(String status) => switch (status) {
  'completed' => LocaleKeys.workspace_views_action_completed,
  'completedChanged' => LocaleKeys.workspace_views_action_completed_changed,
  'partial' => LocaleKeys.workspace_views_action_partial,
  'invalid' => LocaleKeys.workspace_views_action_invalid,
  'denied' => LocaleKeys.workspace_connected_denied,
  'uncertain' => LocaleKeys.workspace_views_action_uncertain,
  'repair' => LocaleKeys.workspace_connected_repair,
  'disconnected' => LocaleKeys.workspace_connected_disconnected,
  _ => LocaleKeys.workspace_connected_failed,
};

String _tableErrorKey(WorkspaceTableException error) => error.conflict
    ? LocaleKeys.workspace_views_action_changed
    : switch (error.denied) {
        true => LocaleKeys.workspace_connected_denied,
        false => LocaleKeys.workspace_connected_repair,
      };

String _cloudErrorKey(CloudWorkspaceException error) => switch (error.code) {
  .staleRevision || .conflict => LocaleKeys.workspace_views_action_changed,
  .permissionDenied ||
  .membershipRequired ||
  .authenticationRequired => LocaleKeys.workspace_connected_denied,
  .validationFailed => LocaleKeys.workspace_views_action_invalid,
  _ => LocaleKeys.workspace_connected_repair,
};

String _connectorErrorKey(AgentToolExecutionFailure error) {
  try {
    final decoded = jsonDecode(error.responseRaw);
    if (decoded is Map && decoded['error'] is Map) {
      final code = (decoded['error'] as Map)['code'];
      if (code == 'tool_access_denied' || code == 'denied') {
        return LocaleKeys.workspace_connected_denied;
      }
      if (code == 'stale_contract' || code == 'invalid_tool_arguments') {
        return LocaleKeys.workspace_connected_repair;
      }
    }
    if (decoded is Map && decoded['statusCode'] == 207) {
      return LocaleKeys.workspace_views_action_partial;
    }
  } on FormatException {
    return error.resultStatus == AgentToolResultStatus.uncertain
        ? LocaleKeys.workspace_views_action_uncertain
        : LocaleKeys.workspace_connected_failed;
  }

  return error.resultStatus == AgentToolResultStatus.uncertain
      ? LocaleKeys.workspace_views_action_uncertain
      : LocaleKeys.workspace_connected_failed;
}

class const _ActionApprovalDialog({
  required final String viewName,
  required final Map<String, Object?> details,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            const TextLocale(LocaleKeys.workspace_views_action_review),
            const SizedBox(height: 8),
            Text(viewName),
            const SizedBox(height: 8),
            const TextLocale(LocaleKeys.workspace_views_action_approval),
            const SizedBox(height: 8),
            SelectableText(const JsonEncoder.withIndent('  ').convert(details)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: .end,
              children: [
                AuraButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const TextLocale(LocaleKeys.common_cancel),
                  variant: .ghost,
                ),
                const SizedBox(width: 8),
                AuraButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const TextLocale(
                    LocaleKeys.workspace_views_action_submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class const _SurfaceUpdates(
  final SurfaceController controller, {
  required final bool interactive,
  required final bool submitting,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<SurfaceUpdate>(
    stream: controller.surfaceUpdates,
    builder: (_, _) => _ReadySurface(
      controller,
      interactive: interactive,
      submitting: submitting,
    ),
  );
}

class _ReadOnlyActions implements ActionDelegate {
  const new();
  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genuiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) => true;
}

class const _ReadySurface(
  final SurfaceController controller, {
  required final bool interactive,
  required final bool submitting,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInteractionScope(
    policy: interactive && !submitting
        ? const AuraInteractionPolicy.interactive()
        : const AuraInteractionPolicy.readOnly(),
    child: Surface(
      surfaceContext: controller.contextFor('view'),
      actionDelegate: const _ReadOnlyActions(),
    ),
  );
}
