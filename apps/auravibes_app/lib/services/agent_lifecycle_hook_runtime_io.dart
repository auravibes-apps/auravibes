import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_process.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_source_inspector.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:path/path.dart' as p;

typedef _Invocation = ({
  AgentLifecycleHookSourceSnapshot snapshot,
  AgentLifecycleHookDefinition hook,
  String input,
  AgentToolHookCancellationChecker isCancellationRequested,
  String conversationId,
  Future<bool> Function() isStillTrusted,
});
typedef _Reinspection = ({
  AgentLifecycleHookSourceSnapshot? snapshot,
  AgentToolHookOutcome? failure,
});

AgentLifecycleHookRuntime createAgentLifecycleHookRuntime() =>
    const AgentLifecycleHookRuntimeIo();

class const AgentLifecycleHookRuntimeIo() implements AgentLifecycleHookRuntime {
  @override
  bool get isSupported =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    if (!isSupported) {
      throw const AgentLifecycleHookConfigException('unsupported_platform');
    }

    return await const AgentLifecycleHookSourceInspector().inspect(sourcePath);
  }

  @override
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
    required Future<bool> Function() isStillTrusted,
  }) => _invoke((
    snapshot: snapshot,
    hook: hook,
    input: input,
    isCancellationRequested: isCancellationRequested,
    conversationId: conversationId,
    isStillTrusted: isStillTrusted,
  ));

  Future<AgentLifecycleHookInvocationResult> _invoke(
    _Invocation request,
  ) async {
    final failure = _inputFailure(request);
    if (failure != null) return .new(outcome: failure);
    final checked = await _reinspect(request);
    if (checked.failure case final failure?) return .new(outcome: failure);
    final current = checked.snapshot;
    if (current == null) return const .new(outcome: .failed);
    final commandPath = current.commandPaths[request.hook.event];
    if (commandPath == null) return const .new(outcome: .unavailable);

    return await const AgentLifecycleHookProcess().run(
      _processRequest(current, request, commandPath),
    );
  }

  AgentToolHookOutcome? _inputFailure(_Invocation request) {
    if (!isSupported) return .unavailable;
    if (request.isCancellationRequested(request.conversationId))
      return .cancelled;
    if (_inputExceedsLimit(request.input)) return .outputLimitExceeded;

    return null;
  }

  Future<_Reinspection> _reinspect(_Invocation request) async {
    final AgentLifecycleHookSourceSnapshot current;
    try {
      // Dispatch through the overridable entrypoint, including the second check.
      current = await inspect(request.snapshot.canonicalPath);
    } on Object {
      return (snapshot: null, failure: AgentToolHookOutcome.failed);
    }
    if (!_matchesInvocation(current, request)) {
      return (snapshot: null, failure: AgentToolHookOutcome.unavailable);
    }

    return (snapshot: current, failure: null);
  }
}

AgentLifecycleHookProcessRequest _processRequest(
  AgentLifecycleHookSourceSnapshot current,
  _Invocation request,
  String commandPath,
) => (
  commandPath: commandPath,
  arguments: request.hook.args,
  workingDirectory: p.dirname(current.canonicalPath),
  inputBytes: utf8.encode(request.input),
  isCancellationRequested: () =>
      request.isCancellationRequested(request.conversationId),
  isStillTrusted: request.isStillTrusted,
);

bool _inputExceedsLimit(String input) =>
    input.length > maxAgentLifecycleHookInputBytes ||
    utf8.encode(input).length > maxAgentLifecycleHookInputBytes;

bool _matchesInvocation(
  AgentLifecycleHookSourceSnapshot current,
  _Invocation request,
) {
  if (current.digest != request.snapshot.digest) return false;
  final hook = current.config.hookFor(request.hook.event);
  if (hook == null || current.commandPaths[request.hook.event] == null)
    return false;

  return hook.command == request.hook.command &&
      _sameArguments(hook.args, request.hook.args);
}

bool _sameArguments(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }

  return true;
}
