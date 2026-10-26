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

const _partialHttpStatusCode = 207;
const _submissionStatusMessages = <String, Widget>{
  LocaleKeys.workspace_views_action_completed: TextLocale(
    LocaleKeys.workspace_views_action_completed,
  ),
  LocaleKeys.workspace_views_action_completed_changed: TextLocale(
    LocaleKeys.workspace_views_action_completed_changed,
  ),
  LocaleKeys.workspace_views_action_partial: TextLocale(
    LocaleKeys.workspace_views_action_partial,
  ),
  LocaleKeys.workspace_views_action_invalid: TextLocale(
    LocaleKeys.workspace_views_action_invalid,
  ),
  LocaleKeys.workspace_views_action_changed: TextLocale(
    LocaleKeys.workspace_views_action_changed,
  ),
  LocaleKeys.workspace_views_action_uncertain: TextLocale(
    LocaleKeys.workspace_views_action_uncertain,
  ),
  LocaleKeys.workspace_connected_denied: TextLocale(
    LocaleKeys.workspace_connected_denied,
  ),
  LocaleKeys.workspace_connected_repair: TextLocale(
    LocaleKeys.workspace_connected_repair,
  ),
  LocaleKeys.workspace_connected_disconnected: TextLocale(
    LocaleKeys.workspace_connected_disconnected,
  ),
  LocaleKeys.workspace_connected_failed: TextLocale(
    LocaleKeys.workspace_connected_failed,
  ),
};

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
    _controller.dispose();
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

    return _SurfaceContent(
      controller: _controller,
      canSubmit: _canSubmit,
      submitting: _submitting,
      statusKey: _statusKey,
      formErrors: _formErrors,
      onSubmit: () => unawaited(_submit()),
    );
  }

  void _load() {
    _controller.dispose();
    _controller = .new(catalogs: auraChatCatalogs());
    _failed = false;
    try {
      _render();
    } on Object {
      _failed = true;
    }
  }

  void _render() {
    final decoded = activeA2uiWireCodec.decodeAll(
      WorkspaceViewSurfaceData.envelope(widget.data, widget.connectedModel),
    );
    for (final result in decoded) {
      final operation = result.envelope?.operation;
      if (operation == null) {
        _failed = true;

        return;
      }
      _controller.handleMessage(.fromJson(operation.json));
    }
  }

  Future<void> _submit() => _WorkspaceViewSubmissionController(this).submit();

  void _setSubmitting({required bool value, bool clearFeedback = false}) =>
      setState(() {
        _submitting = value;
        if (clearFeedback) {
          _statusKey = null;
          _formErrors = const {};
        }
      });

  void _applySubmissionFeedback(
    _SubmissionFeedback feedback,
    String workspaceId,
    String viewId,
  ) {
    if (feedback.cancelled) return;
    setState(() {
      _statusKey = feedback.statusKey;
      _formErrors = feedback.errorsByPath;
    });
    if (feedback.refresh) {
      ref
        ..invalidate(workspaceViewDataProvider(workspaceId, viewId))
        ..invalidate(workspaceConnectedViewProvider(workspaceId, viewId));
    }
  }
}

class const _WorkspaceViewSubmissionController(
  final _WorkspaceViewSurfaceState state,
) {
  Future<void> submit() async {
    final submission = _submission();
    if (submission == null || state._submitting) return;
    _begin();
    try {
      await _run(submission);
    } on Object catch (error) {
      if (state.mounted) {
        _showError(error, submission.workspaceId, submission.view.id);
      }
    } finally {
      if (state.mounted) _finish();
    }
  }

  ({String workspaceId, WorkspaceView view, String? recordId})? _submission() {
    final workspaceId = state.widget.workspaceId;
    final view = state.widget.data.view;
    if (workspaceId == null || view.action == null) return null;

    return (
      workspaceId: workspaceId,
      view: view,
      recordId: state.widget.recordId,
    );
  }

  void _begin() => state._setSubmitting(value: true, clearFeedback: true);

  void _finish() => state._setSubmitting(value: false);

  Future<void> _run(
    ({String workspaceId, WorkspaceView view, String? recordId}) submission,
  ) async {
    final result = await _formSubmission(submission);
    if (state.mounted) _showResult(result, submission);
  }

  Future<Object?> _formSubmission(
    ({String workspaceId, WorkspaceView view, String? recordId}) submission,
  ) => _WorkspaceViewFormSubmission(
    ref: state.ref,
    controller: state._controller,
    view: submission.view,
    workspaceId: submission.workspaceId,
    recordId: submission.recordId,
    approve: _approve,
  ).call();

  void _showResult(
    Object? result,
    ({String workspaceId, WorkspaceView view, String? recordId}) submission,
  ) {
    _SubmissionFeedback.fromResult(result)
        .apply(state, submission.workspaceId, submission.view.id);
  }

  void _showError(Object error, String workspaceId, String viewId) =>
      _SubmissionFeedback.fromError(error).apply(state, workspaceId, viewId);

  Future<bool> _approve({
    required WorkspaceView view,
    required A2uiSavedAction action,
    required Map<String, Object?> values,
  }) async {
    final details = _approvalValues(
      action,
      values,
      state.widget.data.table.columns,
    );

    return await showDialog<bool>(
          context: state.context,
          builder: (_) =>
              _ActionApprovalDialog(viewName: view.name, details: details),
        ) ??
        false;
  }
}

