import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Stored tool output is display history, never an enduring data-access grant.
class const ProjectWorkspaceChatContextUsecase(
  final WorkspaceConversationToolsUsecase tools,
) {
  Future<List<MessageEntity>> call(List<MessageEntity> messages) async {
    final result = <MessageEntity>[];
    for (final message in messages) {
      final metadata = message.metadata;
      if (metadata == null) {
        result.add(message);
        continue;
      }
      final calls = <MessageToolCallEntity>[];
      for (final call in metadata.toolCalls) {
        calls.add(
          call.name == workspaceCommandToolName
              ? await _project(message.conversationId, call)
              : call,
        );
      }
      result.add(
        message.copyWith(metadata: metadata.copyWith(toolCalls: calls)),
      );
    }
    return result;
  }

  Future<MessageToolCallEntity> _project(
    String conversationId,
    MessageToolCallEntity call,
  ) async {
    if (call.isPending) {
      return call.copyWith(argumentsRaw: '{"action":"read"}', appData: null);
    }
    var response = workspaceContextUnavailable;
    try {
      final input = jsonDecode(call.argumentsRaw) as Map<String, dynamic>;
      final output = jsonDecode(call.responseRaw ?? '{}');
      final read = workspaceContextReadArguments(input, output);
      response = jsonEncode(
        await tools.call(conversationId: conversationId, arguments: read),
      );
    } on Object {
      // Missing, revoked, deleted, stale, or unavailable scope stays out of prompts.
    }
    return workspaceToolCallForContext(call, projectToolOutput(response).text);
  }
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
    [
      for (final message in messages)
        message.metadata == null
            ? message
            : message.copyWith(
                metadata: message.metadata!.copyWith(
                  toolCalls: [
                    for (final call in message.metadata!.toolCalls)
                      call.name == workspaceCommandToolName
                          ? workspaceToolCallForContext(
                              call,
                              workspaceContextUnavailable,
                            )
                          : call,
                  ],
                ),
              ),
    ];
