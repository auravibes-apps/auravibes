import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stored tool output is display history, never an enduring data-access grant.
class const ProjectWorkspaceChatContextUsecase(
  final WorkspaceConversationToolsUsecase tools,
) {
  Future<List<MessageEntity>> call(List<MessageEntity> messages) async => [
    for (final message in messages)
      await _ProjectedMessage(this, message).read(),
  ];

  Future<MessageToolCallEntity> _project(
    String conversationId,
    MessageToolCallEntity call,
  ) async {
    if (call.isPending) {
      return workspaceToolCallForContext(call, workspaceContextUnavailable);
    }
    final response = await _read(conversationId, call);

    return workspaceToolCallForContext(call, projectToolOutput(response).text);
  }

  Future<String> _read(
    String conversationId,
    MessageToolCallEntity call,
  ) async {
    try {
      final result = await tools.call(
        conversationId: conversationId,
        arguments: _WorkspaceToolContext.arguments(call),
      );

      return jsonEncode(result);
    } on Object {
      return workspaceContextUnavailable;
    }
  }
}

class const _ProjectedMessage(
  final ProjectWorkspaceChatContextUsecase projector,
  final MessageEntity message,
) {
  Future<MessageEntity> read() async {
    final metadata = message.metadata;
    if (metadata == null) return message;
    final calls = await _calls(metadata.toolCalls);

    return message.copyWith(metadata: metadata.copyWith(toolCalls: calls));
  }

  Future<List<MessageToolCallEntity>> _calls(
    List<MessageToolCallEntity> calls,
  ) async => [
    for (final call in calls)
      if (call.name == workspaceCommandToolName)
        await projector._project(message.conversationId, call)
      else
        call,
  ];
}

abstract final class _WorkspaceToolContext {
  static Map<String, dynamic> arguments(MessageToolCallEntity call) =>
      workspaceContextReadArguments(
        jsonDecode(call.argumentsRaw) as Map<String, dynamic>,
        jsonDecode(call.responseRaw ?? '{}'),
      );
}

MessageToolCallEntity workspaceToolCallForContext(
  MessageToolCallEntity call,
  String response,
) => call.isPending
    ? call.copyWith(argumentsRaw: '{"action":"read"}', appData: null)
    : call.copyWith(
        argumentsRaw: '{"action":"read"}',
        responseRaw: response,
        responseContextRaw: response,
        appData: null,
      );

List<MessageEntity> redactWorkspaceToolHistory(List<MessageEntity> messages) =>
    _WorkspaceHistoryRedaction.all(messages);

abstract final class _WorkspaceHistoryRedaction {
  static List<MessageEntity> all(List<MessageEntity> messages) => [
    for (final message in messages) _message(message),
  ];

  static MessageEntity _message(MessageEntity message) {
    final metadata = message.metadata;
    if (metadata == null) return message;

    return message.copyWith(
      metadata: metadata.copyWith(toolCalls: _calls(metadata.toolCalls)),
    );
  }

  static List<MessageToolCallEntity> _calls(
    List<MessageToolCallEntity> calls,
  ) => [
    for (final call in calls)
      if (call.name == workspaceCommandToolName)
        workspaceToolCallForContext(call, workspaceContextUnavailable)
      else
        call,
  ];
}
