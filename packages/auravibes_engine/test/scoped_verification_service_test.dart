import 'dart:async';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('passes only a complete receipt with every selected zero exit', () async {
    final fixture = _Fixture();
    final result = await fixture.run();
    expect(result.outcome, ScopedVerificationOutcome.pass);
    expect(result.checkIds, ['dart']);
    expect(result.paths, ['lib/main.dart']);
    expect(fixture.runner.calls, ['capabilities', 'start']);
    expect(fixture.clock.activeTimers, 0);
    expect(fixture.runner.closed, 1);
  });

  test('returns fail output for completed nonzero checks', () async {
    final fixture = _Fixture();
    fixture.runner.reply = fixture.runner.job(exitCodes: const {'dart': 2}, output: 'analyzer failure');
    final result = await fixture.run();
    expect(result.outcome, ScopedVerificationOutcome.fail);
    expect(result.output, 'analyzer failure');
    expect(result.repairAllowed, isFalse);
  });

  test('a queued cancellation starts no capabilities or command', () async {
    final fixture = _Fixture()..scope.requestStop();
    final result = await fixture.run();
    expect(result.outcome, ScopedVerificationOutcome.cancelled);
    expect(fixture.runner.calls, isEmpty);
  });

  test('unsupported runner capabilities launch no command', () async {
    final fixture = _Fixture();
    fixture.runner.capability = ScopedVerificationCapabilities(protocol: ScopedVerificationLimits.protocol, features: const {'scopedPaths'});
    final result = await fixture.run();
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
    expect(result.reason, 'unsupported_runner');
    expect(fixture.runner.calls, ['capabilities']);
  });

  test('a runner without persistent pre-start cancellation cannot launch', () async {
    final fixture = _Fixture();
    fixture.runner.capability = ScopedVerificationCapabilities(protocol: ScopedVerificationLimits.protocol, features: ScopedVerificationCapabilities.requiredFeatures.where((feature) => feature != 'cancellationTombstones').toSet());
    expect((await fixture.run()).reason, 'unsupported_runner');
    expect(fixture.runner.calls, ['capabilities']);
  });

  test('cancel tombstone prevents a delayed registration after the run settles', () async {
    final fixture = _Fixture();
    final delayed = Completer<ScopedVerificationJob>();
    fixture.runner.startResult = delayed.future;
    final future = fixture.run();
    await _flush();
    expect(delayed.isCompleted, isFalse);
    fixture.scope.requestStop();
    expect((await future).outcome, ScopedVerificationOutcome.cancelled);
    expect(fixture.runner.cancelledOperations, {'operation'});
    delayed.complete(fixture.runner.registerLate('operation'));
    await _flush();
    expect(fixture.runner.remoteExecutions, 0);
    expect(fixture.runner.calls, ['capabilities', 'start', 'cancel']);
  });

  for (final (index, badJob) in <ScopedVerificationJob Function(_Runner)>[
    (runner) => runner.job(exitCodes: const {}),
    (runner) => runner.job(exitCodes: const {'unknown': 0}),
    (runner) => runner.job(operationId: 'wrong'),
    (runner) => runner.job(root: 'root-sibling'),
    (runner) => runner.job(scopeValidated: false),
    (runner) => runner.job(output: 'x' * 16385),
  ].indexed) {
    test('invalid completion $index never records pass and cancels uncertain work', () async {
      final fixture = _Fixture();
      fixture.runner.reply = badJob(fixture.runner);
      final result = await fixture.run();
      expect(result.outcome, ScopedVerificationOutcome.incomplete);
      expect(fixture.runner.calls.where((call) => call == 'cancel'), hasLength(1));
    });
  }

  test('polls running work and settles a single completed result', () async {
    final fixture = _Fixture();
    fixture.runner.reply = fixture.runner.job(state: .running, exitCodes: const {});
    final future = fixture.run();
    await _flush();
    expect(fixture.runner.calls, ['capabilities', 'start']);
    fixture.runner.reply = fixture.runner.job();
    fixture.clock.elapse(const Duration(milliseconds: 250));
    final result = await future;
    expect(result.outcome, ScopedVerificationOutcome.pass);
    expect(fixture.runner.calls, ['capabilities', 'start', 'poll']);
    expect(fixture.clock.activeTimers, 0);
  });

  test('deadline cancels once and late zero exit cannot become pass', () async {
    final fixture = _Fixture();
    final pending = Completer<ScopedVerificationJob>();
    fixture.runner.startResult = pending.future;
    final future = fixture.run();
    await _flush();
    fixture.clock.elapse(const Duration(seconds: 30));
    final result = await future;
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
    expect(result.reason, 'timeout');
    pending.complete(fixture.runner.job());
    await _flush();
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
    expect(fixture.runner.calls, ['capabilities', 'start', 'cancel']);
    expect(fixture.clock.activeTimers, 0);
  });

  test('confirmed user stop cancels remote work and returns cancelled', () async {
    final fixture = _Fixture();
    fixture.runner.startResult = Completer<ScopedVerificationJob>().future;
    final future = fixture.run();
    await _flush();
    fixture.scope.requestStop();
    final result = await future;
    expect(result.outcome, ScopedVerificationOutcome.cancelled);
    expect(fixture.runner.calls, ['capabilities', 'start', 'cancel']);
    expect(fixture.clock.activeTimers, 0);
  });

  test('unconfirmed cancellation settles incomplete after two seconds', () async {
    final fixture = _Fixture();
    fixture.runner.startResult = Completer<ScopedVerificationJob>().future;
    fixture.runner.cancelResult = Completer<ScopedVerificationJob>().future;
    final future = fixture.run();
    await _flush();
    fixture.scope.requestStop();
    await _flush();
    fixture.clock.elapse(const Duration(seconds: 2));
    final result = await future;
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
    expect(result.reason, 'cancellation_unconfirmed');
    expect(fixture.runner.calls.where((call) => call == 'cancel'), hasLength(1));
    expect(fixture.clock.activeTimers, 0);
  });

  test('capability timeout never starts or cancels nonexistent work', () async {
    final fixture = _Fixture();
    fixture.runner.capabilityResult = Completer<ScopedVerificationCapabilities>().future;
    final future = fixture.run();
    await _flush();
    fixture.clock.elapse(const Duration(seconds: 30));
    expect((await future).reason, 'timeout');
    expect(fixture.runner.calls, ['capabilities']);
  });

  test('empty selections skip without probing or executing a runner', () async {
    final fixture = _Fixture();
    final request = ScopedVerificationRequest(operationId: 'operation', workspaceRoot: 'root', deadline: fixture.clock.now().add(const Duration(seconds: 30)), selections: const []);
    final result = await fixture.service.call(request, cancellation: fixture.scope);
    expect(result.outcome, ScopedVerificationOutcome.skipped);
    expect(result.reason, 'no_matching_checks');
    expect(fixture.runner.calls, isEmpty);
  });

  test('stop during capability negotiation never starts work', () async {
    final fixture = _Fixture();
    fixture.runner.capabilityResult = Completer<ScopedVerificationCapabilities>().future;
    final future = fixture.run();
    await _flush();
    fixture.scope.requestStop();
    expect((await future).outcome, ScopedVerificationOutcome.cancelled);
    expect(fixture.runner.calls, ['capabilities']);
  });

  test('lost polling transport returns incomplete and cancels once', () async {
    final fixture = _Fixture();
    fixture.runner.reply = fixture.runner.job(state: .running, exitCodes: const {});
    fixture.runner.pollFailure = StateError('disconnected');
    final future = fixture.run();
    await _flush();
    fixture.clock.elapse(const Duration(milliseconds: 250));
    final result = await future;
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
    expect(result.reason, 'runner_error');
    expect(fixture.runner.calls, ['capabilities', 'start', 'poll', 'cancel']);
  });

  test('transport failure is incomplete and never retries start', () async {
    final fixture = _Fixture();
    fixture.runner.startFailure = StateError('connection lost');
    final result = await fixture.run();
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
    expect(result.reason, 'runner_error');
    expect(fixture.runner.calls, ['capabilities', 'start', 'cancel']);
  });

  test('every selected check needs a terminal exit code', () async {
    final fixture = _Fixture();
    final request = ScopedVerificationRequest(
      operationId: 'operation', workspaceRoot: 'root', deadline: fixture.clock.now().add(const Duration(seconds: 30)),
      selections: [
        ScopedVerificationSelection(check: ScopedVerificationCheck(id: 'dart', executable: 'dart'), paths: const ['lib/main.dart']),
        ScopedVerificationSelection(check: ScopedVerificationCheck(id: 'test', executable: 'test'), paths: const ['lib/main.dart']),
      ],
    );
    final result = await fixture.service.call(request, cancellation: fixture.scope);
    expect(result.outcome, ScopedVerificationOutcome.incomplete);
  });
}

