// Required: Existing test and UI helpers keep compact return flow.
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_attachment_bytes.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_workspace_chat_context_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show ChatMessage, ChatMessageRole;
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:genkit/genkit.dart';
import 'package:path/path.dart' as p;

typedef _AgentToolCallPromptRequest = ({
  List<MessageToolCallEntity>? toolCalls,
  List<MessageAttachmentEntity> attachments,
  List<String> modalitiesInput,
  bool supportsImageToolResults,
  bool allowPending,
});
typedef _ToolResultMediaBuild = ({
  List<agent.AgentToolResultMedia> media,
  int totalBytes,
});
typedef _ToolResultMediaItem = ({Uint8List? bytes, int totalBytes});
typedef _ToolResultMediaAttachment = ({
  agent.AgentToolResultMedia? media,
  int totalBytes,
});
typedef _ToolResultMediaCallRequest = ({
  String toolCallId,
  List<MessageAttachmentEntity> attachments,
  List<String> modalitiesInput,
  bool supportsImageToolResults,
  int totalBytes,
});

class const BuildPromptChatMessages({
  final List<String> modalitiesInput = const [],
  final bool supportsImageToolResults = false,
}) {
  static const _agentBuilder = agent.BuildPromptChatMessages();

  Future<List<ChatMessage>> call(List<MessageEntity> messages) async {
    return await _buildPromptMessages(
      _agentBuilder,
      modalitiesInput,
      supportsImageToolResults,
      redactWorkspaceToolHistory(messages),
    );
  }
}

Future<List<ChatMessage>> _buildPromptMessages(
  agent.BuildPromptChatMessages agentBuilder,
  List<String> modalitiesInput,
  bool supportsImageToolResults,
  List<MessageEntity> messages,
) async {
  final chatMessages = <ChatMessage>[];
  for (final message in messages) {
    chatMessages.addAll(
      await _buildPromptMessage(
        agentBuilder,
        modalitiesInput,
        supportsImageToolResults,
        message,
      ),
    );
  }

  return chatMessages;
}

Future<List<ChatMessage>> _buildPromptMessage(
  agent.BuildPromptChatMessages agentBuilder,
  List<String> modalitiesInput,
  bool supportsImageToolResults,
  MessageEntity message,
) async {
  final promptMessage = await _toAgentPromptMessage(
    message,
    modalitiesInput,
    supportsImageToolResults,
  );

  return [
    for (final chatMessage in agentBuilder.call([promptMessage]))
      await _withAttachments(
        _toChatMessage(chatMessage).copyWith(
          metadata: {
            ...chatMessage.metadata,
            'transcriptMessageId': message.id,
          },
        ),
        message,
        modalitiesInput,
      ),
  ];
}

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

Future<agent.AgentPromptMessage> _toAgentPromptMessage(
  MessageEntity message,
  List<String> modalitiesInput,
  bool supportsImageToolResults,
) async {
  final metadata = message.metadata;
  final toolCalls = await _toAgentToolCalls((
    toolCalls: metadata?.toolCalls,
    attachments: message.attachments,
    modalitiesInput: modalitiesInput,
    supportsImageToolResults: supportsImageToolResults,
    allowPending: !message.isForkReference,
  ));

  return _agentPromptMessage(message, metadata, toolCalls);
}

