// Required: Existing test and UI helpers keep compact return flow.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:auravibes_app/services/chatbot_service/chat_attachment_bytes.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:genkit/genkit.dart';
import 'package:path/path.dart' as p;

class BuildPromptChatMessages {
  const BuildPromptChatMessages({this.modalitiesInput = const []});

  final List<String> modalitiesInput;

  static const _agentBuilder = agent.BuildPromptChatMessages();

  Future<List<ChatMessage>> call(List<MessageEntity> messages) async {
    final chatMessages = <ChatMessage>[];
    for (final message in messages) {
      for (final chatMessage in _agentBuilder.call([
        _toAgentPromptMessage(message),
      ])) {
        chatMessages.add(
          await _withAttachments(_toChatMessage(chatMessage), message),
        );
      }
    }

    return chatMessages;
  }

  Future<ChatMessage> _withAttachments(
    ChatMessage message,
    MessageEntity entity,
  ) async {
    if (!entity.isUser || entity.attachments.isEmpty) return message;

    final mediaParts = <MediaPart>[];
    var totalBytes = 0;
    for (final attachment in entity.attachments) {
      if (!_supportsAttachment(attachment)) continue;
      final part = await _toMediaPart(attachment);
      if (part == null) continue;
      final encodedBytes = part.media.url.length;
      if (totalBytes + encodedBytes > maxChatPromptAttachmentBytes) {
        continue;
      }
      totalBytes += encodedBytes;
      mediaParts.add(part);
    }

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

  bool _supportsAttachment(MessageAttachmentEntity attachment) {
    return supportsAttachmentModality(
      attachment.modality,
      modalitiesInput,
      mimeType: attachment.mimeType,
    );
  }

  Future<MediaPart?> _toMediaPart(MessageAttachmentEntity attachment) async {
    final bytes = await readChatAttachmentBytes(attachment.localPath);
    if (bytes == null) return null;

    final dataUrl = 'data:${attachment.mimeType};base64,${base64Encode(bytes)}';

    return MediaPart(
      media: Media(contentType: attachment.mimeType, url: dataUrl),
      metadata: {'filename': _safeFileName(attachment.fileName)},
    );
  }

  String _safeFileName(String fileName) {
    final normalizedFileName = fileName.replaceAll(
      String.fromCharCode(0x5C),
      '/',
    );

    return p
        .basename(normalizedFileName)
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  agent.AgentPromptMessage _toAgentPromptMessage(MessageEntity message) {
    return agent.AgentPromptMessage(
      content: message.content,
      isUser: message.isUser,
      type: message.messageType == MessageType.system
          ? agent.AgentPromptMessageType.system
          : agent.AgentPromptMessageType.text,
      isCompactionSummary: message.metadata?.isCompactionSummary ?? false,
      thinking: message.metadata?.thinking,
      modelMetadata: message.metadata?.modelMetadata ?? const {},
      toolCalls: [
        for (final toolCall
            in message.metadata?.toolCalls ?? const <MessageToolCallEntity>[])
          agent.AgentPromptToolCall(
            id: toolCall.id,
            name: toolCall.name,
            arguments: toolCall.arguments,
            isResolved: toolCall.isResolved,
            response: toolCall.getResponseForAI(),
          ),
      ],
    );
  }

  ChatMessage _toChatMessage(agent.AgentChatMessage message) {
    return ChatMessage(
      role: switch (message.role) {
        agent.AgentChatMessageRole.system => ChatMessageRole.system,
        agent.AgentChatMessageRole.user => ChatMessageRole.user,
        agent.AgentChatMessageRole.model => ChatMessageRole.model,
        agent.AgentChatMessageRole.tool => ChatMessageRole.tool,
      },
      content: message.content,
      parts: message.parts.map(_toPart).toList(),
      metadata: Map<String, Object?>.of(message.metadata),
    );
  }

  Part _toPart(agent.AgentChatPart part) {
    return switch (part.type) {
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
  }

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
}