class const _WorkspaceViewFormSubmission({
  required final WidgetRef ref,
  required final SurfaceController controller,
  required final WorkspaceView view,
  required final String workspaceId,
  required final String? recordId,
  required final WorkspaceViewActionApproval approve,
}) {
  Future<Object?> call() async {
    final formValues = _formValues();
    final usecase = await ref.read(
      workspaceViewActionUsecaseProvider(workspaceId).future,
    );

    return await usecase.call(
      request: .new(
        workspaceId: workspaceId,
        viewId: view.id,
        expectedRevision: view.revision,
        formValues: formValues,
        recordId: recordId,
      ),
      approve: approve,
    );
  }

  Map<String, Object?> _formValues() {
    final root = controller
        .contextFor('view')
        .dataModel
        .getValue<Object?>(.root);
    if (root is! Map) throw const WorkspaceTableException();

    return Map<String, Object?>.from(root);
  }
}

class const _SubmissionFeedback({
  required final String? statusKey,
  required final Map<String, String> errorsByPath,
  final bool cancelled = false,
  final bool refresh = false,
}) {
  factory fromResult(Object? result) {
    final status = _resultStatus(result);

    return .new(
      statusKey: status == 'cancelled' ? null : _statusKeyFor(status),
      errorsByPath: _readErrors(result),
      cancelled: status == 'cancelled',
      refresh: status == 'completed',
    );
  }

  factory fromError(Object error) => switch (error) {
    WorkspaceViewFormValidationException(:final errorsByPath) => .new(
      statusKey: LocaleKeys.workspace_views_action_invalid,
      errorsByPath: errorsByPath,
    ),
    final WorkspaceTableException failure => .new(
      statusKey: _tableErrorKey(failure),
      errorsByPath: const {},
    ),
    final CloudWorkspaceException failure => .new(
      statusKey: _cloudErrorKey(failure),
      errorsByPath: const {},
    ),
    final AgentToolExecutionFailure failure => .new(
      statusKey: _connectorErrorKey(failure),
      errorsByPath: const {},
    ),
    _ => const .new(
      statusKey: LocaleKeys.workspace_connected_failed,
      errorsByPath: {},
    ),
  };

  void apply(
    _WorkspaceViewSurfaceState state,
    String workspaceId,
    String viewId,
  ) => state._applySubmissionFeedback(this, workspaceId, viewId);

  static Map<String, String> _readErrors(Object? result) {
    if (result is Map && result['errorsByPath'] is Map) {
      return Map<String, String>.from(result['errorsByPath']! as Map);
    }

    return const {};
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

  return switch (result) {
    {'status': final String status} => _WorkspaceViewResultStatus.action(
      status,
      result as Map<dynamic, dynamic>,
    ),
    {'outcome': final String outcome} => _WorkspaceViewResultStatus.external(
      outcome,
      result as Map<dynamic, dynamic>,
    ),
    _ => 'failed',
  };
}

abstract final class _WorkspaceViewResultStatus {
  static String action(String status, Map<dynamic, dynamic> result) =>
      switch (status) {
        'completed' when result['viewChangedDuringExecution'] == true =>
          'completedChanged',
        'completed' => 'completed',
        'partial' => 'partial',
        'validationFailed' => 'invalid',
        'denied' => 'denied',
        'uncertain' => 'uncertain',
        'failed' when _repairCode(result['code']) => 'repair',
        'failed' when _connectionCode(result['code']) => 'disconnected',
        _ => 'failed',
      };

  static String external(String outcome, Map<dynamic, dynamic> result) =>
      switch (outcome) {
        'completed' => 'completed',
        'uncertain' when result['statusCode'] == _partialHttpStatusCode =>
          'partial',
        'uncertain' => 'uncertain',
        _ => 'failed',
      };

  static bool _repairCode(Object? code) =>
      code == 'stale_contract' ||
      code == 'invalid_tool_arguments' ||
      code == 'unknown_tool';

  static bool _connectionCode(Object? code) =>
      code == 'connection_unavailable' ||
      code == 'connection_required' ||
      code == 'connection_selection_required';
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
  return _ConnectorErrorStatus.key(error);
}

abstract final class _ConnectorErrorStatus {
  static String key(AgentToolExecutionFailure error) {
    final response = _decode(error.responseRaw);

    return switch (response) {
      {'error': {'code': 'tool_access_denied' || 'denied'}} =>
        LocaleKeys.workspace_connected_denied,
      {'error': {'code': 'stale_contract' || 'invalid_tool_arguments'}} =>
        LocaleKeys.workspace_connected_repair,
      {'statusCode': _partialHttpStatusCode} =>
        LocaleKeys.workspace_views_action_partial,
      _ =>
        error.resultStatus == AgentToolResultStatus.uncertain
            ? LocaleKeys.workspace_views_action_uncertain
            : LocaleKeys.workspace_connected_failed,
    };
  }

  static Map<dynamic, dynamic>? _decode(String response) {
    try {
      final decoded = jsonDecode(response);

      return decoded is Map ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

class const _ActionApprovalDialog({
  required final String viewName,
  required final Map<String, Object?> details,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: _ActionApprovalContent(viewName: viewName, details: details),
    ),
  );
}

class const _ActionApprovalContent({
  required final String viewName,
  required final Map<String, Object?> details,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        _ActionApprovalHeader(viewName),
        _ActionApprovalDetails(details),
        const SizedBox(height: 12),
        const _ActionApprovalButtons(),
      ],
    ),
  );
}

class const _ActionApprovalHeader(final String viewName)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      const TextLocale(LocaleKeys.workspace_views_action_review),
      const SizedBox(height: 8),
      Text(viewName),
      const SizedBox(height: 8),
      const TextLocale(LocaleKeys.workspace_views_action_approval),
    ],
  );
}

