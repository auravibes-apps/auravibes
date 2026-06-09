// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:riverpod/riverpod.dart';

class StopAllPendingToolCallsUsecase {
  const StopAllPendingToolCallsUsecase({
    required this._messageRepository,
  });

  final MessageRepository _messageRepository;

  Future<void> call({required String messageId}) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();
    var didUpdate = false;
    final updatedToolCalls = metadata.toolCalls.map((toolCall) {
      if (!toolCall.isPending) return toolCall;

      didUpdate = true;

      return toolCall.copyWith(
        resultStatus: ToolCallResultStatus.stoppedByUser,
      );
    }).toList();
    if (!didUpdate) return;

    final _ = await _messageRepository.patchMessage(
      messageId,
      MessagePatch(
        metadata: metadata.copyWith(toolCalls: updatedToolCalls),
      ),
    );
  }
}

final stopAllPendingToolCallsUsecaseProvider =
    Provider<StopAllPendingToolCallsUsecase>((ref) {
      return StopAllPendingToolCallsUsecase(
        messageRepository: ref.watch(messageRepositoryProvider),
      );
    });
