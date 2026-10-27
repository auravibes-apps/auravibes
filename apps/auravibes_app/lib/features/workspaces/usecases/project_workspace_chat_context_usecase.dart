import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stored tool output is display history, never an enduring data-access grant.
class const ProjectWorkspaceChatContextUsecase(
  final WorkspaceConversationToolsUsecase tools,
) {
  Future<List<MessageEntity>> call(List<MessageEntity> messages) async {
    final lastUser = messages.lastIndexWhere((message) => message.isUser);

    return [
      for (var i = 0; i < messages.length; i++)
        await _ProjectedMessage(
          this,
          messages[i],
          currentTurn: lastUser >= 0 && i > lastUser,
        ).read(),
    ];
  }

  Future<MessageToolCallEntity> _project(
    String conversationId,
    MessageToolCallEntity call,
    bool currentTurn,
  ) async {
    if (call.isPending) {
      return workspaceToolCallForContext(call, workspaceContextUnavailable);
    }
    if (currentTurn && !(call.resultStatus?.isSuccess() ?? false)) {
      return _currentCall(
        call,
        jsonEncode(workspaceFailureContext(call.responseRaw)),
        preserveTargetIdentifiers: false,
      );
    }
    final arguments = workspaceCommandArgumentsForTool(
      call.name,
      call.arguments,
    );
    final action = workspaceActionForTool(call.name, call.arguments);
    Map<String, Object?>? receipt;
    if (currentTurn && action != 'read' && action != 'listCreated') {
      try {
        receipt = await tools.verifiedMutation(
          conversationId: conversationId,
          operationId: call.id,
          arguments: arguments,
        );
        if (receipt == null) {
          return workspaceToolCallForContext(call, workspaceContextUnavailable);
        }
      } on Object {
        return workspaceToolCallForContext(call, workspaceContextUnavailable);
      }
    }
    final response = action == 'listCreated'
        ? await _listCreated(conversationId, call)
        : await _read(conversationId, call, receipt, arguments);
    if (receipt != null) {
      try {
        if (await tools.verifiedMutation(
              conversationId: conversationId,
              operationId: call.id,
              arguments: arguments,
            ) ==
            null) {
          return workspaceToolCallForContext(call, workspaceContextUnavailable);
        }
      } on Object {
        return workspaceToolCallForContext(call, workspaceContextUnavailable);
      }
    }

    if (currentTurn) {
      return _currentCall(
        call,
        response == workspaceContextUnavailable
            ? response
            : jsonEncode({
                'outcome': 'success',
                'current': jsonDecode(response),
              }),
        preserveTargetIdentifiers: response != workspaceContextUnavailable,
      );
    }

    return workspaceToolCallForContext(call, projectToolOutput(response).text);
  }

  Future<String> _listCreated(
    String conversationId,
    MessageToolCallEntity call,
  ) async {
    try {
      return jsonEncode(
        await tools.call(
          conversationId: conversationId,
          arguments: {
            'action': 'listCreated',
            if (call.arguments['cursor'] case final String cursor)
              'cursor': cursor,
          },
        ),
      );
    } on Object {
      return workspaceContextUnavailable;
    }
  }

  Future<String> _read(
    String conversationId,
    MessageToolCallEntity call,
    Map<String, Object?>? receipt,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final result = await tools.call(
        conversationId: conversationId,
        arguments: workspaceContextReadArguments(
          arguments,
          receipt ?? jsonDecode(call.responseRaw ?? '{}'),
        ),
      );

      return jsonEncode(result);
    } on Object {
      return workspaceContextUnavailable;
    }
  }
}

MessageToolCallEntity _currentCall(
  MessageToolCallEntity call,
  String response, {
  required bool preserveTargetIdentifiers,
}) {
  return call.copyWith(
    argumentsRaw: jsonEncode(
      workspaceToolArgumentsForContext(
        call.name,
        call.arguments,
        preserveAction: true,
        preserveTargetIdentifiers: preserveTargetIdentifiers,
      ),
    ),
    responseRaw: projectToolOutput(response).text,
    responseContextRaw: projectToolOutput(response).text,
    appData: null,
  );
}

class const _ProjectedMessage(
  final ProjectWorkspaceChatContextUsecase projector,
  final MessageEntity message, {
  required final bool currentTurn,
}) {
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
      if (isWorkspaceToolName(call.name))
        await projector._project(message.conversationId, call, currentTurn)
      else
        call,
  ];
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
      if (isWorkspaceToolName(call.name))
        workspaceToolCallForContext(call, workspaceContextUnavailable)
      else
        call,
  ];
}
