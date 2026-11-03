import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

typedef AgentLifecycleHookProcessRequest = ({
  String commandPath,
  List<String> arguments,
  String workingDirectory,
  List<int> inputBytes,
  bool Function() isCancellationRequested,
  Future<bool> Function() isStillTrusted,
});
typedef _LaunchResult = ({Process? process, AgentToolHookOutcome? failure});

const _LaunchResult _failedLaunch = (
  process: null,
  failure: AgentToolHookOutcome.failed,
);
const _LaunchResult _unavailableLaunch = (
  process: null,
  failure: AgentToolHookOutcome.unavailable,
);
const _LaunchResult _cancelledLaunch = (
  process: null,
  failure: AgentToolHookOutcome.cancelled,
);

const _gracefulStopTimeout = Duration(milliseconds: 150);
const _forcedStopTimeout = Duration(milliseconds: 250);
const _streamDrainTimeout = Duration(milliseconds: 100);
const _cancellationInterval = Duration(milliseconds: 25);

class const AgentLifecycleHookProcess() {
  Future<AgentLifecycleHookInvocationResult> run(
    AgentLifecycleHookProcessRequest request,
  ) async {
    final started = await _launch(request);
    if (started.failure case final failure?) return .new(outcome: failure);
    final process = started.process;
    if (process == null) return const .new(outcome: .failed);

    return await _createSupervisor(
      process,
      request.isCancellationRequested,
    ).run(request.inputBytes);
  }

  static _HookProcessSupervisor _createSupervisor(
    Process process,
    bool Function() isCancellationRequested,
  ) {
    final termination = _HookProcessTermination(process);
    final outcome = _HookProcessOutcome(termination);
    final output = _HookProcessOutput(
      process,
      outcome.fail,
      () => outcome.isSuccess,
    );

    return _HookProcessSupervisor(
      process,
      isCancellationRequested,
      termination,
      outcome,
      output,
    );
  }
}

Future<_LaunchResult> _launch(AgentLifecycleHookProcessRequest request) async {
  final bool trusted;
  try {
    trusted = await request.isStillTrusted();
  } on Object {
    return _failedLaunch;
  }
  if (!trusted) return _unavailableLaunch;
  // Keep this synchronous check adjacent to launch after the final trust await.
  if (request.isCancellationRequested()) return _cancelledLaunch;
  try {
    return (
      process: await Process.start(
        request.commandPath,
        request.arguments,
        workingDirectory: request.workingDirectory,
        environment: const {},
        includeParentEnvironment: false,
      ),
      failure: null,
    );
  } on Object {
    return _failedLaunch;
  }
}

class _HookProcessOutput(
  final Process process,
  final void Function(AgentToolHookOutcome) onFailure,
  final bool Function() isAccepting,
) {
  final outputDone = Completer<void>();
  final errorDone = Completer<void>();
  final _output = BytesBuilder(copy: false);
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  int _outputBytes = 0;

  void attach() {
    _stdoutSubscription = _listen(
      process.stdout,
      capture: true,
      done: outputDone,
    );
    _stderrSubscription = _listen(
      process.stderr,
      capture: false,
      done: errorDone,
    );
  }

  Future<void> cancel() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
  }

  List<int> takeBytes() => _output.takeBytes();

  StreamSubscription<List<int>> _listen(
    Stream<List<int>> stream, {
    required bool capture,
    required Completer<void> done,
  }) => stream.listen(
    (chunk) => _consume(chunk, capture: capture),
    onError: (Object _) => onFailure(.failed),
    onDone: done.complete,
    cancelOnError: false,
  );

  void _consume(List<int> chunk, {required bool capture}) {
    if (!isAccepting()) return;
    _outputBytes += chunk.length;
    if (_outputBytes >
        AgentLifecycleHookRuntimeLimits.maxAgentLifecycleHookOutputBytes) {
      onFailure(.outputLimitExceeded);

      return;
    }
    if (capture) _output.add(chunk);
  }
}

class _HookProcessOutcome(final _HookProcessTermination _termination) {
  AgentToolHookOutcome _outcome = .success;

  bool get isSuccess => _outcome == .success;
  AgentToolHookOutcome get value => _outcome;