agent.AgentPromptMessage _agentPromptMessage(
  MessageEntity message,
  MessageMetadataEntity? metadata,
  List<agent.AgentPromptToolCall> toolCalls,
) {
  return agent.AgentPromptMessage(
    content: _promptContent(message),
    isUser: message.isUser,
    type: _promptMessageType(message),
    isCompactionSummary: metadata?.isCompactionSummary ?? false,
    thinking: metadata?.thinking,
    modelMetadata: metadata?.modelMetadata ?? const {},
    toolCalls: toolCalls,
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

Future<List<agent.AgentPromptToolCall>> _toAgentToolCalls(
  _AgentToolCallPromptRequest request,
) async {
  final result = <agent.AgentPromptToolCall>[];
  final builder = _AgentToolCallBuilder(request);
  for (final toolCall in request.toolCalls ?? const <MessageToolCallEntity>[]) {
    final builtCall = await builder.call(toolCall);
    if (builtCall != null) result.add(builtCall);
  }

  return result;
}

class _AgentToolCallBuilder(final _AgentToolCallPromptRequest request) {
  var _totalBytes = 0;

  Future<agent.AgentPromptToolCall?> call(
    MessageToolCallEntity toolCall,
  ) async {
    if (!request.allowPending && toolCall.isPending) return null;
    final builtCall = await _agentToolCallWithMedia(
      request,
      toolCall,
      _totalBytes,
    );
    _totalBytes = builtCall.totalBytes;

    return builtCall.toolCall;
  }
}

Future<({agent.AgentPromptToolCall toolCall, int totalBytes})>
_agentToolCallWithMedia(
  _AgentToolCallPromptRequest request,
  MessageToolCallEntity toolCall,
  int totalBytes,
) async {
  final builtMedia = await _toolResultMediaForCall((
    toolCallId: toolCall.id,
    attachments: request.attachments,
    modalitiesInput: request.modalitiesInput,
    supportsImageToolResults: request.supportsImageToolResults,
    totalBytes: totalBytes,
  ));

  return (
    toolCall: _agentPromptToolCall(toolCall, builtMedia.media),
    totalBytes: builtMedia.totalBytes,
  );
}

agent.AgentPromptToolCall _agentPromptToolCall(
  MessageToolCallEntity toolCall,
  List<agent.AgentToolResultMedia> media,
) => agent.AgentPromptToolCall(
  id: toolCall.id,
  name: toolCall.name,
  arguments: toolCall.arguments,
  isResolved: toolCall.isResolved,
  response: toolCall.getResponseForAI(),
  media: media,
);

Future<_ToolResultMediaBuild> _toolResultMediaForCall(
  _ToolResultMediaCallRequest request,
) {
  if (!request.supportsImageToolResults ||
      !request.modalitiesInput.contains('image')) {
    return Future.value((
      media: const <agent.AgentToolResultMedia>[],
      totalBytes: request.totalBytes,
    ));
  }

  return _readToolResultMedia(request);
}

Future<_ToolResultMediaBuild> _readToolResultMedia(
  _ToolResultMediaCallRequest request,
) async {
  final media = <agent.AgentToolResultMedia>[];
  var totalBytes = request.totalBytes;
  for (final attachment in request.attachments) {
    final item = await _toolResultMediaForAttachment(
      attachment,
      request,
      totalBytes,
    );
    totalBytes = item.totalBytes;
    if (item.media case final result?) media.add(result);
  }

  return (media: media, totalBytes: totalBytes);
}

Future<_ToolResultMediaAttachment> _toolResultMediaForAttachment(
  MessageAttachmentEntity attachment,
  _ToolResultMediaCallRequest request,
  int totalBytes,
) async {
  if (!_isToolResultImage(attachment, (
    toolCallId: request.toolCallId,
    modalitiesInput: request.modalitiesInput,
  ))) {
    return _unchangedToolResultMedia(totalBytes);
  }
  final item = await _readBoundedToolResultMedia(attachment, totalBytes);
  final bytes = item.bytes;
  if (bytes == null) return _unchangedToolResultMedia(item.totalBytes);

  return _includedToolResultMedia(
    attachment: attachment,
    bytes: bytes,
    totalBytes: item.totalBytes,
  );
}

_ToolResultMediaAttachment _unchangedToolResultMedia(int totalBytes) =>
    (media: null, totalBytes: totalBytes);

_ToolResultMediaAttachment _includedToolResultMedia({
  required MessageAttachmentEntity attachment,
  required Uint8List bytes,
  required int totalBytes,
}) => (
  media: agent.AgentToolResultMedia(
    bytes: bytes,
    mimeType: attachment.mimeType,
    fileName: _safeFileName(attachment.fileName),
  ),
  totalBytes: totalBytes,
);

bool _isToolResultImage(
  MessageAttachmentEntity attachment,
  ({String toolCallId, List<String> modalitiesInput}) request,
) =>
    attachment.toolCallId == request.toolCallId &&
    attachment.modality == MessageAttachmentModality.image &&
    _supportsAttachment(attachment, request.modalitiesInput);

Future<_ToolResultMediaItem> _readBoundedToolResultMedia(
  MessageAttachmentEntity attachment,
  int totalBytes,
) async {
  final bytes = await ChatAttachmentBytes.read(attachment.localPath);
  if (bytes == null ||
      totalBytes + bytes.length >
          ChatAttachmentModality.maxChatPromptAttachmentBytes) {
    return (bytes: null, totalBytes: totalBytes);
  }

  return (
    bytes: Uint8List.fromList(bytes),
    totalBytes: totalBytes + bytes.length,
  );
}

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
    content: [
      for (final media in response.media)
        MediaPart(
          media: .new(
            contentType: media.mimeType,
            url: 'data:${media.mimeType};base64,${base64Encode(media.bytes)}',
          ),
        ).toJson(),
    ],
  );
}
