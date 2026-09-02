import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:riverpod/riverpod.dart';

class const LocalChatAttachmentUsecase(
  final LocalChatAttachmentService _service,
) {
  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    required String displayName,
  }) {
    return _service.copyIntoAppStorage(sourcePath, displayName: displayName);
  }

  Future<void> deleteAttachment(String localPath) {
    return _service.deleteAttachment(localPath);
  }

  Future<void> startVoiceRecording() {
    return _service.startVoiceRecording();
  }

  Future<MessageAttachmentToCreate?> stopVoiceRecording() {
    return _service.stopVoiceRecording();
  }

  Future<void> cancelVoiceRecording() {
    return _service.cancelVoiceRecording();
  }
}

final localChatAttachmentUsecaseProvider = Provider<LocalChatAttachmentUsecase>(
  (ref) =>
      LocalChatAttachmentUsecase(ref.watch(localChatAttachmentServiceProvider)),
);
