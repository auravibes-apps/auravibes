// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:json_annotation/json_annotation.dart';

/// Represents the result status of a tool call execution.
///
/// This is stored in the database to indicate why a tool call ended.
/// A null resultStatus means the tool is awaiting approval.
@JsonEnum(fieldRename: FieldRename.snake)
enum ToolCallResultStatus {
  /// Tool was approved and is currently executing.
  running,

  /// Tool executed successfully, responseRaw contains the output.
  success,

  /// User skipped this specific tool (continues AI loop).
  skippedByUser,

  /// User stopped all pending tools (halts AI loop).
  stoppedByUser,

  /// Tool not found or not available.
  toolNotFound,

  /// Tool disabled in workspace settings.
  disabledInWorkspace,

  /// Tool disabled in conversation settings.
  disabledInConversation,

  /// Tool denied by selected agent settings.
  disabledByAgent,

  /// Tool not configured.
  notConfigured,

  /// Tool execution threw an error.
  executionError,
}

/// Extension methods for [ToolCallResultStatus].
extension ToolCallResultStatusX on ToolCallResultStatus {
  /// Returns the response string to send to AI when responseRaw is null.
  ///
  /// For [success], this returns an empty string since responseRaw should
  /// contain the actual output.
  String toResponseString() => _responseStrings[this]!;

  /// Whether this result should halt the AI agent loop entirely.
  ///
  /// When true, no response should be sent to the AI for any tools
  /// in this message.
  bool get stopsAgentLoop => agentLifecycle.stopsAgentLoop;

  AgentToolCallLifecycle get agentLifecycle => _agentLifecycles[this]!;

  /// Whether this result represents a failed tool call.
  bool isFailure() => agentLifecycle == AgentToolCallLifecycle.failed;

  /// Whether this result represents successful tool execution.
  bool isSuccess() => this == .success;

  /// Returns the locale key for displaying this status in the UI.
  ///
  /// Use with `.tr()` to get the translated string.
  String get localeKey => _localeKeys[this]!;
}

final _responseStrings = <ToolCallResultStatus, String>{
  ToolCallResultStatus.running: AgentToolCallLifecycle.pending.modelFallback,
  ToolCallResultStatus.success: AgentToolResultStatus.success.modelFallback,
  ToolCallResultStatus.skippedByUser:
      AgentToolCallLifecycle.skippedByUser.modelFallback,
  ToolCallResultStatus.stoppedByUser:
      AgentToolCallLifecycle.stoppedByUser.modelFallback,
  ToolCallResultStatus.toolNotFound:
      AgentToolResultStatus.toolNotFound.modelFallback,
  ToolCallResultStatus.disabledInWorkspace:
      AgentToolResultStatus.disabledInWorkspace.modelFallback,
  ToolCallResultStatus.disabledInConversation:
      AgentToolResultStatus.disabledInConversation.modelFallback,
  ToolCallResultStatus.disabledByAgent:
      AgentToolResultStatus.disabledByAgent.modelFallback,
  ToolCallResultStatus.notConfigured:
      AgentToolResultStatus.notConfigured.modelFallback,
  ToolCallResultStatus.executionError:
      AgentToolResultStatus.executionError.modelFallback,
};

const _agentLifecycles = <ToolCallResultStatus, AgentToolCallLifecycle>{
  .running: .pending,
  .success: .success,
  .skippedByUser: .skippedByUser,
  .stoppedByUser: .stoppedByUser,
  .toolNotFound: .failed,
  .disabledInWorkspace: .failed,
  .disabledInConversation: .failed,
  .disabledByAgent: .failed,
  .notConfigured: .failed,
  .executionError: .failed,
};

const _localeKeys = <ToolCallResultStatus, String>{
  .running: LocaleKeys.tool_call_status_running,
  .success: LocaleKeys.tool_call_status_success,
  .skippedByUser: LocaleKeys.tool_call_status_skipped_by_user,
  .stoppedByUser: LocaleKeys.tool_call_status_stopped_by_user,
  .toolNotFound: LocaleKeys.tool_call_status_tool_not_found,
  .disabledInWorkspace: LocaleKeys.tool_call_status_disabled_in_workspace,
  .disabledInConversation: LocaleKeys.tool_call_status_disabled_in_conversation,
  .disabledByAgent: LocaleKeys.tool_call_status_disabled_by_agent,
  .notConfigured: LocaleKeys.tool_call_status_not_configured,
  .executionError: LocaleKeys.tool_call_status_execution_error,
};

const _statusFromJson = <String, ToolCallResultStatus>{
  'running': .running,
  'success': .success,
  'skipped_by_user': .skippedByUser,
  'stopped_by_user': .stoppedByUser,
  'tool_not_found': .toolNotFound,
  'disabled_in_workspace': .disabledInWorkspace,
  'disabled_in_conversation': .disabledInConversation,
  'disabled_by_agent': .disabledByAgent,
  'not_configured': .notConfigured,
  'execution_error': .executionError,
};

const _statusToJson = <ToolCallResultStatus, String>{
  .running: 'running',
  .success: 'success',
  .skippedByUser: 'skipped_by_user',
  .stoppedByUser: 'stopped_by_user',
  .toolNotFound: 'tool_not_found',
  .disabledInWorkspace: 'disabled_in_workspace',
  .disabledInConversation: 'disabled_in_conversation',
  .disabledByAgent: 'disabled_by_agent',
  .notConfigured: 'not_configured',
  .executionError: 'execution_error',
};

/// JSON converter for [ToolCallResultStatus].
///
/// Converts the enum to/from snake_case strings for JSON serialization.
class const ToolCallResultStatusConverter()
    implements JsonConverter<ToolCallResultStatus?, String?> {
  @override
  ToolCallResultStatus? fromJson(String? json) {
    if (json == null) return null;

    return _statusFromJson[json];
  }

  @override
  String? toJson(ToolCallResultStatus? object) {
    if (object == null) return null;

    return _statusToJson[object];
  }
}
