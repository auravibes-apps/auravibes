import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_process.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_source_inspector.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:path/path.dart' as p;

typedef _Invocation = AgentLifecycleHookInvocationRequest;
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
  Future<AgentLifecycleHookInvocationResult> invoke(
    AgentLifecycleHookInvocationRequest request,
  ) => _invoke(request);

  Future<AgentLifecycleHookInvocationResult> _invoke(
    _Invocation request,
  ) async {
    final failure = _inputFailure(request);
    if (failure != null) return .new(outcome: failure);
    return await _invokeReinspected(request);
  }

  Future<AgentLifecycleHookInvocationResult> _invokeReinspected(
    _Invocation request,
  ) async {
    final checked = await _reinspect(request);
    return await _completeInvocation(request, checked);
  }

  Future<AgentLifecycleHookInvocationResult> _completeInvocation(
    _Invocation request,
    _Reinspection checked,
  ) async {
    if (checked.failure case final failure?) return .new(outcome: failure);
    final current = checked.snapshot;
    if (current == null) return const .new(outcome: .failed);
    final commandPath = current.commandPaths[request.hook.event];
    if (commandPath == null) return const .new(outcome: .unavailable);

    final processRequest = _processRequest(current, request, commandPath);

    return await const AgentLifecycleHookProcess().run(processRequest);
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
) {
  final hook = request.hook;
  final conversationId = request.conversationId;
  final cancellationCheck = request.isCancellationRequested;

  return (
    commandPath: commandPath,
    arguments: hook.args,
    workingDirectory: p.dirname(current.canonicalPath),
    inputBytes: utf8.encode(request.input),
    isCancellationRequested: () => cancellationCheck(conversationId),
    isStillTrusted: request.isStillTrusted,
  );
}

bool _inputExceedsLimit(String input) =>
    input.length > maxAgentLifecycleHookInputBytes ||
    utf8.encode(input).length > maxAgentLifecycleHookInputBytes;

bool _matchesInvocation(
  AgentLifecycleHookSourceSnapshot current,
  _Invocation request,
) {
  if (current.digest != request.snapshot.digest) return false;
  final expectedHook = request.hook;
  final currentHook = _currentHook(current, expectedHook.event);
  if (currentHook == null) return false;

  return _sameHook(currentHook, expectedHook);
}

AgentLifecycleHookDefinition? _currentHook(
  AgentLifecycleHookSourceSnapshot snapshot,
  AgentLifecycleHookEvent event,
) {
  final hook = snapshot.config.hookFor(event);
  if (snapshot.commandPaths[event] == null) return null;

  return hook;
}

bool _sameHook(
  AgentLifecycleHookDefinition actual,
  AgentLifecycleHookDefinition expected,
) {
  final commandMatches = actual.command == expected.command;
  final argumentsMatch = _sameArguments(actual.args, expected.args);

  return commandMatches && argumentsMatch;
}

bool _sameArguments(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }

  return true;
}
