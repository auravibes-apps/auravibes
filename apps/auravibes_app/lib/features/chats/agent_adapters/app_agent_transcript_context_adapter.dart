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
    final updates = _transcriptContextUpdates(transcript);
    final delta = diffAgentTranscriptContext(
      foldAgentTranscriptContext(updates),
      _currentTranscriptContext(contextMessages, tools, approvalStates),
    );
    final entries = _activeEntries(transcript);
    final entry = await _persistUpdate(
      conversationId: conversationId,
      transcript: transcript,
      update: delta,
    );
    if (entry != null) {
      updates.add(entry.update);
      entries.add(entry);
    }

    return _preparedTranscriptContext(updates, entries);
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

List<AgentTranscriptContextUpdate> _transcriptContextUpdates(
  List<MessageEntity> transcript,
) => [
  for (final message in transcript)
    if (message.isAgentTranscriptContextUpdate)
      AgentTranscriptContextCodec.decodeUpdate(message.content),
];

PreparedAgentTranscriptContext<ChatMessage, ToolSpec>
_preparedTranscriptContext(
  List<AgentTranscriptContextUpdate> updates,
  List<AgentTranscriptContextEntry> entries,
) {
  final effective = foldAgentTranscriptContext(updates);

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
  metadata: message.kind == null ? const {} : {'kind': message.kind},
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
  final summaryIndex = transcript.lastIndexWhere(
    (message) =>
        message.metadata?.isCompactionSummary == true &&
        message.status == .sent,
  );
  final beforeSummary = summaryIndex < 0
      ? <AgentTranscriptContextUpdate>[]
      : _updatesBeforeSummary(transcript, summaryIndex);
  final entries = _entriesAfterSummary(transcript, summaryIndex);

  if (beforeSummary.isEmpty) return entries;

  return [
    AgentTranscriptContextEntry(
      afterMessageId: null,
      update: snapshotAgentTranscriptContext(
        foldAgentTranscriptContext(beforeSummary),
      ),
    ),
    ...entries,
  ];
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
) {
  final entries = <AgentTranscriptContextEntry>[];
  String? previousMessageId;
  for (var index = 0; index < transcript.length; index++) {
    final message = transcript[index];
    if (!message.isAgentTranscriptContextUpdate) {
      previousMessageId = message.id;
    } else if (index >= summaryIndex) {
      entries.add(
        AgentTranscriptContextEntry(
          afterMessageId: previousMessageId,
          update: AgentTranscriptContextCodec.decodeUpdate(message.content),
        ),
      );
    }
  }

  return entries;
}

String? _lastVisibleMessageId(List<MessageEntity> transcript) {
  for (final message in transcript.reversed) {
    if (!message.isAgentTranscriptContextUpdate) return message.id;
  }

  return null;
}
