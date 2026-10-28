import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Redacts stored workspace results; it never re-reads workspace data.
class const ProjectWorkspaceChatContextUsecase(
  WorkspaceConversationToolsUsecase _,
) {
  Future<List<MessageEntity>> call(List<MessageEntity> messages) async =>
      redactWorkspaceToolHistory(messages);
}

MessageToolCallEntity workspaceToolCallForContext(
  MessageToolCallEntity call,
  String response,
) => call.isPending
    ? call.copyWith(
        argumentsRaw: jsonEncode(
          workspaceToolArgumentsForContext(call.name, call.arguments),
        ),
        appData: null,
      )
    : call.copyWith(
        argumentsRaw: jsonEncode(
          workspaceToolArgumentsForContext(call.name, call.arguments),
        ),
        responseRaw: response,
        responseContextRaw: response,
        appData: null,
      );

List<MessageEntity> redactWorkspaceToolHistory(List<MessageEntity> messages) =>
    _WorkspaceHistoryRedaction.all(messages);

abstract final class _WorkspaceHistoryRedaction {
  static List<MessageEntity> all(List<MessageEntity> messages) {
    final lastUser = messages.lastIndexWhere((message) => message.isUser);

    return [
      for (var index = 0; index < messages.length; index++)
        _message(
          messages[index],
          currentTurn:
              lastUser >= 0 &&
              index > lastUser &&
              !messages[index].isForkReference,
        ),
    ];
  }

  static MessageEntity _message(
    MessageEntity message, {
    required bool currentTurn,
  }) {
    final metadata = message.metadata;
    if (metadata == null) return message;

    return message.copyWith(
      metadata: metadata.copyWith(
        toolCalls: _calls(metadata.toolCalls, currentTurn: currentTurn),
      ),
    );
  }

  static List<MessageToolCallEntity> _calls(
    List<MessageToolCallEntity> calls, {
    required bool currentTurn,
  }) => [
    for (final call in calls)
      if (isWorkspaceToolName(call.name) && currentTurn)
        _currentCall(call)
      else if (isWorkspaceToolName(call.name))
        workspaceToolCallForContext(call, workspaceContextUnavailable)
      else
        call,
  ];
}

MessageToolCallEntity _currentCall(MessageToolCallEntity call) {
  if (call.isPending) return workspaceToolCallForContext(call, '');
  final response = call.resultStatus?.isSuccess() ?? false
      ? call.responseContextRaw ?? call.responseRaw ?? '{}'
      : jsonEncode(
          workspaceFailureContext(call.responseContextRaw ?? call.responseRaw),
        );

  return call.copyWith(
    argumentsRaw: jsonEncode(
      workspaceToolArgumentsForContext(
        call.name,
        call.arguments,
        preserveAction: true,
        preserveTargetIdentifiers: true,
      ),
    ),
    responseRaw: projectToolOutput(response).text,
    responseContextRaw: projectToolOutput(response).text,
    appData: null,
  );
}
