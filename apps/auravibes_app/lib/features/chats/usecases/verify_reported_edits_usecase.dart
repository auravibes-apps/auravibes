import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_cancellation.dart';
import 'package:auravibes_app/features/chats/models/scoped_verification_invocation.dart';
import 'package:auravibes_app/features/chats/usecases/scoped_verification_feedback.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

export 'scoped_verification_feedback.dart' show buildScopedVerificationFeedback;

class const VerifyReportedEditsUsecase({
  required final WorkspaceVerificationRepository repository,
  required final Future<ScopedVerificationIdentity?> Function(
    ScopedVerificationInvocation invocation,
  )
  resolveIdentity,
  required final Future<ScopedVerificationRunner?> Function(
    ScopedVerificationRunnerInput input,
  )
  createRunner,
  required final ScopedVerificationCancellation cancellation,
}) {
  Future<Object> call({
    required String conversationId,
    required String toolCallId,
    required ResolvedTool tool,
    required McpToolCallerResult result,
  }) => _verifyReportedEdit(this, (
    conversationId: conversationId,
    toolCallId: toolCallId,
    tool: tool,
    result: result,
  ));

  Future<ScopedVerificationResult> _verify(_VerificationInput input) async {
    final turnId = input.identity.turnId;
    if (turnId == null) {
      return ScopedVerificationResult(
        outcome: .incomplete,
        reason: 'invalid_turn',
      );
    }
    final reservation = await repository.reserve(
      workspaceId: input.identity.workspaceId,
      turnId: turnId,
      toolCallId: input.invocation.toolCallId,
      configRevision: input.settings.revision,
      maxRepairAttempts: input.settings.maxRepairAttempts,
    );
    if (reservation.result case final ScopedVerificationResult recorded) {
      return recorded;
    }
    final id = reservation.operationId;
    if (id == null) {
      return ScopedVerificationResult(
        outcome: .incomplete,
        reason: 'invalid_reservation',
      );
    }

    return _runReservedVerification(input, id);
  }

  Future<ScopedVerificationResult> _runReservedVerification(
    _VerificationInput input,
    String operationId,
  ) async {
    final deadline = DateTime.now().toUtc().add(input.settings.timeout);
    try {
      final result = await _executeVerification(input, operationId, deadline);

      return await repository.complete(operationId, result);
    } on Object {
      return await repository.complete(
        operationId,
        _verificationFailure(input.cancellation, deadline),
      );
    }
  }

  Future<ScopedVerificationResult> _executeVerification(
    _VerificationInput input,
    String operationId,
    DateTime deadline,
  ) async {
    final request = ScopedVerificationRequest(
      operationId: operationId,
      workspaceRoot: input.settings.workspaceRoot,
      deadline: deadline,
      selections: input.selections,
      maxOutputBytes: input.settings.maxOutputBytes,
    );
    final runner = await _createBounded((
      invocation: input.invocation,
      settings: input.settings,
      request: request,
      cancellation: input.cancellation,
    ));
    if (runner == null) return _unavailableRunnerResult(input, request);

    return await ScopedVerificationService(runner: runner)
        .call(request, cancellation: input.cancellation);
  }

  Future<ScopedVerificationRunner?> _createBounded(
    ScopedVerificationRunnerInput input,
  ) async {
    final remaining = input.request.deadline.difference(DateTime.now().toUtc());
    if (input.cancellation.isCancellationRequested || remaining <= .zero) {
      return null;
    }
    final interrupted = Completer<ScopedVerificationRunner?>();
    void end() {
      if (!interrupted.isCompleted) interrupted.complete();
    }

    final timer = Timer(remaining, end);
    final registration = input.cancellation.registerCleanup(end);
    try {
      return await Future.any([createRunner(input), interrupted.future]);
    } finally {
      timer.cancel();
      final _ = registration.remove();
    }
  }
}

typedef _VerifyReportedEditRequest = ({
  String conversationId,
  String toolCallId,
  ResolvedTool tool,
  McpToolCallerResult result,
});

typedef _VerificationContext = ({
  ScopedVerificationIdentity identity,
  ScopedVerificationSettings settings,
});

typedef _VerificationSelection = ({
  List<ScopedVerificationSelection>? selections,
  ScopedVerificationResult? result,
});

typedef _SelectedVerification = ({
  VerifyReportedEditsUsecase usecase,
  ScopedVerificationInvocation invocation,
  McpToolCallerResult original,
  _VerificationContext context,
  List<ScopedVerificationSelection> selections,
});

Future<Object> _verifyReportedEdit(
  VerifyReportedEditsUsecase usecase,
  _VerifyReportedEditRequest request,
) async {
  if (!request.tool.isMcp || request.result.isError == true) {
    return request.result.modelText;
  }
  try {
    return await _verifyCandidateEdit(usecase, request);
  } on Object {
    return _feedback(request.result, .incomplete, 'verification_error');
  }
}

