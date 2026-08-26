import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

class ChatDraft {
  const ChatDraft({required this.text, this.attachments = const []});

  final String text;
  final List<MessageAttachmentToCreate> attachments;

  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;
}
