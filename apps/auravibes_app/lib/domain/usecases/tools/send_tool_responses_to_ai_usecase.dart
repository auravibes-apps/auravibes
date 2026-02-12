// lib/domain/usecases/tools/send_tool_responses_to_ai_usecase.dart
import 'package:auravibes_app/domain/entities/messages.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/domain/repositories/message_repository.dart';
import 'package:auravibes_app/providers/messages_manager_provider.dart';
import 'package:auravibes_app/providers/tool_execution_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Use case for sending tool responses to AI.
///
/// This is a simple class with constructor injection - no Riverpod.
class SendToolResponsesToAIUseCase {
  const SendToolResponsesToAIUseCase(
    this._messageRepository,
    this._ref,
  );

  final MessageRepository _messageRepository;
  final Ref _ref;

  /// Sends all resolved tool responses to AI for continuation
  Future<void> call({required String messageId}) async {
    final message = await _messageRepository.getMessageById(messageId);
    if (message == null) return;

    final metadata = message.metadata ?? const MessageMetadataEntity();

    // Check if any tool stopped the agent loop
    final shouldStop = metadata.toolCalls.any(
      (t) => t.resultStatus?.stopsAgentLoop ?? false,
    );
    if (shouldStop) {
      return;
    }

    // Build responses using getResponseForAI() which uses
    // responseRaw if available, otherwise resultStatus.toResponseString()
    final allResponses = metadata.toolCalls
        .where((t) => t.isResolved)
        .map((t) => ToolResponseItem(id: t.id, content: t.getResponseForAI()))
        .toList();

    _sendResponsesToAI(allResponses, messageId);
  }

  void _sendResponsesToAI(List<ToolResponseItem> responses, String messageId) {
    _ref
        .read(messagesManagerProvider.notifier)
        .sendToolsResponse(responses, messageId);
  }
}
