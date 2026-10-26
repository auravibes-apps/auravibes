// ignore_for_file: type=lint, type=warning
import 'dart:io';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/services/chatbot/build_prompt_chat_messages.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as engine;
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';

void main() {
  group('BuildPromptChatMessages', () {
    const usecase = BuildPromptChatMessages();

    test('default prompt and compaction omit archived workspace payloads', () async {
      final result = await usecase.call([
        MessageEntity(
          id: 'assistant-workspace',
          conversationId: 'conversation-1',
          content: '',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'workspace-read',
                name: engine.workspaceCommandToolName,
                argumentsRaw:
                    '{"action":"updateRecord","values":{"secret":"old-input"}}',
                responseRaw: '{"secret":"old-response"}',
                responseContextRaw: '{"secret":"old-context"}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
        ),
      ]);
      final output = result
          .expand((message) => message.parts)
          .whereType<ToolResponsePart>()
          .single
          .toolResponse
          .output;
      expect(output, engine.workspaceContextUnavailable);
      expect(result.toString(), isNot(contains('old-input')));
      expect(result.toString(), isNot(contains('old-response')));
      expect(result.toString(), isNot(contains('old-context')));
    });

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
        expect(resultMessage.parts.whereType<ToolResponsePart>(), hasLength(1));
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
                sizeBytes:
                    ChatAttachmentModality.maxChatPromptAttachmentBytes + 1,
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

    test(
      'reconstructs tool screenshot media only when provider supports it',
      () async {
        final directory = await Directory.systemTemp.createTemp();
        addTearDown(() => directory.delete(recursive: true));
        final screenshot = File('${directory.path}/capture.png');
        final _ = await screenshot.writeAsBytes([1, 2, 3]);
        final message = MessageEntity(
          id: 'assistant-1',
          conversationId: 'conversation-1',
          content: 'Checking the page.',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-1',
                name: 'browser_capture_screenshot',
                argumentsRaw: '{}',
                responseRaw: '{"snapshot":"Bounded DOM fallback"}',
                resultStatus: ToolCallResultStatus.success,
              ),
            ],
          ),
          attachments: [
            MessageAttachmentEntity(
              id: 'attachment-1',
              messageId: 'assistant-1',
              toolCallId: 'tool-1',
              localPath: screenshot.path,
              fileName: 'capture.png',
              displayName: 'capture.png',
              mimeType: 'image/png',
              modality: MessageAttachmentModality.image,
              sizeBytes: 3,
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
          ],
        );

        final imageCapable = await const BuildPromptChatMessages(
          modalitiesInput: ['image'],
          supportsImageToolResults: true,
        ).call([message]);
        final fallback = await const BuildPromptChatMessages(
          modalitiesInput: ['image'],
        ).call([message]);
        final imageResponse = imageCapable[1].parts
            .whereType<ToolResponsePart>()
            .single
            .toolResponse;
        final fallbackResponse = fallback[1].parts
            .whereType<ToolResponsePart>()
            .single
            .toolResponse;

        expect(imageResponse.output, contains('Bounded DOM fallback'));
        expect(imageResponse.content, hasLength(1));
        expect(
          MediaPart.fromJson(
            Map<String, dynamic>.from(imageResponse.content!.single as Map),
          ).media.url,
          'data:image/png;base64,AQID',
        );
        expect(fallbackResponse.output, contains('Bounded DOM fallback'));
        expect(fallbackResponse.content, isEmpty);
      },
    );

    test(
      'adds form answers to provider content without changing chat text',
      () async {
        const content = 'Answers received.';
        const action = engine.A2uiChatAction(
          protocolVersion: engine.a2uiChatProtocolVersion,
          conversationId: 'conversation-1',
          turnId: 'assistant-1',
          surfaceId: 'assistant-1:main',
          wireSurfaceId: 'main',
          componentId: engine.a2uiChatFormSubmitComponentId,
          actionName: engine.a2uiChatFormSubmitActionName,
          context: {},
          messageText: 'Form answers submitted',
          answers: {'name': 'Ada', 'amount': 42},
        );
        final entity = MessageEntity(
          id: 'user-1',
          conversationId: 'conversation-1',
          content: content,
          messageType: MessageType.text,
          isUser: true,
          status: MessageStatus.sent,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          metadata: MessageMetadataEntity(
            modelMetadata: {engine.a2uiChatActionMetadataKey: action.toJson()},
          ),
        );

        final result = await usecase.call([entity]);

        expect(entity.content, content);
        expect(result.single.content, contains('Form submission context:'));
        expect(result.single.content, contains('{"name":"Ada","amount":42}'));
      },
    );

    test('keeps a UI-only assistant message in provider history', () async {
      final payload = engine.A2uiChatContract.encodeEnvelope({
        'version': engine.a2uiChatWireVersion,
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': engine.a2uiChatCatalogId,
        },
      });
      final entity = MessageEntity(
        id: 'assistant-1',
        conversationId: 'conversation-1',
        content: '',
        messageType: MessageType.text,
        isUser: false,
        status: MessageStatus.sent,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        metadata: MessageMetadataEntity(a2uiMessages: [payload]),
      );

      final result = await usecase.call([entity]);

      expect(result, hasLength(1));
      expect(result.single.role, engine.ChatMessageRole.model);
      expect(
        result.single.parts.whereType<TextPart>().single.text,
        contains('"createSurface"'),
      );
      expect(entity.content, isEmpty);
    });
  });
}