final class _Fixture {
  final clock = _Clock();
  final runner = _Runner();
  final scope = AgentCancellationScope();
  ScopedVerificationService get service => ScopedVerificationService(runner: runner, clock: clock);
  Future<ScopedVerificationResult> run() => service.call(
    ScopedVerificationRequest(operationId: 'operation', workspaceRoot: 'root', deadline: clock.now().add(const Duration(seconds: 30)), selections: [ScopedVerificationSelection(check: ScopedVerificationCheck(id: 'dart', executable: 'dart'), paths: const ['lib/main.dart'])]),
    cancellation: scope,
  );
}

final class _Runner implements ScopedVerificationRunner, ScopedVerificationRunnerLifecycle {
  int closed = 0;
  @override
  void close() { closed++; }
  final calls = <String>[];
  ScopedVerificationCapabilities capability = ScopedVerificationCapabilities(protocol: ScopedVerificationLimits.protocol, features: ScopedVerificationCapabilities.requiredFeatures);
  Future<ScopedVerificationCapabilities>? capabilityResult;
  Future<ScopedVerificationJob>? startResult;
  Future<ScopedVerificationJob>? cancelResult;
  Object? startFailure;
  Object? pollFailure;
  ScopedVerificationJob? reply;
  final cancelledOperations = <String>{};
  int remoteExecutions = 0;

