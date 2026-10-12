import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

const compactionUserConstraint =
    'CONSTRAINT: compaction tests must stay offline and use no provider.';
const compactionPriorDecision =
    'DECISION: retain the local schema migration plan.';
const compactionPendingTask =
    'PENDING: verify the migration retains all forked parent context.';
const compactionForkBoundary =
    'FORK BOUNDARY: inherited parent history ends at this decision.';
const compactionAfterForkBoundary =
    'OUTSIDE FORK: this later parent message must not enter the child.';
const compactionToolResult = 'TOOL RESULT: schema version is 3.';

final class CompactionContextFixture {
  final String forkThroughMessageId = 'parent-05-fork-boundary';
  final MessageEntity parentMessageAfterForkBoundary = _message(
    id: 'parent-06-after-boundary',
    content: compactionAfterForkBoundary,
    isUser: true,
  );

  // A fork's effective transcript contains only inherited rows through
  // forkThroughMessageId, followed by messages owned by the child.
  final List<MessageEntity> messages = .unmodifiable([
    _message(
      id: 'parent-01-constraint',
      content: compactionUserConstraint,
      isUser: true,
      isForkReference: true,
    ),
    _message(
      id: 'parent-02-decision',
      content: compactionPriorDecision,
      isUser: false,
      isForkReference: true,
    ),
    _message(
      id: 'parent-03-tool-exchange',
      content: '',
      isUser: false,
      isForkReference: true,
      metadata: const MessageMetadataEntity(
        toolCalls: [
          MessageToolCallEntity(
            id: 'schema-lookup-1',
            name: 'schema_lookup',
            argumentsRaw: '{"schema":"local"}',
            responseRaw: compactionToolResult,
            resultStatus: .success,
          ),
        ],
      ),
    ),
    _message(
      id: 'parent-04-pending-task',
      content: compactionPendingTask,
      isUser: true,
      isForkReference: true,
    ),
    _message(
      id: 'parent-05-fork-boundary',
      content: compactionForkBoundary,
      isUser: false,
      isForkReference: true,
    ),
    _message(
      id: 'child-01-continuation',
      content:
          'FORK CHILD: use inherited context without reading later parent '
          'messages.',
      isUser: true,
    ),
    _message(
      id: 'child-02-decision',
      content: 'CHILD DECISION: continue with the existing local fixture.',
      isUser: false,
    ),
    _message(
      id: 'child-03-current-request',
      content:
          'CURRENT REQUEST: prepare a summary and retain pending work without '
          'crossing the fork boundary.',
      isUser: true,
    ),
    _message(
      id: 'child-04-latest-response',
      content: 'The next step is the offline migration audit.',
      isUser: false,
    ),
  ]);
}

MessageEntity _message({
  required String id,
  required String content,
  required bool isUser,
  bool isForkReference = false,
  MessageMetadataEntity? metadata,
}) => MessageEntity(
  id: id,
  conversationId: 'fork-conv',
  content: content,
  messageType: .text,
  isUser: isUser,
  status: .sent,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  metadata: metadata,
  isForkReference: isForkReference,
);
