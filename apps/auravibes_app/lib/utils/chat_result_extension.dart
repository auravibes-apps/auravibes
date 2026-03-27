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

  MessageMetadataEntity? get entityMetadata {
    if (output.toolCalls.isEmpty) {
      return null;
    }

    return MessageMetadataEntity(toolCalls: entityTools);
  }
}
