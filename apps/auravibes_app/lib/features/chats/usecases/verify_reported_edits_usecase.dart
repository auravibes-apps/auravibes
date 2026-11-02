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
  }) async {
    if (!tool.isMcp || result.isError == true) return result.modelText;
    final invocation = (
      conversationId: conversationId,
      toolCallId: toolCallId,
      tool: tool,
    );
    try {
      final identity = await resolveIdentity(invocation);
      if (identity == null) return result.modelText;
      final settings = await repository.getSettings(identity.workspaceId);
      if (!settings.enabled ||
          !settings.editToolIds.contains(tool.tableId) ||
          tool.tableId == settings.runnerToolId) {
        return result.modelText;
      }
      if (tool.mcpServerId != settings.mcpServerId) {
        return _feedback(result, .incomplete, 'server_mismatch');
      }
      final ScopedEditReport? report;
      final List<ScopedVerificationSelection> selections;
      try {
        report = parseScopedEditReport(result.structuredContent);
        if (report == null) {
          return _feedback(result, .skipped, 'no_changed_paths');
        }
        selections = selectScopedVerificationChecks(settings, report);
      } on FormatException {
        return _feedback(result, .incomplete, 'invalid_report');
      }
      if (selections.isEmpty) {
        return _feedback(result, .skipped, 'no_matching_checks');
      }
      if (identity.turnId == null) {
        return _feedback(result, .incomplete, 'invalid_turn');
      }
      final verified = await cancellation.run(
        invocation,
        (scope) => _verify((
          identity: identity,
          invocation: invocation,
          settings: settings,
          selections: selections,
          cancellation: scope,
        )),
      );

      return buildScopedVerificationFeedback(result.modelText, verified);
    } on Object {
      // A verification problem never converts a completed edit into a retry.
      return _feedback(result, .incomplete, 'verification_error');
    }
  }

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
    final deadline = DateTime.now().toUtc().add(input.settings.timeout);
    try {
      final request = ScopedVerificationRequest(
        operationId: id,
        workspaceRoot: input.settings.workspaceRoot,
        deadline: deadline,
        selections: input.selections,
        maxOutputBytes: input.settings.maxOutputBytes,
      );
      // The factory must return a new runner for this operation, never a
      // workspace singleton that retains another operation's cleanup binding.
      final runner = await _createBounded((
        invocation: input.invocation,
        settings: input.settings,
        request: request,
        cancellation: input.cancellation,
      ));
      final ScopedVerificationResult result;
      if (runner != null) {
        result = await ScopedVerificationService(runner: runner)
            .call(request, cancellation: input.cancellation);
      } else if (input.cancellation.isCancellationRequested) {
        result = ScopedVerificationResult(
          outcome: .cancelled,
          reason: 'cancelled',
        );
      } else if (!request.deadline.isAfter(DateTime.now().toUtc())) {
        result = ScopedVerificationResult(
          outcome: .incomplete,
          reason: 'timeout',
        );
      } else {
        result = ScopedVerificationResult(
          outcome: .incomplete,
          reason: 'runner_unavailable',
        );
      }

      return await repository.complete(id, result);
    } on Object {
      final stopped = input.cancellation.isCancellationRequested;
      final expired = !deadline.isAfter(DateTime.now().toUtc());

      return await repository.complete(
        id,
        .new(
          outcome: stopped ? .cancelled : .incomplete,
          reason: _failureReason(stopped: stopped, expired: expired),
        ),
      );
    }
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
