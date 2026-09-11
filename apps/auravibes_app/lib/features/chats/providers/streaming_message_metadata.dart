part of 'message_id_list.dart';

abstract final class StreamingMessageMetadata {
  static MessageMetadataEntity? merge(
    MessageMetadataEntity? current,
    MessageMetadataEntity? streaming,
  ) {
    if (streaming == null) return current;

    return _mergeMetadata(current ?? const MessageMetadataEntity(), streaming);
  }

  static MessageMetadataEntity _mergeMetadata(
    MessageMetadataEntity current,
    MessageMetadataEntity streaming,
  ) =>
      _mergeContentMetadata(_mergeTokenMetadata(current, streaming), streaming);
}

MessageMetadataEntity _mergeTokenMetadata(
  MessageMetadataEntity current,
  MessageMetadataEntity streaming,
) => current.copyWith(
  promptTokens: _prefer(streaming.promptTokens, current.promptTokens),
  completionTokens: _prefer(
    streaming.completionTokens,
    current.completionTokens,
  ),
  totalTokens: _prefer(streaming.totalTokens, current.totalTokens),
  thinking: _prefer(streaming.thinking, current.thinking),
);

MessageMetadataEntity _mergeContentMetadata(
  MessageMetadataEntity current,
  MessageMetadataEntity streaming,
) => current.copyWith(
  toolCalls: _preferNonEmpty(streaming.toolCalls, current.toolCalls),
  modelMetadata: {...current.modelMetadata, ...streaming.modelMetadata},
  a2uiMessages: _preferNonEmpty(streaming.a2uiMessages, current.a2uiMessages),
  a2uiIssuesBySurface: _preferNonEmptyMap(
    streaming.a2uiIssuesBySurface,
    current.a2uiIssuesBySurface,
  ),
  a2uiMessageIssues: _preferNonEmpty(
    streaming.a2uiMessageIssues,
    current.a2uiMessageIssues,
  ),
);

T? _prefer<T>(T? streaming, T? current) => streaming ?? current;

List<T> _preferNonEmpty<T>(List<T> streaming, List<T> current) =>
    streaming.isEmpty ? current : streaming;

Map<K, V> _preferNonEmptyMap<K, V>(Map<K, V> streaming, Map<K, V> current) =>
    streaming.isEmpty ? current : streaming;
