import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/src/agent_runtime.dart';
import 'package:auravibes_engine/src/scoped_verification.dart';
import 'package:auravibes_engine/src/scoped_verification_result.dart';
import 'package:auravibes_engine/src/scoped_verification_runner.dart';

class const ScopedVerificationService({
  required final ScopedVerificationRunner runner,
  final ScopedVerificationClock clock = const _SystemVerificationClock(),
}) {
  Future<ScopedVerificationResult> call(
    ScopedVerificationRequest request, {
    required AgentCancellationScope cancellation,
  }) async {
    try {
      return await _VerificationExecution(
        runner,
        clock,
        request,
        cancellation,
      ).run();
    } finally {
      if (runner case ScopedVerificationRunnerLifecycle lifecycle)
        lifecycle.close();
    }
  }
}

final class _VerificationExecution {
  _VerificationExecution(
    this.runner,
    this.clock,
    this.request,
    this.cancellation,
  );

  final ScopedVerificationRunner runner;
  final ScopedVerificationClock clock;
  final ScopedVerificationRequest request;
  final AgentCancellationScope cancellation;
  final _stop = Completer<void>();
  final _timeout = Completer<void>();
  bool _started = false;

  Future<ScopedVerificationResult> run() async {
    if (cancellation.isCancellationRequested)
      return _result(.cancelled, 'cancelled');
    if (request.selections.isEmpty)
      return _result(.skipped, 'no_matching_checks');
    final remaining = request.deadline.difference(clock.now());
    if (remaining <= Duration.zero) return _result(.incomplete, 'timeout');
    if (remaining > ScopedVerificationLimits.maxTimeout)
      return _result(.incomplete, 'invalid_deadline');
    final timer = clock.schedule(remaining, _completeTimeout);
    final registration = cancellation.registerCleanup(_completeStop);
    try {
      final capabilities = await _wait(runner.capabilities());
      _ensureActive();
      if (!capabilities.supported)
        return _result(.incomplete, 'unsupported_runner');
      _started = true;
      var job = await _wait(runner.start(request));
      while (true) {
        _ensureActive();
        _validateJob(job);
        if (job.state == .completed) return _completed(job);
        if (job.state == .cancelled)
          return _result(.cancelled, 'runner_cancelled');
        await _pause();
        _ensureActive();
        job = await _wait(runner.poll(request.operationId));
      }
    } on _VerificationInterrupted catch (interrupted) {
      return await _terminate(interrupted.reason);
    } on FormatException {
      return await _terminate('invalid_response');
    } on Object {
      return await _terminate('runner_error');
    } finally {
      timer.cancel();
      final _ = registration.remove();
    }
  }

  void _completeTimeout() {
    if (!_timeout.isCompleted) _timeout.complete();
  }

  void _completeStop() {
    if (!_stop.isCompleted) _stop.complete();
  }

  void _ensureActive() {
    if (cancellation.isCancellationRequested)
      throw const _VerificationInterrupted('cancelled');
    if (_timeout.isCompleted || !request.deadline.isAfter(clock.now()))
      throw const _VerificationInterrupted('timeout');
  }

  Future<T> _wait<T>(Future<T> operation) => Future.any([
    operation,
    _stop.future.then<T>(
      (_) => throw const _VerificationInterrupted('cancelled'),
    ),
    _timeout.future.then<T>(
      (_) => throw const _VerificationInterrupted('timeout'),
    ),
  ]);

  Future<void> _pause() async {
    final ready = Completer<void>();
    final timer = clock.schedule(
      const Duration(milliseconds: 250),
      ready.complete,
    );
    try {
      await _wait(ready.future);
    } finally {
      timer.cancel();
    }
  }

  void _validateJob(ScopedVerificationJob job) {
    if (job.operationId != request.operationId ||
        job.workspaceRoot != request.workspaceRoot ||
        !job.scopeValidated ||
        utf8.encode(job.output).length > request.maxOutputBytes ||
        job.exitCodes.keys.any(
          (id) =>
              !request.selections.any((selection) => selection.check.id == id),
        )) {
      throw const FormatException('Invalid scoped verification receipt.');
    }
  }

  ScopedVerificationResult _completed(ScopedVerificationJob job) {
    if (job.exitCodes.length != request.selections.length) {
      throw const FormatException(
        'Verification needs every completed exit code.',
      );
    }
    final passed = job.exitCodes.values.every((exitCode) => exitCode == 0);

    return ScopedVerificationResult(
      outcome: passed ? .pass : .fail,
      reason: passed ? 'zero_exit' : 'nonzero_exit',
      checkIds: request.selections
          .map((selection) => selection.check.id)
          .toList(),
      paths: request.selections
          .expand((selection) => selection.paths)
          .toSet()
          .toList(),
      output: job.output,
      maxOutputBytes: request.maxOutputBytes,
      outputTruncated: job.outputTruncated,
      originalOutputBytes: job.originalOutputBytes,
    );
  }

  Future<ScopedVerificationResult> _terminate(String reason) async {
    if (!_started)
      return _result(reason == 'cancelled' ? .cancelled : .incomplete, reason);
    final confirmed = await _cancel();
    if (reason == 'cancelled') {
      return confirmed
          ? _result(.cancelled, 'cancelled')
          : _result(.incomplete, 'cancellation_unconfirmed');
    }

    return _result(.incomplete, reason);
  }

  Future<bool> _cancel() async {
    final expired = Completer<ScopedVerificationJob>();
    final timer = clock.schedule(
      const Duration(seconds: 2),
      () => expired.completeError(
        const _VerificationInterrupted('cancellation_unconfirmed'),
      ),
    );
    try {
      final reply = await Future.any([
        runner.cancel(request.operationId),
        expired.future,
      ]);

      return reply.operationId == request.operationId &&
          reply.workspaceRoot == request.workspaceRoot &&
          reply.scopeValidated &&
          reply.state == .cancelled &&
          reply.cancellationRecorded;
    } on Object {
      return false;
    } finally {
      timer.cancel();
    }
  }

  ScopedVerificationResult _result(
    ScopedVerificationOutcome outcome,
    String reason,
  ) => ScopedVerificationResult(
    outcome: outcome,
    reason: reason,
    checkIds: request.selections
        .map((selection) => selection.check.id)
        .toList(),
    paths: request.selections
        .expand((selection) => selection.paths)
        .toSet()
        .toList(),
    maxOutputBytes: request.maxOutputBytes,
  );
}

class const _VerificationInterrupted(final String reason) implements Exception;

class const _SystemVerificationClock() implements ScopedVerificationClock {
  @override
  DateTime now() => DateTime.now().toUtc();
  @override
  Timer schedule(Duration duration, void Function() callback) =>
      Timer(duration, callback);
}
