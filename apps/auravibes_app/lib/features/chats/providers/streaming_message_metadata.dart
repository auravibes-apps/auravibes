part of 'message_id_list.dart';

abstract final class StreamingMessageMetadata {
  static MessageMetadataEntity? merge(
    MessageMetadataEntity? current,
    MessageMetadataEntity? streaming,
  ) {
    if (streaming == null) return current;

    var toolCalls = streaming.toolCalls;
    if (toolCalls.isEmpty) {
      toolCalls = current?.toolCalls ?? const <MessageToolCallEntity>[];
    }

    return (current ?? const MessageMetadataEntity()).copyWith(
      toolCalls: toolCalls,
      promptTokens: streaming.promptTokens ?? current?.promptTokens,
      completionTokens: streaming.completionTokens ?? current?.completionTokens,
      totalTokens: streaming.totalTokens ?? current?.totalTokens,
      thinking: streaming.thinking ?? current?.thinking,
      modelMetadata: {...?current?.modelMetadata, ...streaming.modelMetadata},
      a2uiMessages: streaming.a2uiMessages.isEmpty
          ? current?.a2uiMessages ?? const <String>[]
          : streaming.a2uiMessages,
      a2uiIssuesBySurface: streaming.a2uiIssuesBySurface.isEmpty
          ? current?.a2uiIssuesBySurface ?? const <String, List<String>>{}
          : streaming.a2uiIssuesBySurface,
      a2uiMessageIssues: streaming.a2uiMessageIssues.isEmpty
          ? current?.a2uiMessageIssues ?? const <String>[]
          : streaming.a2uiMessageIssues,
    );
  }
}
