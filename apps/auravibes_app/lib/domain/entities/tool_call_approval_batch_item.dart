import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';

class const ToolCallApprovalBatchItem({
  required final String conversationId,
  required final String messageId,
  required final String toolCallId,
  required final String? argumentsDigest,
  required final int? turnRevision,
});

enum ToolCallApprovalBatchClaimStatus { claimed, alreadyHandled, conflicted }

typedef ToolCallExecutionIdentity = ({
  String conversationId,
  String messageId,
  String toolCallId,
});

typedef ToolCallExecutionOutput = ({
  String? responseRaw,
  String? responseContextRaw,
  bool outputTruncated,
  int? originalResponseBytes,
  bool fullOutputForContext,
});

class const ToolCallApprovalBatchClaim({
  required final ToolCallApprovalBatchItem item,
  required final ToolCallApprovalBatchClaimStatus status,
  final MessageToolCallEntity? toolCall,
});

class const ToolCallExecutionBatchUpdate({
  required final String conversationId,
  required final String messageId,
  required final String toolCallId,
  required final ToolCallResultStatus resultStatus,
  final String? responseRaw,
  final String? responseContextRaw,
  final bool outputTruncated = false,
  final int? originalResponseBytes,
  final bool fullOutputForContext = false,
}) {
  // ignore: unnecessary_type_name_in_constructor, named factory alongside primary constructor.
  factory ToolCallExecutionBatchUpdate.fromParts({
    required ToolCallExecutionIdentity identity,
    required ToolCallResultStatus resultStatus,
    required ToolCallExecutionOutput output,
  }) => .new(
    conversationId: identity.conversationId,
    messageId: identity.messageId,
    toolCallId: identity.toolCallId,
    resultStatus: resultStatus,
    responseRaw: output.responseRaw,
    responseContextRaw: output.responseContextRaw,
    outputTruncated: output.outputTruncated,
    originalResponseBytes: output.originalResponseBytes,
    fullOutputForContext: output.fullOutputForContext,
  );

  MessageToolCallEntity applyTo(MessageToolCallEntity toolCall) =>
      toolCall.copyWith(
        resultStatus: resultStatus,
        responseRaw: responseRaw,
        responseContextRaw: responseContextRaw,
        outputTruncated: outputTruncated,
        originalResponseBytes: originalResponseBytes,
        fullOutputForContext: fullOutputForContext,
      );
}
