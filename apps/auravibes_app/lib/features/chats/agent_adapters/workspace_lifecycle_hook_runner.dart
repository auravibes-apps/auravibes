import 'dart:convert';

import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

typedef _LoadedHookConfig = ({
  agent.AgentToolHookOutcome? failure,
  AgentLifecycleHookSourceSnapshot? snapshot,
});
typedef _HookRequest = ({
  agent.AgentToolLifecycleHookRequest<ResolvedTool> request,
  agent.AgentToolHookCancellationChecker isCancellationRequested,
  AgentLifecycleHookEvent event,
  bool? toolSucceeded,
});
typedef _TrustedHookRequest = ({
  _HookRequest input,
  AgentLifecycleHookSourceSnapshot snapshot,
  AgentLifecycleHookDefinition hook,
});

const _LoadedHookConfig _unavailableConfig = (
  failure: .unavailable,
  snapshot: null,
);
const _LoadedHookConfig _failedConfig = (failure: .failed, snapshot: null);
const _maxHookIdentifierBytes = 128;
const _maxHookArgumentNames = 24;
const _maxHookArgumentNameBytes = 24;

class const WorkspaceLifecycleHookRunner({
  required final WorkspaceAgentHookSettingsRepository settingsRepository,
  required final WorkspaceRepository workspaceRepository,
  required final AgentLifecycleHookRuntime runtime,
}) implements agent.AgentToolLifecycleHookRunner<ResolvedTool> {
  @override
  Future<agent.AgentPreToolHookResult> beforeTool({
    required agent.AgentToolLifecycleHookRequest<ResolvedTool> request,
    required agent.AgentToolHookCancellationChecker isCancellationRequested,
  }) async {
    final invocation = await _invokeFor((
      request: request,
      isCancellationRequested: isCancellationRequested,
      event: .beforeTool,
      toolSucceeded: null,
    ));
    if (invocation == null) return const .new(outcome: .allow);
    if (invocation.outcome != agent.AgentToolHookOutcome.success) {
      return _preFailure(invocation.outcome);
    }

    return _preResponse(invocation.stdout);
  }

  @override
  Future<agent.AgentPostToolHookResult> afterTool({
    required agent.AgentToolLifecycleHookRequest<ResolvedTool> request,
    required bool toolSucceeded,
    required agent.AgentToolHookCancellationChecker isCancellationRequested,
  }) async {
    final invocation = await _invokeFor((
      request: request,
      isCancellationRequested: isCancellationRequested,
      event: .afterTool,
      toolSucceeded: toolSucceeded,
    ));
    if (invocation == null) return const .new(outcome: .success);
    if (invocation.outcome != agent.AgentToolHookOutcome.success) {
      return .new(outcome: invocation.outcome);
    }

    return _postResponse(invocation.stdout);
  }

  Future<AgentLifecycleHookInvocationResult?> _invokeFor(
    _HookRequest input,
  ) async {
    final loaded = await _loadTrustedConfig(input.request.workspaceId);
    if (loaded == null) return null;
    return await _invokeLoaded(input, loaded);
  }

  Future<AgentLifecycleHookInvocationResult?> _invokeLoaded(
    _HookRequest input,
    _LoadedHookConfig loaded,
  ) async {
    if (loaded.failure case final failure?) return .new(outcome: failure);
    final snapshot = loaded.snapshot;
    if (snapshot == null) return const .new(outcome: .failed);
    return await _invokeSelectedHook(input, snapshot);
  }

  Future<AgentLifecycleHookInvocationResult?> _invokeSelectedHook(
    _HookRequest input,
    AgentLifecycleHookSourceSnapshot snapshot,
  ) async {
    final hook = snapshot.config.hookFor(input.event);
    if (hook == null) return null;

    return await _invokeTrusted((input: input, snapshot: snapshot, hook: hook));
  }

  Future<AgentLifecycleHookInvocationResult> _invokeTrusted(
    _TrustedHookRequest prepared,
  ) async {
    final input = prepared.input;
    final request = input.request;
    if (!await _isStillTrusted(
      workspaceRepository,
      settingsRepository,
      request.workspaceId,
      prepared.snapshot,
    )) {
      return const .new(outcome: .unavailable);
    }
    if (input.isCancellationRequested(request.conversationId)) {
      return const .new(outcome: .cancelled);
    }

    return await _runtimeInvocation(prepared);
  }

  Future<AgentLifecycleHookInvocationResult> _runtimeInvocation(
    _TrustedHookRequest prepared,
  ) => runtime.invoke(
    _runtimeRequest(prepared, workspaceRepository, settingsRepository),
  );

  Future<_LoadedHookConfig?> _loadTrustedConfig(String workspaceId) async {
    if (workspaceId.trim().isEmpty) return _unavailableConfig;
    final workspace = await workspaceRepository.getWorkspaceById(workspaceId);
    if (workspace == null) return _unavailableConfig;
    final settings = await settingsRepository.get(workspaceId);
    if (!settings.enabled) return null;
    final path = _trustedConfigPath(settings, workspace);
    if (path == null) return _unavailableConfig;

    return await _inspectTrustedConfig(path, settings);
  }

  String? _trustedConfigPath(
    WorkspaceAgentHookSettings settings,
    WorkspaceEntity workspace,
  ) {
    if (!runtime.isSupported ||
        !workspace.type.isLocal ||
        !settings.isTrusted) {
      return null;
    }

    return settings.configPath;
  }

  Future<_LoadedHookConfig> _inspectTrustedConfig(
    String path,
    WorkspaceAgentHookSettings settings,
  ) async {
    try {
      final snapshot = await runtime.inspect(path);
      if (!settings.trustsSource(
        canonicalPath: snapshot.canonicalPath,
        digest: snapshot.digest,
      ))
        return _unavailableConfig;

      return (failure: null, snapshot: snapshot);
    } on Object {
      return _failedConfig;
    }
  }
}

