import 'dart:convert';

import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const AppAgentTranscriptContextAdapter(
  final MessageRepository _messages,
) {
  Future<PreparedAgentTranscriptContext<ChatMessage, ToolSpec>> reconcile({
    required String conversationId,
    required List<ChatMessage> contextMessages,
    required List<ToolSpec> tools,
    Map<String, String> approvalStates = const {},
  }) async {
    final transcript = await _messages.getTranscriptMessagesByConversation(
      conversationId,
    );
    final current = _currentTranscriptContext(
      contextMessages,
      tools,
      approvalStates,
    );
    final delta = _pendingTranscriptUpdate(transcript, current);
    final entries = _activeEntries(transcript);
    await _appendUpdate(
      conversationId: conversationId,
      transcript: transcript,
      update: delta,
      entries: entries,
    );

    return _preparedTranscriptContext(entries);
  }

  Future<void> _appendUpdate({
    required String conversationId,
    required List<MessageEntity> transcript,
    required AgentTranscriptContextUpdate? update,
    required List<AgentTranscriptContextEntry> entries,
  }) async {
    final entry = await _persistUpdate(
      conversationId: conversationId,
      transcript: transcript,
      update: update,
    );
    if (entry != null) entries.add(entry);
  }

  Future<AgentTranscriptContextEntry?> _persistUpdate({
    required String conversationId,
    required List<MessageEntity> transcript,
    required AgentTranscriptContextUpdate? update,
  }) async {
    if (update == null) return null;
    final _ = await _messages.createMessage(
      _contextUpdateMessage(conversationId, transcript, update),
    );

    return AgentTranscriptContextEntry(
      afterMessageId: _lastVisibleMessageId(transcript),
      update: update,
    );
  }
}

AgentTranscriptContextState _currentTranscriptContext(
  List<ChatMessage> contextMessages,
  List<ToolSpec> tools,
  Map<String, String> approvalStates,
) => AgentTranscriptContextState(
  contextMessages: contextMessages.map(_contextMessage).toList(),
  tools: tools,
  approvalStates: approvalStates,
);

AgentTranscriptContextUpdate? _diffTranscriptContext(
  List<AgentTranscriptContextUpdate> updates,
  AgentTranscriptContextState current,
) => diffAgentTranscriptContext(foldAgentTranscriptContext(updates), current);

AgentTranscriptContextUpdate? _pendingTranscriptUpdate(
  List<MessageEntity> transcript,
  AgentTranscriptContextState current,
) => _diffTranscriptContext(_transcriptContextUpdates(transcript), current);

List<AgentTranscriptContextUpdate> _transcriptContextUpdates(
  List<MessageEntity> transcript,
) => [
  for (final message in transcript)
    if (message.isAgentTranscriptContextUpdate)
      AgentTranscriptContextCodec.decodeUpdate(message.content),
];

PreparedAgentTranscriptContext<ChatMessage, ToolSpec>
_preparedTranscriptContext(List<AgentTranscriptContextEntry> entries) {
  final effective = foldAgentTranscriptContext(
    entries.map((entry) => entry.update),
  );

  return PreparedAgentTranscriptContext(
    contextMessages: effective.contextMessages.map(_chatMessage).toList(),
    tools: effective.tools,
    entries: entries,
  );
}

AgentContextMessage _contextMessage(ChatMessage message) {
  if (message.parts.isNotEmpty || !_hasTrustedContextRole(message)) {
    throw const AgentTranscriptContextException('unsupported context message');
  }
  final kind = message.metadata['kind'];

  return AgentContextMessage(
    role: message.role == ChatMessageRole.system ? .system : .skill,
    content: message.content,
    kind: kind is String ? kind : null,
  );
}

bool _hasTrustedContextRole(ChatMessage message) =>
    message.role == ChatMessageRole.system ||
    (message.role == ChatMessageRole.user &&
        message.metadata['kind'] == skillContextMetadataKind);

ChatMessage _chatMessage(AgentContextMessage message) => ChatMessage(
  role: message.role == AgentContextMessageRole.system ? .system : .user,
  content: message.content,
  metadata: {'transcriptContext': true, 'kind': ?message.kind},
);

