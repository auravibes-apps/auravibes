import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:riverpod/riverpod.dart';

class LocalChatAttachmentService {
  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String _, {
    required String displayName,
  }) {
    throw UnsupportedError(
      'Local attachment files are unsupported on web. $displayName',
    );
  }

  Future<void> startVoiceRecording() {
    throw UnsupportedError('Voice recording is unsupported on web.');
  }

  Future<MessageAttachmentToCreate?> stopVoiceRecording() async => null;

  Future<void> cancelVoiceRecording() => Future.value();

  Future<void> deleteAttachment(String _) => Future.value();
}

final localChatAttachmentServiceProvider = Provider<LocalChatAttachmentService>(
  (_) => LocalChatAttachmentService(),
);