  void fail(AgentToolHookOutcome failure) {
    if (!isSuccess) return;
    _outcome = failure;
    unawaited(_termination.stop());
  }

  void setIfSuccess(AgentToolHookOutcome outcome) {
    if (isSuccess) _outcome = outcome;
  }
}

class _HookProcessSupervisor(
  final Process process,
  final bool Function() isCancellationRequested,
  final _HookProcessTermination _termination,
  final _HookProcessOutcome _outcome,
  final _HookProcessOutput _output,
) {
  Future<AgentLifecycleHookInvocationResult> run(List<int> inputBytes) async {
    final exitCodeFuture = _termination.exitCode;
    _output.attach();
    unawaited(_writeInput(process, inputBytes));
    final exitCode = await _waitWithTimers(exitCodeFuture);
    await _drain();
    _recordExitOutcome(exitCode);

    return _result();
  }

  Future<int> _waitWithTimers(Future<int> exitCode) async {
    final timeout = Timer(
      AgentLifecycleHookRuntimeLimits.agentLifecycleHookTimeout,
      () => _outcome.fail(.timedOut),
    );
    final cancellation = Timer.periodic(
      _cancellationInterval,
      _pollCancellation,
    );
    try {
      return await _waitForExit(exitCode);
    } finally {
      timeout.cancel();
      cancellation.cancel();
    }
  }

  void _pollCancellation(Timer _) {
    if (_outcome.isSuccess && isCancellationRequested()) {
      _outcome.fail(.cancelled);
    }
  }

  Future<int> _waitForExit(Future<int> exitCode) async {
    try {
      return await exitCode.timeout(
        AgentLifecycleHookRuntimeLimits.agentLifecycleHookTimeout +
            _forcedStopTimeout,
        onTimeout: _onExitTimeout,
      );
    } on Object {
      _outcome.fail(.failed);
      await _termination.stop();

      return -1;
    }
  }

  Future<int> _onExitTimeout() async {
    _outcome.setIfSuccess(.timedOut);
    await _termination.stop();

    return -1;
  }

  Future<void> _drain() async {
    try {
      final _ = await Future.wait([
        _output.outputDone.future,
        _output.errorDone.future,
      ]).timeout(_streamDrainTimeout);
    } on Object {
      _outcome.fail(.failed);
      await _output.cancel();
    }
  }

  void _recordExitOutcome(int exitCode) {
    if (_outcome.isSuccess && exitCode != 0) {
      _outcome.setIfSuccess(.failed);
    }
    if (_outcome.isSuccess && isCancellationRequested()) {
      _outcome.setIfSuccess(.cancelled);
    }
  }

  AgentLifecycleHookInvocationResult _result() {
    if (!_outcome.isSuccess) {
      return .new(outcome: _outcome.value);
    }
    try {
      return .new(outcome: .success, stdout: utf8.decode(_output.takeBytes()));
    } on FormatException {
      return const .new(outcome: .failed);
    }
  }
}

class _HookProcessTermination {
  new(this.process);

  final Process process;
  bool _exited = false;
  Future<int>? _exitCode;
  Future<void>? _stopping;

  Future<int> get exitCode => _exitCode ??= _trackExit();

  Future<void> stop() => _stopping ??= _stop();

  Future<int> _trackExit() async {
    final code = await process.exitCode;
    _exited = true;

    return code;
  }

  Future<void> _stop() async {
    if (_exited) return;
    _signal();
    if (await _exitedWithin(_gracefulStopTimeout)) return;
    _signal(.sigkill);
    final _ = await _exitedWithin(_forcedStopTimeout);
  }

  void _signal([ProcessSignal signal = ProcessSignal.sigterm]) {
    try {
      final _ = process.kill(signal);
    } on Object {
      // Some platforms support only direct-child termination.
    }
  }

  Future<bool> _exitedWithin(Duration duration) async {
    try {
      final _ = await exitCode.timeout(duration);

      return true;
    } on TimeoutException {
      return _exited;
    }
  }
}

Future<void> _writeInput(Process process, List<int> inputBytes) async {
  try {
    process.stdin.add(inputBytes);
    final _ = await process.stdin.flush();
    final _ = await process.stdin.close();
  } on Object {
    // A hook may exit before consuming its bounded input.
  }
}