Future<Object> _verifyCandidateEdit(
  VerifyReportedEditsUsecase usecase,
  _VerifyReportedEditRequest request,
) async {
  final invocation = (
    conversationId: request.conversationId,
    toolCallId: request.toolCallId,
    tool: request.tool,
  );
  final context = await _verificationContext(usecase, invocation, request.tool);
  if (context == null) return request.result.modelText;

  return _verifyEligibleEdit(usecase, invocation, request, context);
}

Future<_VerificationContext?> _verificationContext(
  VerifyReportedEditsUsecase usecase,
  ScopedVerificationInvocation invocation,
  ResolvedTool tool,
) async {
  final identity = await usecase.resolveIdentity(invocation);
  if (identity == null) return null;
  final settings = await usecase.repository.getSettings(identity.workspaceId);
  if (!settings.enabled ||
      !settings.editToolIds.contains(tool.tableId) ||
      tool.tableId == settings.runnerToolId) {
    return null;
  }

  return (identity: identity, settings: settings);
}

Future<Object> _verifyEligibleEdit(
  VerifyReportedEditsUsecase usecase,
  ScopedVerificationInvocation invocation,
  _VerifyReportedEditRequest request,
  _VerificationContext context,
) async {
  if (request.tool.mcpServerId != context.settings.mcpServerId) {
    return _feedback(request.result, .incomplete, 'server_mismatch');
  }
  final selection = _verificationSelection(
    context.settings,
    request.result.structuredContent,
  );
  if (selection.result case final ScopedVerificationResult result) {
    return _feedback(request.result, result.outcome, result.reason ?? '');
  }
  final selections = selection.selections;
  if (selections == null || context.identity.turnId == null) {
    return _feedback(request.result, .incomplete, 'invalid_turn');
  }

  return await _runSelectedVerification((
    usecase: usecase,
    invocation: invocation,
    original: request.result,
    context: context,
    selections: selections,
  ));
}

ScopedVerificationResult _unavailableRunnerResult(
  _VerificationInput input,
  ScopedVerificationRequest request,
) {
  if (input.cancellation.isCancellationRequested) {
    return ScopedVerificationResult(outcome: .cancelled, reason: 'cancelled');
  }
  if (!request.deadline.isAfter(DateTime.now().toUtc())) {
    return ScopedVerificationResult(outcome: .incomplete, reason: 'timeout');
  }

  return ScopedVerificationResult(
    outcome: .incomplete,
    reason: 'runner_unavailable',
  );
}

ScopedVerificationResult _verificationFailure(
  AgentCancellationScope cancellation,
  DateTime deadline,
) {
  final stopped = cancellation.isCancellationRequested;
  final expired = !deadline.isAfter(DateTime.now().toUtc());

  return ScopedVerificationResult(
    outcome: stopped ? .cancelled : .incomplete,
    reason: _failureReason(stopped: stopped, expired: expired),
  );
}

_VerificationSelection _verificationSelection(
  ScopedVerificationSettings settings,
  Object? structuredContent,
) {
  try {
    final report = parseScopedEditReport(structuredContent);
    if (report == null) {
      return (
        selections: null,
        result: ScopedVerificationResult(
          outcome: .skipped,
          reason: 'no_changed_paths',
        ),
      );
    }
    final selections = selectScopedVerificationChecks(settings, report);
    if (selections.isEmpty) {
      return (
        selections: null,
        result: ScopedVerificationResult(
          outcome: .skipped,
          reason: 'no_matching_checks',
        ),
      );
    }

    return (selections: selections, result: null);
  } on FormatException {
    return (
      selections: null,
      result: ScopedVerificationResult(
        outcome: .incomplete,
        reason: 'invalid_report',
      ),
    );
  }
}

Future<Object> _runSelectedVerification(_SelectedVerification request) async {
  final verified = await request.usecase.cancellation.run(
    request.invocation,
    (scope) => request.usecase._verify((
      identity: request.context.identity,
      invocation: request.invocation,
      settings: request.context.settings,
      selections: request.selections,
      cancellation: scope,
    )),
  );

  return buildScopedVerificationFeedback(request.original.modelText, verified);
}

String _failureReason({required bool stopped, required bool expired}) {
  if (stopped) {
    return 'cancelled';
  }
  if (expired) {
    return 'timeout';
  }

  return 'verification_error';
}

typedef _VerificationInput = ({
  ScopedVerificationIdentity identity,
  ScopedVerificationInvocation invocation,
  ScopedVerificationSettings settings,
  List<ScopedVerificationSelection> selections,
  AgentCancellationScope cancellation,
});

Map<String, Object?> _feedback(
  McpToolCallerResult original,
  ScopedVerificationOutcome outcome,
  String reason,
) => buildScopedVerificationFeedback(
  original.modelText,
  .new(outcome: outcome, reason: reason),
);
