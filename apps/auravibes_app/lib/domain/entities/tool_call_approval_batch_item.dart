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
});
