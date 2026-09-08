import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

class const ChatDraft({
  required final String text,
  final List<MessageAttachmentToCreate> attachments = const [],
  final String? metadataJson,
}) {
  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;

  MessageToCreate toMessage(String conversationId) => .new(
    conversationId: conversationId,
    content: text,
    messageType: .text,
    isUser: true,
    status: .sending,
    metadata: metadataJson,
    attachments: attachments,
  );
}
