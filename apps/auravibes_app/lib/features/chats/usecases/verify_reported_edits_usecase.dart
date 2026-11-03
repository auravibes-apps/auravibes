import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_cancellation.dart';
import 'package:auravibes_app/features/chats/models/scoped_verification_invocation.dart';
import 'package:auravibes_app/features/chats/usecases/scoped_verification_feedback.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

export 'scoped_verification_feedback.dart' show ScopedVerificationFeedback;

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
    final reservation = await _reserveVerification(input);
    if (reservation.result case final ScopedVerificationResult result) {
      return result;
    }
    final operationId = reservation.operationId;
    if (operationId == null) {
      return ScopedVerificationResult(
        outcome: .incomplete,
        reason: 'invalid_reservation',
      );
    }

    return await _runReservedVerification(input, operationId);
  }

  Future<ScopedVerificationReservation> _reserveVerification(
    _VerificationInput input,
  ) async {
    final turnId = input.identity.turnId;
    if (turnId == null) return _invalidTurnReservation();

    return await repository.reserve((
      workspaceId: input.identity.workspaceId,
      turnId: turnId,
      toolCallId: input.invocation.toolCallId,
      configRevision: input.settings.revision,
      maxRepairAttempts: input.settings.maxRepairAttempts,
    ));
  }

  ScopedVerificationReservation _invalidTurnReservation() => (
    operationId: null,
    result: ScopedVerificationResult(
      outcome: .incomplete,
      reason: 'invalid_turn',
    ),
    repairAttemptsRemaining: 0,
    shouldRun: false,
  );

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
  ) => _executeBoundedVerification(
    this,
    input,
    _verificationRequest(input, operationId, deadline),
  );

  Future<ScopedVerificationRunner?> _createBounded(
    ScopedVerificationRunnerInput input,
  ) async {
    final remaining = input.request.deadline.difference(DateTime.now().toUtc());
    if (input.cancellation.isCancellationRequested || remaining <= .zero) {
      return null;
    }

    return await _raceRunnerCreation(input, remaining, createRunner);
  }

  Future<ScopedVerificationRunner?> _raceRunnerCreation(
    ScopedVerificationRunnerInput input,
    Duration remaining,
    Future<ScopedVerificationRunner?> Function(
      ScopedVerificationRunnerInput input,
    )
    create,
  ) async {
    final race = _ScopedVerificationRunnerCreationRace.start(input, remaining);
    try {
      return await race.run(create);
    } finally {
      race.close();
    }
  }
}

ScopedVerificationRequest _verificationRequest(
  _VerificationInput input,
  String operationId,
  DateTime deadline,
) => ScopedVerificationRequest(
  operationId: operationId,
  workspaceRoot: input.settings.workspaceRoot,
  deadline: deadline,
  selections: input.selections,
  maxOutputBytes: input.settings.maxOutputBytes,
);

Future<ScopedVerificationResult> _executeBoundedVerification(
  VerifyReportedEditsUsecase usecase,
  _VerificationInput input,
  ScopedVerificationRequest request,
) async {
  final runner = await usecase._createBounded((
    invocation: input.invocation,
    settings: input.settings,
    request: request,
    cancellation: input.cancellation,
  ));
  if (runner == null) return _unavailableRunnerResult(input, request);

  return await ScopedVerificationService(runner: runner)
      .call(request, cancellation: input.cancellation);
}

class _ScopedVerificationRunnerCreationRace {
  _ScopedVerificationRunnerCreationRace._({
    required this.input,
    required this.interrupted,
    required this.timer,
    required this.registration,
  });

  factory _ScopedVerificationRunnerCreationRace.start(
    ScopedVerificationRunnerInput input,
    Duration remaining,
  ) {
    final interrupted = Completer<ScopedVerificationRunner?>();
    void interrupt() {
      if (!interrupted.isCompleted) interrupted.complete();
    }

    return _ScopedVerificationRunnerCreationRace._(
      input: input,
      interrupted: interrupted,
      timer: Timer(remaining, interrupt),
      registration: input.cancellation.registerCleanup(interrupt),
    );
  }

  final ScopedVerificationRunnerInput input;
  final Completer<ScopedVerificationRunner?> interrupted;
  final Timer timer;
  final AgentCancellationCleanupRegistration registration;

  Future<ScopedVerificationRunner?> run(
    Future<ScopedVerificationRunner?> Function(
      ScopedVerificationRunnerInput input,
    )
    create,
  ) => Future.any([create(input), interrupted.future]);

