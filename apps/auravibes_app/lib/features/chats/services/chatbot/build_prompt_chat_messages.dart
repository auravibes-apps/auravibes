// Required: Existing test and UI helpers keep compact return flow.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_attachment_bytes.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show ChatMessage, ChatMessageRole;
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:genkit/genkit.dart';
import 'package:path/path.dart' as p;

class const BuildPromptChatMessages({
  final List<String> modalitiesInput = const [],
}) {
  static const _agentBuilder = agent.BuildPromptChatMessages();

  Future<List<ChatMessage>> call(List<MessageEntity> messages) =>
      _buildPromptMessages(_agentBuilder, modalitiesInput, messages);
}

Future<List<ChatMessage>> _buildPromptMessages(
  agent.BuildPromptChatMessages agentBuilder,
  List<String> modalitiesInput,
  List<MessageEntity> messages,
) async {
  final chatMessages = <ChatMessage>[];
  for (final message in messages) {
    chatMessages.addAll(
      await _buildPromptMessage(agentBuilder, modalitiesInput, message),
    );
  }

  return chatMessages;
}

Future<List<ChatMessage>> _buildPromptMessage(
  agent.BuildPromptChatMessages agentBuilder,
  List<String> modalitiesInput,
  MessageEntity message,
) async => [
  for (final chatMessage in agentBuilder.call([_toAgentPromptMessage(message)]))
    await _withAttachments(
      _toChatMessage(chatMessage),
      message,
      modalitiesInput,
    ),
];

Future<ChatMessage> _withAttachments(
  ChatMessage message,
  MessageEntity entity,
  List<String> modalitiesInput,
) async {
  if (!entity.isUser || entity.attachments.isEmpty) return message;

  final mediaParts = await _attachmentMediaParts(
    entity.attachments,
    modalitiesInput,
  );

  return ChatMessage(
    role: message.role,
    parts: [
      if (message.content.isNotEmpty) TextPart(text: message.content),
      ...message.parts,
      ...mediaParts,
    ],
    metadata: message.metadata,
  );
}

Future<List<MediaPart>> _attachmentMediaParts(
  List<MessageAttachmentEntity> attachments,
  List<String> modalitiesInput,
) async {
  final mediaParts = <MediaPart>[];
  var totalBytes = 0;
  for (final attachment in attachments) {
    final part = await _supportedMediaPart(attachment, modalitiesInput);
    if (part == null || _exceedsAttachmentLimit(part, totalBytes)) continue;
    totalBytes += part.media.url.length;
    mediaParts.add(part);
  }

  return mediaParts;
}

Future<MediaPart?> _supportedMediaPart(
  MessageAttachmentEntity attachment,
  List<String> modalitiesInput,
) {
  if (!_supportsAttachment(attachment, modalitiesInput)) {
    return Future<MediaPart?>.value();
  }

  return _toMediaPart(attachment);
}

bool _exceedsAttachmentLimit(MediaPart part, int totalBytes) =>
    totalBytes + part.media.url.length >
    ChatAttachmentModality.maxChatPromptAttachmentBytes;

bool _supportsAttachment(
  MessageAttachmentEntity attachment,
  List<String> modalitiesInput,
) => ChatAttachmentModality.supports(
  attachment.modality,
  modalitiesInput,
  mimeType: attachment.mimeType,
);

Future<MediaPart?> _toMediaPart(MessageAttachmentEntity attachment) async {
  final bytes = await ChatAttachmentBytes.read(attachment.localPath);
  if (bytes == null) return null;

  final dataUrl = 'data:${attachment.mimeType};base64,${base64Encode(bytes)}';

  return MediaPart(
    media: .new(contentType: attachment.mimeType, url: dataUrl),
    metadata: {'filename': _safeFileName(attachment.fileName)},
  );
}

String _safeFileName(String fileName) => p
    .basename(fileName.replaceAll(String.fromCharCode(0x5C), '/'))
    .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

agent.AgentPromptMessage _toAgentPromptMessage(MessageEntity message) {
  final metadata = message.metadata;

  return agent.AgentPromptMessage(
    content: _promptContent(message),
    isUser: message.isUser,
    type: _promptMessageType(message),
    isCompactionSummary: metadata?.isCompactionSummary ?? false,
    thinking: metadata?.thinking,
    modelMetadata: metadata?.modelMetadata ?? const {},
    toolCalls: _toAgentToolCalls(metadata?.toolCalls),
  );
}

agent.AgentPromptMessageType _promptMessageType(MessageEntity message) =>
    message.messageType == MessageType.system
    ? agent.AgentPromptMessageType.system
    : agent.AgentPromptMessageType.text;

String _promptContent(MessageEntity message) {
  final metadata = message.metadata;
  final action = agent.A2uiChatContract.decodeActionMetadata(
    metadata?.modelMetadata,
    conversationId: message.conversationId,
  );
  final content = agent.A2uiChatContract.appendAnswersToPrompt(
    message.content,
    action,
  );

  return message.isUser ? content : _appendA2uiSurfaces(content, metadata);
}

String _appendA2uiSurfaces(String content, MessageMetadataEntity? metadata) =>
    agent.appendA2uiSurfacesToPrompt(content, {
      'a2uiMessages': metadata?.a2uiMessages ?? const <String>[],
    });

List<agent.AgentPromptToolCall> _toAgentToolCalls(
  List<MessageToolCallEntity>? toolCalls,
) => [
  for (final toolCall in toolCalls ?? const <MessageToolCallEntity>[])
    agent.AgentPromptToolCall(
      id: toolCall.id,
      name: toolCall.name,
      arguments: toolCall.arguments,
      isResolved: toolCall.isResolved,
      response: toolCall.getResponseForAI(),
    ),
];

ChatMessage _toChatMessage(agent.AgentChatMessage message) => ChatMessage(
  role: _chatMessageRole(message),
  content: message.content,
  parts: message.parts.map(_toPart).toList(),
  metadata: Map<String, Object?>.of(message.metadata),
);

ChatMessageRole _chatMessageRole(agent.AgentChatMessage message) =>
    switch (message.role) {
      agent.AgentChatMessageRole.system => ChatMessageRole.system,
      agent.AgentChatMessageRole.user => ChatMessageRole.user,
      agent.AgentChatMessageRole.model => ChatMessageRole.model,
      agent.AgentChatMessageRole.tool => ChatMessageRole.tool,
    };

Part _toPart(agent.AgentChatPart part) => switch (part.type) {
  agent.AgentChatPartType.text => TextPart(text: part.text ?? ''),
  agent.AgentChatPartType.reasoning => ReasoningPart(
    reasoning: part.reasoning ?? '',
  ),
  agent.AgentChatPartType.toolRequest => ToolRequestPart(
    toolRequest: _toToolRequest(part),
  ),
  agent.AgentChatPartType.toolResponse => ToolResponsePart(
    toolResponse: _toToolResponse(part),
  ),
};

ToolRequest _toToolRequest(agent.AgentChatPart part) {
  final request = part.toolRequest;
  if (request == null) {
    throw StateError('Tool request part is missing request payload.');
  }

  return ToolRequest(
    ref: request.ref,
    name: request.name,
    input: request.input,
  );
}

ToolResponse _toToolResponse(agent.AgentChatPart part) {
  final response = part.toolResponse;
  if (response == null) {
    throw StateError('Tool response part is missing response payload.');
  }

  return ToolResponse(
    ref: response.ref,
    name: response.name,
    output: response.output,
  );
}
