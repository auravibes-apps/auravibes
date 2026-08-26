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
    );
  }
}