MessageToCreate _contextUpdateMessage(
  String conversationId,
  List<MessageEntity> transcript,
  AgentTranscriptContextUpdate update,
) {
  return MessageToCreate(
    conversationId: conversationId,
    content: AgentTranscriptContextCodec.encodeUpdate(update),
    messageType: .system,
    isUser: false,
    status: .sent,
    createdAt: _contextUpdateCreatedAt(transcript),
    metadata: jsonEncode(
      const MessageMetadataEntity(
        modelMetadata: {
          MessageMetadataEntity.agentTranscriptContextMetadataKey: true,
        },
      ).toJson(),
    ),
  );
}

DateTime _contextUpdateCreatedAt(List<MessageEntity> transcript) {
  final now = DateTime.now();
  final latest = transcript.lastOrNull?.createdAt;
  if (latest == null || now.isAfter(latest)) return now;

  return latest.add(const Duration(microseconds: 1));
}

List<AgentTranscriptContextEntry> _activeEntries(
  List<MessageEntity> transcript,
) {
  final summaryIndex = _lastSummaryIndex(transcript);
  final entries = _entriesAfterSummary(transcript, summaryIndex);
  final snapshot = _snapshotBeforeSummary(transcript, summaryIndex);
  if (snapshot == null) return entries;

  return [snapshot, ...entries];
}

int _lastSummaryIndex(List<MessageEntity> transcript) =>
    transcript.lastIndexWhere(
      (message) =>
          message.metadata?.isCompactionSummary == true &&
          message.status == .sent,
    );

AgentTranscriptContextEntry? _snapshotBeforeSummary(
  List<MessageEntity> transcript,
  int summaryIndex,
) {
  if (summaryIndex < 0) return null;
  final updates = _updatesBeforeSummary(transcript, summaryIndex);
  if (updates.isEmpty) return null;

  return AgentTranscriptContextEntry(
    afterMessageId: null,
    update: snapshotAgentTranscriptContext(foldAgentTranscriptContext(updates)),
  );
}

List<AgentTranscriptContextUpdate> _updatesBeforeSummary(
  List<MessageEntity> transcript,
  int summaryIndex,
) => [
  for (var index = 0; index < summaryIndex; index++)
    if (transcript[index].isAgentTranscriptContextUpdate)
      AgentTranscriptContextCodec.decodeUpdate(transcript[index].content),
];

List<AgentTranscriptContextEntry> _entriesAfterSummary(
  List<MessageEntity> transcript,
  int summaryIndex,
) => _iterEntriesAfterSummary(transcript, summaryIndex).toList();

Iterable<AgentTranscriptContextEntry> _iterEntriesAfterSummary(
  List<MessageEntity> transcript,
  int summaryIndex,
) sync* {
  String? previousMessageId;
  for (var index = 0; index < transcript.length; index++) {
    final progress = _transcriptEntryProgress(
      transcript[index],
      index,
      summaryIndex,
      previousMessageId,
    );
    previousMessageId = progress.previousMessageId;
    final entry = progress.entry;
    if (entry == null) continue;
    yield entry;
  }
}

typedef _TranscriptEntryProgress = ({
  AgentTranscriptContextEntry? entry,
  String? previousMessageId,
});

_TranscriptEntryProgress _transcriptEntryProgress(
  MessageEntity message,
  int index,
  int summaryIndex,
  String? previousMessageId,
) {
  if (!message.isAgentTranscriptContextUpdate) {
    return (entry: null, previousMessageId: message.id);
  }
  if (index < summaryIndex) {
    return (entry: null, previousMessageId: previousMessageId);
  }

  return (
    entry: _transcriptContextEntry(message, previousMessageId),
    previousMessageId: previousMessageId,
  );
}

AgentTranscriptContextEntry _transcriptContextEntry(
  MessageEntity message,
  String? previousMessageId,
) => AgentTranscriptContextEntry(
  afterMessageId: previousMessageId,
  update: AgentTranscriptContextCodec.decodeUpdate(message.content),
);

String? _lastVisibleMessageId(List<MessageEntity> transcript) {
  for (final message in transcript.reversed) {
    if (!message.isAgentTranscriptContextUpdate) return message.id;
  }

  return null;
}
