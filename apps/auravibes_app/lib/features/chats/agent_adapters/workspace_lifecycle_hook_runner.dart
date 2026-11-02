import 'dart:convert';

import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_app/services/log_redaction.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;

class WorkspaceLifecycleHookRunner
    implements agent.AgentToolLifecycleHookRunner<ResolvedTool> {
  const WorkspaceLifecycleHookRunner({
    required WorkspaceAgentHookSettingsRepository settingsRepository,
    required WorkspaceRepository workspaceRepository,
    required AgentLifecycleHookRuntime runtime,
  }) : _settingsRepository = settingsRepository,
       _workspaceRepository = workspaceRepository,
       _runtime = runtime;

  final WorkspaceAgentHookSettingsRepository _settingsRepository;
  final WorkspaceRepository _workspaceRepository;
  final AgentLifecycleHookRuntime _runtime;

  @override
  Future<agent.AgentPreToolHookResult> beforeTool({
    required agent.AgentToolLifecycleHookRequest<ResolvedTool> request,
    required agent.AgentToolHookCancellationChecker isCancellationRequested,
  }) async {
    final loaded = await _loadTrustedConfig(request.workspaceId);
    if (loaded == null) {
      return const agent.AgentPreToolHookResult(outcome: .allow);
    }
    if (loaded.failure != null) {
      return _preFailure(loaded.failure!);
    }

    final snapshot = loaded.snapshot!;
    final hook = snapshot.config.hookFor(AgentLifecycleHookEvent.beforeTool);
    if (hook == null)
      return const agent.AgentPreToolHookResult(outcome: .allow);
    if (!await _isStillTrusted(request.workspaceId, snapshot)) {
      return _preFailure(agent.AgentToolHookOutcome.unavailable);
    }
    if (isCancellationRequested(request.conversationId)) {
      return const agent.AgentPreToolHookResult(outcome: .cancelled);
    }

    final invocation = await _runtime.invoke(
      snapshot: snapshot,
      hook: hook,
      input: _hookInput(request, event: 'beforeTool'),
      isCancellationRequested: isCancellationRequested,
      conversationId: request.conversationId,
      isStillTrusted: () => _isStillTrusted(request.workspaceId, snapshot),
    );
    if (invocation.outcome != agent.AgentToolHookOutcome.success) {
      return _preFailure(invocation.outcome);
    }

    final response = _decodeHookResponse(invocation.stdout);
    if (response == null) {
      return const agent.AgentPreToolHookResult(
        outcome: .failed,
        reason: 'The pre-tool hook returned an invalid response.',
      );
    }
    if (response['decision'] == 'allow' &&
        response.keys.toSet().difference({'decision'}).isEmpty) {
      return const agent.AgentPreToolHookResult(outcome: .allow);
    }
    if (response['decision'] == 'block' &&
        response.keys.toSet().difference({'decision', 'reason'}).isEmpty) {
      final rawReason = response['reason'];
      final reason = rawReason is String ? _redactAndTrim(rawReason) : null;

      return agent.AgentPreToolHookResult(
        outcome: .block,
        reason: reason?.isNotEmpty == true
            ? reason
            : 'Blocked by a trusted lifecycle hook.',
      );
    }

    return const agent.AgentPreToolHookResult(
      outcome: .failed,
      reason: 'The pre-tool hook returned an invalid decision.',
    );
  }

  @override
  Future<agent.AgentPostToolHookResult> afterTool({
    required agent.AgentToolLifecycleHookRequest<ResolvedTool> request,
    required bool toolSucceeded,
    required agent.AgentToolHookCancellationChecker isCancellationRequested,
  }) async {
    final loaded = await _loadTrustedConfig(request.workspaceId);
    if (loaded == null) {
      return const agent.AgentPostToolHookResult(outcome: .success);
    }
    if (loaded.failure != null) {
      return agent.AgentPostToolHookResult(outcome: loaded.failure!);
    }

    final snapshot = loaded.snapshot!;
    final hook = snapshot.config.hookFor(AgentLifecycleHookEvent.afterTool);
    if (hook == null) {
      return const agent.AgentPostToolHookResult(outcome: .success);
    }
    if (!await _isStillTrusted(request.workspaceId, snapshot)) {
      return const agent.AgentPostToolHookResult(outcome: .unavailable);
    }
    if (isCancellationRequested(request.conversationId)) {
      return const agent.AgentPostToolHookResult(outcome: .cancelled);
    }

    final invocation = await _runtime.invoke(
      snapshot: snapshot,
      hook: hook,
      input: _hookInput(
        request,
        event: 'afterTool',
        toolSucceeded: toolSucceeded,
      ),
      isCancellationRequested: isCancellationRequested,
      conversationId: request.conversationId,
      isStillTrusted: () => _isStillTrusted(request.workspaceId, snapshot),
    );
    if (invocation.outcome != agent.AgentToolHookOutcome.success) {
      return agent.AgentPostToolHookResult(outcome: invocation.outcome);
    }

    final response = _decodeHookResponse(invocation.stdout);
    if (response == null ||
        response.keys.toSet().difference({'context'}).isNotEmpty ||
        response['context'] is! String) {
      return const agent.AgentPostToolHookResult(outcome: .failed);
    }

    return agent.AgentPostToolHookResult(
      outcome: .success,
      context: _redactAndTrim(response['context']! as String),
    );
  }

  Future<bool> _isStillTrusted(
    String workspaceId,
    AgentLifecycleHookSourceSnapshot snapshot,
  ) async {
    final workspace = await _workspaceRepository.getWorkspaceById(workspaceId);
    if (workspace == null || !workspace.type.isLocal) return false;
    final settings = await _settingsRepository.get(workspaceId);

    return settings.enabled &&
        settings.isTrusted &&
        settings.configPath == snapshot.canonicalPath &&
        settings.trustedSourcePath == snapshot.canonicalPath &&
        settings.trustedDigest == snapshot.digest;
  }

  Future<
    ({
      agent.AgentToolHookOutcome? failure,
      AgentLifecycleHookSourceSnapshot? snapshot,
    })?
  >
  _loadTrustedConfig(String workspaceId) async {
    if (workspaceId.trim().isEmpty) {
      return (failure: agent.AgentToolHookOutcome.unavailable, snapshot: null);
    }

    final workspace = await _workspaceRepository.getWorkspaceById(workspaceId);
    if (workspace == null) {
      return (failure: agent.AgentToolHookOutcome.unavailable, snapshot: null);
    }

    final settings = await _settingsRepository.get(workspaceId);
    if (!settings.enabled) return null;
    if (!_runtime.isSupported) {
      return (failure: agent.AgentToolHookOutcome.unavailable, snapshot: null);
    }

    if (!workspace.type.isLocal) {
      return (failure: agent.AgentToolHookOutcome.unavailable, snapshot: null);
    }

    final configPath = settings.configPath;
    if (configPath == null || !settings.isTrusted) {
      return (failure: agent.AgentToolHookOutcome.unavailable, snapshot: null);
    }

    try {
      final snapshot = await _runtime.inspect(configPath);
      if (snapshot.canonicalPath != settings.trustedSourcePath ||
          snapshot.canonicalPath != configPath ||
          snapshot.digest != settings.trustedDigest) {
        return (
          failure: agent.AgentToolHookOutcome.unavailable,
          snapshot: null,
        );
      }

      return (failure: null, snapshot: snapshot);
    } on AgentLifecycleHookConfigException {
      return (failure: agent.AgentToolHookOutcome.failed, snapshot: null);
    } on Object {
      return (failure: agent.AgentToolHookOutcome.failed, snapshot: null);
    }
  }
}

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

String _hookInput(
  agent.AgentToolLifecycleHookRequest<ResolvedTool> request, {
  required String event,
  bool? toolSucceeded,
}) => jsonEncode({
  'version': 1,
  'event': event,
  'toolCallId': _truncateUtf8(request.toolCallId, 128),
  'tool': _truncateUtf8(request.tool.toolIdentifier, 128),
  'argumentNames': request.argumentNames
      .take(24)
      .map((name) => _truncateUtf8(name, 24))
      .toList(growable: false),
  if (toolSucceeded != null) 'toolSucceeded': toolSucceeded,
});

String _redactAndTrim(String value) => LogRedaction.redact(value).trim();

String _truncateUtf8(String value, int maxBytes) {
  return agent.truncateAgentToolHookText(value, maxBytes);
}
