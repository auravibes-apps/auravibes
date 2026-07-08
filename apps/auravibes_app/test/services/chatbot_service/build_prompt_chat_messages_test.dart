import 'dart:io';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:auravibes_app/services/chatbot_service/build_prompt_chat_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';

void main() {
  group('BuildPromptChatMessages', () {
    const usecase = BuildPromptChatMessages();

    test(
      'falls back to result status response when raw response is absent',
      () async {
        final messages = [
          MessageEntity(
            id: 'assistant-1',
            conversationId: 'conversation-1',
            content: 'hello',
            messageType: MessageType.text,
            isUser: false,
            status: MessageStatus.sent,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
            metadata: const MessageMetadataEntity(
              toolCalls: [
                MessageToolCallEntity(
                  id: 'tool-1',
                  name: 'missing_tool',
                  argumentsRaw: '{}',
                  resultStatus: ToolCallResultStatus.toolNotFound,
                ),
              ],
            ),
          ),
        ];

        final result = await usecase.call(messages);

        expect(result, hasLength(2));
        final resultMessage = result[1];
        expect(
          resultMessage.parts.whereType<ToolResponsePart>(),
          hasLength(1),
        );
        expect(resultMessage.role.name, 'tool');
        expect(
          resultMessage.parts
              .whereType<ToolResponsePart>()
              .single
              .toolResponse
              .output,
          ToolCallResultStatus.toolNotFound.toResponseString(),
        );
      },
    );

    test(
      'skips oversized attachments and keeps later valid attachments',
      () async {
        final directory = await Directory.systemTemp.createTemp();
        addTearDown(() => directory.delete(recursive: true));
        final smallFile = File('${directory.path}/small.png');
        final _ = await smallFile.writeAsBytes([1, 2, 3]);

        const usecase = BuildPromptChatMessages(modalitiesInput: ['image']);
        final result = await usecase.call([
          MessageEntity(
            id: 'user-1',
            conversationId: 'conversation-1',
            content: '',
            messageType: MessageType.text,
            isUser: true,
            status: MessageStatus.sent,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
            attachments: [
              MessageAttachmentEntity(
                id: 'attachment-1',
                messageId: 'user-1',
                localPath: '${directory.path}/missing.png',
                fileName: 'large.png',
                displayName: 'large.png',
                mimeType: 'image/png',
                modality: MessageAttachmentModality.image,
                sizeBytes: maxChatPromptAttachmentBytes + 1,
                createdAt: DateTime(2025),
                updatedAt: DateTime(2025),
              ),
              MessageAttachmentEntity(
                id: 'attachment-2',
                messageId: 'user-1',
                localPath: smallFile.path,
                fileName: 'small.png',
                displayName: 'small.png',
                mimeType: 'image/png',
                modality: MessageAttachmentModality.image,
                sizeBytes: 3,
                createdAt: DateTime(2025),
                updatedAt: DateTime(2025),
              ),
            ],
          ),
        ]);

        final mediaPart = result.single.parts.whereType<MediaPart>().single;
        expect(mediaPart.media.contentType, 'image/png');
        expect(mediaPart.media.url, startsWith('data:image/png;base64,'));
        expect(mediaPart.metadata, {'filename': 'small.png'});
      },
    );
  });
}