  void close() {
    timer.cancel();
    final _ = registration.remove();
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

typedef _EligibleVerification = ({
  VerifyReportedEditsUsecase usecase,
  ScopedVerificationInvocation invocation,
  _VerifyReportedEditRequest request,
  _VerificationContext context,
});

Future<Object> _verifyReportedEdit(
  VerifyReportedEditsUsecase usecase,
  _VerifyReportedEditRequest request,
) async {
  final result = request.result;
  if (!request.tool.isMcp || result.isError == true) {
    return result.modelText;
  }
  try {
    return await _verifyCandidateEdit(usecase, request);
  } on Object {
    return _feedback(result, .incomplete, 'verification_error');
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

  return await _verifyEligibleEdit((
    usecase: usecase,
    invocation: invocation,
    request: request,
    context: context,
  ));
}

Future<_VerificationContext?> _verificationContext(
  VerifyReportedEditsUsecase usecase,
  ScopedVerificationInvocation invocation,
  ResolvedTool tool,
) async {
  final identity = await usecase.resolveIdentity(invocation);
  if (identity == null) return null;
  final settings = await _eligibleVerificationSettings(usecase, identity, tool);
  if (settings == null) return null;

  return (identity: identity, settings: settings);
}

Future<ScopedVerificationSettings?> _eligibleVerificationSettings(
  VerifyReportedEditsUsecase usecase,
  ScopedVerificationIdentity identity,
  ResolvedTool tool,
) async {
  final settings = await usecase.repository.getSettings(identity.workspaceId);
  if (!_settingsIncludeEditTool(settings, tool)) return null;

  return settings;
}

bool _settingsIncludeEditTool(
  ScopedVerificationSettings settings,
  ResolvedTool tool,
) =>
    settings.enabled &&
    settings.editToolIds.contains(tool.tableId) &&
    tool.tableId != settings.runnerToolId;

Future<Object> _verifyEligibleEdit(_EligibleVerification eligible) async {
  final invalid = _editServerMismatch(eligible);
  if (invalid != null) return invalid;

  return await _selectAndRunVerification(eligible);
}

Object? _editServerMismatch(_EligibleVerification eligible) {
  final request = eligible.request;
  final context = eligible.context;
  if (request.tool.mcpServerId == context.settings.mcpServerId) return null;

  return _feedback(request.result, .incomplete, 'server_mismatch');
}

Future<Object> _selectAndRunVerification(_EligibleVerification eligible) async {
  final request = eligible.request;
  final context = eligible.context;
  final selection = _verificationSelection(
    context.settings,
    request.result.structuredContent,
  );

  return await _runSelectionOrExplainFailure(eligible, selection);
}

Future<Object> _runSelectionOrExplainFailure(
  _EligibleVerification eligible,
  _VerificationSelection selection,
) async {
  final failure = _selectionFailure(eligible, selection);
  if (failure != null) return failure;
  final request = eligible.request;
  final context = eligible.context;

  return await _runSelectedVerification((
    usecase: eligible.usecase,
    invocation: eligible.invocation,
    original: request.result,
    context: context,
    selections: selection.selections!,
  ));
}

Object? _selectionFailure(
  _EligibleVerification eligible,
  _VerificationSelection selection,
) {
  if (selection.result case final ScopedVerificationResult result) {
    return _feedback(eligible.request.result, result.outcome, result.reason);
  }
  if (selection.selections == null ||
      eligible.context.identity.turnId == null) {
    return _feedback(eligible.request.result, .incomplete, 'invalid_turn');
  }

  return null;
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
  final verified = await _verifySelectedInScope(request);

  return ScopedVerificationFeedback.build(request.original.modelText, verified);
}

Future<ScopedVerificationResult> _verifySelectedInScope(
  _SelectedVerification request,
) => request.usecase.cancellation.run(
  request.invocation,
  (scope) =>
      request.usecase._verify(_selectedVerificationInput(request, scope)),
);

_VerificationInput _selectedVerificationInput(
  _SelectedVerification request,
  AgentCancellationScope scope,
) => (
  identity: request.context.identity,
  invocation: request.invocation,
  settings: request.context.settings,
  selections: request.selections,
  cancellation: scope,
);

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
) => ScopedVerificationFeedback.build(
  original.modelText,
  .new(outcome: outcome, reason: reason),
);
