import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
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

    return await _HookProcessSupervisor(process, request.isCancellationRequested)
        .run(request.inputBytes);
  }
}

Future<_LaunchResult> _launch(AgentLifecycleHookProcessRequest request) async {
  try {
    if (!await request.isStillTrusted()) {
      return (process: null, failure: .unavailable);
    }
  } on Object {
    return (process: null, failure: .failed);
  }
  // Keep this synchronous check adjacent to launch after the final trust await.
  if (request.isCancellationRequested()) {
    return (process: null, failure: .cancelled);
  }
  try {
    final process = await Process.start(
      request.commandPath,
      request.arguments,
      workingDirectory: request.workingDirectory,
      environment: const {},
      includeParentEnvironment: false,
    );

    return (process: process, failure: null);
  } on Object {
    return (process: null, failure: .failed);
  }
}

class _HookProcessSupervisor {
  new(this.process, this.isCancellationRequested)
      : _termination = _HookProcessTermination(process);

  final Process process;
  final bool Function() isCancellationRequested;
  final _HookProcessTermination _termination;
  final _output = BytesBuilder(copy: false);
  final _outputDone = Completer<void>();
  final _errorDone = Completer<void>();
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  int _outputBytes = 0;
  AgentToolHookOutcome _outcome = .success;

  Future<AgentLifecycleHookInvocationResult> run(List<int> inputBytes) async {
    final exitCodeFuture = _termination.exitCode;
    _attachStreams();
    unawaited(_writeInput(process, inputBytes));
    final exitCode = await _waitWithTimers(exitCodeFuture);
    await _drain();
    _recordExitOutcome(exitCode);

    return _result();
  }

  void _attachStreams() {
    _stdoutSubscription = _listen(process.stdout, capture: true, done: _outputDone);
    _stderrSubscription = _listen(process.stderr, capture: false, done: _errorDone);
  }

  Future<int> _waitWithTimers(Future<int> exitCode) async {
    final timeout = Timer(agentLifecycleHookTimeout, () => _fail(.timedOut));
    final cancellation = Timer.periodic(_cancellationInterval, _pollCancellation);
    try {
      return await _waitForExit(exitCode);
    } finally {
      timeout.cancel();
      cancellation.cancel();
    }
  }

  StreamSubscription<List<int>> _listen(
    Stream<List<int>> stream, {
    required bool capture,
    required Completer<void> done,
  }) => stream.listen(
    (chunk) => _consume(chunk, capture: capture),
    onError: (Object _) => _fail(.failed),
    onDone: done.complete,
    cancelOnError: false,
  );

  void _consume(List<int> chunk, {required bool capture}) {
    if (_outcome != AgentToolHookOutcome.success) return;
    _outputBytes += chunk.length;
    if (_outputBytes > maxAgentLifecycleHookOutputBytes) {
      _fail(.outputLimitExceeded);

      return;
    }
    if (capture) _output.add(chunk);
  }

  void _fail(AgentToolHookOutcome failure) {
    if (_outcome != AgentToolHookOutcome.success) return;
    _outcome = failure;
    unawaited(_termination.stop());
  }

  void _pollCancellation(Timer _) {
    if (_outcome == AgentToolHookOutcome.success && isCancellationRequested()) {
      _fail(.cancelled);
    }
  }

  Future<int> _waitForExit(Future<int> exitCode) async {
    try {
      return await exitCode.timeout(
        agentLifecycleHookTimeout + _forcedStopTimeout,
        onTimeout: _onExitTimeout,
      );
    } on Object {
      _fail(.failed);
      await _termination.stop();

      return -1;
    }
  }

  Future<int> _onExitTimeout() async {
    if (_outcome == AgentToolHookOutcome.success) _outcome = .timedOut;
    await _termination.stop();

    return -1;
  }

  Future<void> _drain() async {
    try {
      final _ = await Future.wait([_outputDone.future, _errorDone.future])
          .timeout(_streamDrainTimeout);
    } on Object {
      _fail(.failed);
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
    }
  }

  void _recordExitOutcome(int exitCode) {
    if (_outcome == AgentToolHookOutcome.success && exitCode != 0) {
      _outcome = .failed;
    }
    if (_outcome == AgentToolHookOutcome.success && isCancellationRequested()) {
      _outcome = .cancelled;
    }
  }

  AgentLifecycleHookInvocationResult _result() {
    if (_outcome != AgentToolHookOutcome.success) return .new(outcome: _outcome);
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

  Future<int> _trackExit() async {
    final code = await process.exitCode;
    _exited = true;

    return code;
  }

  Future<void> stop() => _stopping ??= _stop();

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