  ScopedVerificationJob job({String operationId = 'operation', String root = 'root', ScopedVerificationJobState state = .completed, bool scopeValidated = true, Map<String, int> exitCodes = const {'dart': 0}, String output = ''}) => ScopedVerificationJob(operationId: operationId, workspaceRoot: root, state: state, scopeValidated: scopeValidated, exitCodes: exitCodes, output: output, cancellationRecorded: state == .cancelled);

  ScopedVerificationJob registerLate(String operationId) {
    if (cancelledOperations.contains(operationId)) return job(operationId: operationId, state: .cancelled, exitCodes: const {});
    remoteExecutions++;
    return job(operationId: operationId);
  }

  @override
  Future<ScopedVerificationCapabilities> capabilities() async {
    calls.add('capabilities');
    return await (capabilityResult ?? Future.value(capability));
  }
  @override
  Future<ScopedVerificationJob> start(ScopedVerificationRequest request) async {
    calls.add('start');
    if (startFailure case final Object failure) throw failure;
    return await (startResult ?? Future.value(reply ?? job()));
  }
  @override
  Future<ScopedVerificationJob> poll(String operationId) async {
    calls.add('poll');
    if (pollFailure case final Object failure) throw failure;
    return reply ?? job();
  }
  @override
  Future<ScopedVerificationJob> cancel(String operationId) async {
    calls.add('cancel');
    cancelledOperations.add(operationId);
    return await (cancelResult ?? Future.value(job(state: .cancelled, exitCodes: const {})));
  }
}

final class _Clock implements ScopedVerificationClock {
  DateTime _time = DateTime.utc(2026, 11, 2);
  final _timers = <_Timer>[];
  int get activeTimers => _timers.where((timer) => timer.isActive).length;
  @override
  DateTime now() => _time;
  @override
  Timer schedule(Duration duration, void Function() callback) {
    final timer = _Timer(_time.add(duration), callback);
    _timers.add(timer);
    return timer;
  }
  void elapse(Duration duration) {
    _time = _time.add(duration);
    for (final timer in List<_Timer>.of(_timers)) {
      if (timer.isActive && !timer.at.isAfter(_time)) timer.fire();
    }
  }
}

final class _Timer implements Timer {
  _Timer(this.at, this.callback);
  final DateTime at;
  final void Function() callback;
  bool _active = true;
  @override
  bool get isActive => _active;
  @override
  int get tick => _active ? 0 : 1;
  @override
  void cancel() => _active = false;
  void fire() {
    _active = false;
    callback();
  }
}

Future<void> _flush() async {
  for (var count = 0; count < 20; count++) {
    await Future<void>.value();
  }
}