AgentLifecycleHookInvocationRequest _runtimeRequest(
  _TrustedHookRequest prepared,
  WorkspaceRepository workspaceRepository,
  WorkspaceAgentHookSettingsRepository settingsRepository,
) {
  final input = prepared.input;
  final request = input.request;

  return (
    snapshot: prepared.snapshot,
    hook: prepared.hook,
    input: _hookInput(input),
    isCancellationRequested: input.isCancellationRequested,
    conversationId: request.conversationId,
    isStillTrusted: _trustRecheck(
      prepared,
      workspaceRepository,
      settingsRepository,
    ),
  );
}

Future<bool> Function() _trustRecheck(
  _TrustedHookRequest prepared,
  WorkspaceRepository workspaceRepository,
  WorkspaceAgentHookSettingsRepository settingsRepository,
) {
  final workspaceId = prepared.input.request.workspaceId;
  final snapshot = prepared.snapshot;

  return () => _isStillTrusted(
    workspaceRepository,
    settingsRepository,
    workspaceId,
    snapshot,
  );
}

agent.AgentPreToolHookResult _preResponse(String? raw) {
  final response = _decodeHookResponse(raw);
  if (response == null) {
    return const .new(
      outcome: .failed,
      reason: 'The pre-tool hook returned an invalid response.',
    );
  }

  return switch (response['decision']) {
    'allow' => _allowDecision(response),
    'block' => _blockDecision(response),
    _ => _invalidDecision(),
  };
}

agent.AgentPreToolHookResult _allowDecision(Map<String, dynamic> response) =>
    _hasOnlyResponseFields(response, const {'decision'})
    ? const .new(outcome: .allow)
    : _invalidDecision();

agent.AgentPreToolHookResult _blockDecision(Map<String, dynamic> response) {
  if (!_hasOnlyResponseFields(response, const {'decision', 'reason'})) {
    return _invalidDecision();
  }
  final rawReason = response['reason'];
  final reason = rawReason is String ? _redactAndTrim(rawReason) : null;

  return .new(
    outcome: .block,
    reason: reason?.isNotEmpty == true
        ? reason
        : 'Blocked by a trusted lifecycle hook.',
  );
}

agent.AgentPreToolHookResult _invalidDecision() => const .new(
  outcome: .failed,
  reason: 'The pre-tool hook returned an invalid decision.',
);

agent.AgentPostToolHookResult _postResponse(String? raw) {
  final response = _decodeHookResponse(raw);
  final context = response?['context'];
  if (response == null ||
      context is! String ||
      !_hasOnlyResponseFields(response, const {'context'})) {
    return const .new(outcome: .failed);
  }

  return .new(outcome: .success, context: _redactAndTrim(context));
}

bool _hasOnlyResponseFields(Map<String, dynamic> value, Set<String> allowed) =>
    value.keys.toSet().difference(allowed).isEmpty;

agent.AgentPreToolHookResult _preFailure(agent.AgentToolHookOutcome outcome) =>
    agent.AgentPreToolHookResult(
      outcome:
          outcome == agent.AgentToolHookOutcome.allow ||
              outcome == agent.AgentToolHookOutcome.success
          ? agent.AgentToolHookOutcome.failed
          : outcome,
      reason: switch (outcome) {
        .block => 'Blocked by a trusted lifecycle hook.',
        .timedOut => 'The pre-tool hook timed out.',
        .outputLimitExceeded => 'The pre-tool hook exceeded its output limit.',
        .unavailable => 'The pre-tool hook is not trusted or available.',
        .cancelled => null,
        .failed => 'The pre-tool hook failed.',
        .allow || .success => 'The pre-tool hook failed.',
      },
    );

Map<String, dynamic>? _decodeHookResponse(String? raw) {
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);

    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String _hookInput(_HookRequest input) {
  final identifiers = _hookInputIdentifiers(input.request);

  return jsonEncode({
    'version': 1,
    'event': input.event.name,
    ...identifiers,
    'toolSucceeded': ?input.toolSucceeded,
  });
}

Map<String, Object?> _hookInputIdentifiers(
  agent.AgentToolLifecycleHookRequest<ResolvedTool> request,
) {
  final toolCallId = _truncateUtf8(request.toolCallId, _maxHookIdentifierBytes);
  final toolIdentifier = _truncateUtf8(
    request.tool.toolIdentifier,
    _maxHookIdentifierBytes,
  );
  final argumentNames = request.argumentNames
      .take(_maxHookArgumentNames)
      .map((name) => _truncateUtf8(name, _maxHookArgumentNameBytes))
      .toList(growable: false);

  return {
    'toolCallId': toolCallId,
    'tool': toolIdentifier,
    'argumentNames': argumentNames,
  };
}

String _redactAndTrim(String value) => LogRedaction.redact(value).trim();

String _truncateUtf8(String value, int maxBytes) =>
    agent.truncateAgentToolHookText(value, maxBytes);

Future<bool> _isStillTrusted(
  WorkspaceRepository workspaceRepository,
  WorkspaceAgentHookSettingsRepository settingsRepository,
  String workspaceId,
  AgentLifecycleHookSourceSnapshot snapshot,
) async {
  final workspace = await workspaceRepository.getWorkspaceById(workspaceId);
  if (workspace == null || !workspace.type.isLocal) return false;
  final settings = await settingsRepository.get(workspaceId);

  return settings.enabled &&
      settings.trustsSource(
        canonicalPath: snapshot.canonicalPath,
        digest: snapshot.digest,
      );
}
