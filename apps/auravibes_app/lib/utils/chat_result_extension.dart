import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:langchain/langchain.dart';

extension ChatResultEntities on ChatResult {
  List<MessageToolCallEntity> get entityTools {
    if (output.toolCalls.isEmpty) {
      return [];
    }

    return output.toolCalls.map((e) {
      return MessageToolCallEntity(
        argumentsRaw: e.argumentsRaw,
        id: e.id,
        name: e.name,
      );
    }).toList();
  }

  int get entityPromptTokens => usage.promptTokens ?? 0;

  int get entityCompletionTokens => usage.responseTokens ?? 0;

  int get entityTotalTokens {
    return usage.totalTokens ?? (entityPromptTokens + entityCompletionTokens);
  }

  MessageMetadataEntity? get entityMetadata {
    final hasUsage =
        usage.promptTokens != null ||
        usage.responseTokens != null ||
        usage.totalTokens != null;

    if (output.toolCalls.isEmpty && !hasUsage) {
      return null;
    }

    return MessageMetadataEntity(
      toolCalls: entityTools,
      promptTokens: usage.promptTokens,
      completionTokens: usage.responseTokens,
      totalTokens: usage.totalTokens,
    );
  }
}
