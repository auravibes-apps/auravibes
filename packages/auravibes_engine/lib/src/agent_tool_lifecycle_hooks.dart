import 'dart:convert';

const maxAgentToolHookReasonBytes = 1024;
const maxAgentToolHookContextBytes = 4096;
const _maxHookArgumentJsonCodeUnits = 4096;
const _maxHookArgumentNames = 24;
const _maxHookArgumentNameBytes = 24;

typedef AgentToolHookCancellationChecker = bool Function(String conversationId);

/// Extracts bounded argument names without passing tool argument values.
List<String> sanitizedAgentToolHookArgumentNames(String argumentsRaw) {
  if (argumentsRaw.length > _maxHookArgumentJsonCodeUnits) return const [];

  try {
    final decoded = jsonDecode(argumentsRaw);
    if (decoded is! Map<String, dynamic>) return const [];

    return decoded.keys
        .take(_maxHookArgumentNames)
        .map((name) => _boundedUtf8(name, _maxHookArgumentNameBytes))
        .toList(growable: false);
  } on FormatException {
    return const [];
  }
}

String _boundedUtf8(String value, int maxBytes) {
  return truncateAgentToolHookText(value, maxBytes);
}

/// Truncates a string by UTF-8 byte count without allocating the full encoding.
String truncateAgentToolHookText(String value, int maxBytes) {
  if (maxBytes <= 0) return '';
  final output = StringBuffer();
  var byteCount = 0;
  for (final rune in value.runes) {
    final runeBytes = switch (rune) {
      <= 0x7f => 1,
      <= 0x7ff => 2,
      <= 0xffff => 3,
      _ => 4,
    };
    if (byteCount + runeBytes > maxBytes) return output.toString();
    output.writeCharCode(rune);
    byteCount += runeBytes;
  }

  return value;
}

/// Result of asking a host to run a trusted pre-tool or post-tool hook.
enum AgentToolHookOutcome {
  /// The pre-tool hook permits dispatch.
  allow,

  /// The pre-tool hook explicitly blocks dispatch.
  block,

  /// The hook completed successfully.
  success,

  /// The hook exceeded its runtime bound.
  timedOut,

  /// The hook exceeded its output bound.
  outputLimitExceeded,

  /// The hook could not run or returned an invalid response.
  failed,

  /// The hook runtime is unsupported for this workspace or platform.
  unavailable,

  /// The conversation was cancelled while the hook was running.
  cancelled,
}

/// Sanitized metadata for one tool lifecycle hook invocation.
///
/// Deliberately excludes raw tool arguments and result content. Hosts may pass
/// only the argument names to a hook process.
class const AgentToolLifecycleHookRequest<TTool extends Object>({
  required final String workspaceId,
  required final String conversationId,
  required final String toolCallId,
  required final TTool tool,
  required final List<String> argumentNames,
});

/// Data returned by a pre-tool hook.
class const AgentPreToolHookResult({
  required final AgentToolHookOutcome outcome,
  final String? reason,
});

/// Data returned by a post-tool hook.
class const AgentPostToolHookResult({
  required final AgentToolHookOutcome outcome,
  final String? context,
});

/// Host adapter for trusted lifecycle hooks.
///
/// The engine owns ordering and failure policy. The host owns opt-in, trust,
/// configuration loading, and any platform-specific hook execution.
abstract interface class AgentToolLifecycleHookRunner<TTool extends Object> {
  Future<AgentPreToolHookResult> beforeTool({
    required AgentToolLifecycleHookRequest<TTool> request,
    required AgentToolHookCancellationChecker isCancellationRequested,
  });

  Future<AgentPostToolHookResult> afterTool({
    required AgentToolLifecycleHookRequest<TTool> request,
    required bool toolSucceeded,
    required AgentToolHookCancellationChecker isCancellationRequested,
  });
}
