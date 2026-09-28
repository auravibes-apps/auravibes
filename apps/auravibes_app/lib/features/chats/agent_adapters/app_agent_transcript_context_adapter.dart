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
    final updates = [
      for (final message in transcript)
        if (message.isAgentTranscriptContextUpdate)
          decodeAgentTranscriptContextUpdate(message.content),
    ];
    final previous = foldAgentTranscriptContext(updates);
    final current = AgentTranscriptContextState(
      contextMessages: contextMessages.map(_contextMessage).toList(),
      tools: tools,
      approvalStates: approvalStates,
    );
    final delta = diffAgentTranscriptContext(previous, current);
    final entries = _activeEntries(transcript);
    if (delta != null) {
      final _ = await _messages.createMessage(
        _contextUpdateMessage(conversationId, transcript, delta),
      );
      updates.add(delta);
      entries.add(
        AgentTranscriptContextEntry(
          afterMessageId: _lastVisibleMessageId(transcript),
          update: delta,
        ),
      );
    }
    final effective = foldAgentTranscriptContext(updates);

    return PreparedAgentTranscriptContext(
      contextMessages: effective.contextMessages.map(_chatMessage).toList(),
      tools: effective.tools,
      entries: entries,
    );
  }
}

AgentContextMessage _contextMessage(ChatMessage message) {
  final kind = message.metadata['kind'];
  if (message.parts.isNotEmpty ||
      (message.role != ChatMessageRole.system &&
          (message.role != ChatMessageRole.user ||
              kind != skillContextMetadataKind))) {
    throw const AgentTranscriptContextException('unsupported context message');
  }

  return AgentContextMessage(
    role: message.role == ChatMessageRole.system ? .system : .skill,
    content: message.content,
    kind: kind is String ? kind : null,
  );
}

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
  final now = DateTime.now();
  final latest = transcript.lastOrNull?.createdAt;
  final createdAt = latest != null && !now.isAfter(latest)
      ? latest.add(const Duration(microseconds: 1))
      : now;

  return MessageToCreate(
    conversationId: conversationId,
    content: encodeAgentTranscriptContextUpdate(update),
    messageType: .system,
    isUser: false,
    status: .sent,
    createdAt: createdAt,
    metadata: jsonEncode(
      const MessageMetadataEntity(
        modelMetadata: {agentTranscriptContextMetadataKey: true},
      ).toJson(),
    ),
  );
}

List<AgentTranscriptContextEntry> _activeEntries(
  List<MessageEntity> transcript,
) {
  final summaryIndex = transcript.lastIndexWhere(
    (message) =>
        message.metadata?.isCompactionSummary == true &&
        message.status == .sent,
  );
  final beforeSummary = <AgentTranscriptContextUpdate>[];
  final entries = <AgentTranscriptContextEntry>[];
  String? previousMessageId;
  for (var index = 0; index < transcript.length; index++) {
    final message = transcript[index];
    if (!message.isAgentTranscriptContextUpdate) {
      previousMessageId = message.id;
      continue;
    }
    final update = decodeAgentTranscriptContextUpdate(message.content);
    if (summaryIndex >= 0 && index < summaryIndex) {
      beforeSummary.add(update);
      continue;
    }
    entries.add(
      AgentTranscriptContextEntry(
        afterMessageId: previousMessageId,
        update: update,
      ),
    );
  }
  if (beforeSummary.isNotEmpty) {
    entries.insert(
      0,
      AgentTranscriptContextEntry(
        afterMessageId: null,
        update: snapshotAgentTranscriptContext(
          foldAgentTranscriptContext(beforeSummary),
        ),
      ),
    );
  }

  return entries;
}

String? _lastVisibleMessageId(List<MessageEntity> transcript) {
  for (final message in transcript.reversed) {
    if (!message.isAgentTranscriptContextUpdate) return message.id;
  }

  return null;
}