class const _ActionApprovalDetails(final Map<String, Object?> details)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SelectableText(const JsonEncoder.withIndent('  ').convert(details));
}

class const _ActionApprovalButtons() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: .end,
    children: [
      _ActionApprovalButton(approve: false),
      SizedBox(width: 8),
      _ActionApprovalButton(approve: true),
    ],
  );
}

class const _ActionApprovalButton({required final bool approve})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => Navigator.of(context).pop(approve),
    child: TextLocale(
      approve
          ? LocaleKeys.workspace_views_action_submit
          : LocaleKeys.common_cancel,
    ),
    variant: approve ? .primary : .ghost,
  );
}

class const _SurfaceContent({
  required final SurfaceController controller,
  required final bool canSubmit,
  required final bool submitting,
  required final String? statusKey,
  required final Map<String, String> formErrors,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _SurfaceUpdates(
        controller,
        interactive: canSubmit,
        submitting: submitting,
      ),
      if (canSubmit)
        _SubmissionControls(
          submitting: submitting,
          statusKey: statusKey,
          formErrors: formErrors,
          onSubmit: onSubmit,
        ),
    ],
  );
}

class const _SubmissionControls({
  required final bool submitting,
  required final String? statusKey,
  required final Map<String, String> formErrors,
  required final VoidCallback onSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _SubmissionButton(submitting: submitting, onPressed: onSubmit),
      _SubmissionMessages(statusKey: statusKey, formErrors: formErrors),
    ],
  );
}

class const _SubmissionButton({
  required final bool submitting,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: submitting
        ? const TextLocale(LocaleKeys.workspace_views_action_submitting)
        : const TextLocale(LocaleKeys.workspace_views_action_submit),
    key: const ValueKey('workspace_view_action_submit'),
    isFullWidth: true,
    disabled: submitting,
  );
}

class const _SubmissionMessages({
  required final String? statusKey,
  required final Map<String, String> formErrors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      if (statusKey case final status?)
        _submissionStatusMessages[status] ??
            const TextLocale(LocaleKeys.workspace_connected_failed),
      for (final error in formErrors.entries)
        Text('${error.key}: ${error.value}'),
    ],
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
