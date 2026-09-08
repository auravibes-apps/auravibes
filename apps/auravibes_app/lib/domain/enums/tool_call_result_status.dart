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
  String toResponseString() {
    return switch (this) {
      ToolCallResultStatus.running ||
      ToolCallResultStatus.skippedByUser ||
      ToolCallResultStatus.stoppedByUser => agentLifecycle.modelFallback,
      ToolCallResultStatus.success =>
        AgentToolResultStatus.success.modelFallback,
      ToolCallResultStatus.toolNotFound =>
        AgentToolResultStatus.toolNotFound.modelFallback,
      ToolCallResultStatus.disabledInWorkspace =>
        AgentToolResultStatus.disabledInWorkspace.modelFallback,
      ToolCallResultStatus.disabledInConversation =>
        AgentToolResultStatus.disabledInConversation.modelFallback,
      ToolCallResultStatus.disabledByAgent =>
        AgentToolResultStatus.disabledByAgent.modelFallback,
      ToolCallResultStatus.notConfigured =>
        AgentToolResultStatus.notConfigured.modelFallback,
      ToolCallResultStatus.executionError =>
        AgentToolResultStatus.executionError.modelFallback,
    };
  }

  /// Whether this result should halt the AI agent loop entirely.
  ///
  /// When true, no response should be sent to the AI for any tools
  /// in this message.
  bool get stopsAgentLoop => agentLifecycle.stopsAgentLoop;

  AgentToolCallLifecycle get agentLifecycle => switch (this) {
    ToolCallResultStatus.running => AgentToolCallLifecycle.pending,
    ToolCallResultStatus.success => AgentToolCallLifecycle.success,
    ToolCallResultStatus.skippedByUser => AgentToolCallLifecycle.skippedByUser,
    ToolCallResultStatus.stoppedByUser => AgentToolCallLifecycle.stoppedByUser,
    _ => AgentToolCallLifecycle.failed,
  };

  /// Returns the locale key for displaying this status in the UI.
  ///
  /// Use with `.tr()` to get the translated string.
  String get localeKey {
    return switch (this) {
      ToolCallResultStatus.running => LocaleKeys.tool_call_status_running,
      ToolCallResultStatus.success => LocaleKeys.tool_call_status_success,
      ToolCallResultStatus.skippedByUser =>
        LocaleKeys.tool_call_status_skipped_by_user,
      ToolCallResultStatus.stoppedByUser =>
        LocaleKeys.tool_call_status_stopped_by_user,
      ToolCallResultStatus.toolNotFound =>
        LocaleKeys.tool_call_status_tool_not_found,
      ToolCallResultStatus.disabledInWorkspace =>
        LocaleKeys.tool_call_status_disabled_in_workspace,
      ToolCallResultStatus.disabledInConversation =>
        LocaleKeys.tool_call_status_disabled_in_conversation,
      ToolCallResultStatus.disabledByAgent =>
        LocaleKeys.tool_call_status_disabled_by_agent,
      ToolCallResultStatus.notConfigured =>
        LocaleKeys.tool_call_status_not_configured,
      ToolCallResultStatus.executionError =>
        LocaleKeys.tool_call_status_execution_error,
    };
  }
}

/// JSON converter for [ToolCallResultStatus].
///
/// Converts the enum to/from snake_case strings for JSON serialization.
class const ToolCallResultStatusConverter()
    implements JsonConverter<ToolCallResultStatus?, String?> {
  @override
  ToolCallResultStatus? fromJson(String? json) {
    if (json == null) return null;

    return switch (json) {
      'running' => ToolCallResultStatus.running,
      'success' => ToolCallResultStatus.success,
      'skipped_by_user' => ToolCallResultStatus.skippedByUser,
      'stopped_by_user' => ToolCallResultStatus.stoppedByUser,
      'tool_not_found' => ToolCallResultStatus.toolNotFound,
      'disabled_in_workspace' => ToolCallResultStatus.disabledInWorkspace,
      'disabled_in_conversation' => ToolCallResultStatus.disabledInConversation,
      'disabled_by_agent' => ToolCallResultStatus.disabledByAgent,
      'not_configured' => ToolCallResultStatus.notConfigured,
      'execution_error' => ToolCallResultStatus.executionError,
      _ => null,
    };
  }

  @override
  String? toJson(ToolCallResultStatus? object) {
    if (object == null) return null;

    return switch (object) {
      ToolCallResultStatus.running => 'running',
      ToolCallResultStatus.success => 'success',
      ToolCallResultStatus.skippedByUser => 'skipped_by_user',
      ToolCallResultStatus.stoppedByUser => 'stopped_by_user',
      ToolCallResultStatus.toolNotFound => 'tool_not_found',
      ToolCallResultStatus.disabledInWorkspace => 'disabled_in_workspace',
      ToolCallResultStatus.disabledInConversation => 'disabled_in_conversation',
      ToolCallResultStatus.disabledByAgent => 'disabled_by_agent',
      ToolCallResultStatus.notConfigured => 'not_configured',
      ToolCallResultStatus.executionError => 'execution_error',
    };
  }
}
