import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

class const ChatDraft({
  required final String text,
  final List<MessageAttachmentToCreate> attachments = const [],
}) {
  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;
}
