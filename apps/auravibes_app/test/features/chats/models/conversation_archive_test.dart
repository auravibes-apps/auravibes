import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationArchiveCodec', () {
    test(
      'round-trips safe transcript fields without exporting private data',
      () async {
        final createdAt = DateTime.utc(2025, 1, 2);
        final conversation = ConversationEntity(
          id: 'conversation-private-id',
          title: 'Archive test',
          workspaceId: 'workspace-private-id',
          isPinned: false,
          createdAt: createdAt,
          updatedAt: createdAt,
          modelId: 'model-private-id',
          agentId: 'agent-private-id',
        );
        final messages = [
          MessageEntity(
            id: 'message-private-id',
            conversationId: conversation.id,
            content: 'User message',
            messageType: .text,
            isUser: true,
            status: .sent,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
          MessageEntity(
            id: 'summary-private-id',
            conversationId: conversation.id,
            content: 'Assistant summary',
            messageType: .text,
            isUser: false,
            status: .sent,
            createdAt: createdAt,
            updatedAt: createdAt,
            metadata: .new(
              toolCalls: const [
                MessageToolCallEntity(
                  id: 'tool-call-private-id',
                  name: 'mcp__private-server-id__search_docs',
                  argumentsRaw: '{"authorization":"MCP_SECRET"}',
                  userFacingDescription: 'Search documents',
                  responseRaw: 'tool-response-secret',
                  resultStatus: .success,
                ),
              ],
              promptTokens: 4,
              completionTokens: 3,
              totalTokens: 7,
              thinking: 'private-thinking',
              modelMetadata: const {
                'apiKey': 'workspace-secret',
                'providerError': true,
              },
              a2uiMessages: const ['{"text":"Visible card"}'],
              isCompactionSummary: true,
              compactionKind: .manual,
              compactedFromMessageId: 'message-private-id',
              compactedThroughMessageId: 'message-private-id',
              compactedMessageIds: const ['message-private-id'],
              compactionCreatedAt: createdAt,
            ),
            attachments: [
              MessageAttachmentEntity(
                id: 'attachment-private-id',
                messageId: 'summary-private-id',
                localPath: 'file:///private/attachment/report.pdf',
                fileName: 'report.pdf',
                displayName: 'Report',
                mimeType: 'application/pdf',
                modality: .file,
                sizeBytes: 3,
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            ],
          ),
        ];

        final encoded = await ConversationArchiveCodec.exportConversation(
          conversation: conversation,
          messages: messages,
          modelLabel: 'Example model',
          readAttachmentBytes: (path) async {
            expect(path, 'file:///private/attachment/report.pdf');

            return Uint8List.fromList([1, 2, 3]);
          },
        );
        final decodedJson = jsonDecode(encoded) as Map<String, dynamic>;
        final transcript = decodedJson['conversation'] as Map<String, dynamic>;
        final archivedMessages = decodedJson['messages'] as List<dynamic>;
        final summary = archivedMessages[1] as Map<String, dynamic>;
        final metadata = summary['metadata'] as Map<String, dynamic>;
        final toolCall =
            (metadata['toolCalls'] as List<dynamic>).single
                as Map<String, dynamic>;
        final attachment =
            (summary['attachments'] as List<dynamic>).single
                as Map<String, dynamic>;

        expect(decodedJson['format'], ConversationArchiveCodec.format);
        expect(decodedJson['version'], ConversationArchiveCodec.version);
        expect(transcript['title'], 'Archive test');
        expect(transcript['modelLabel'], 'Example model');
        expect(metadata['totalTokens'], 7);
        expect(metadata['a2uiMessages'], ['{"text":"Visible card"}']);
        expect(metadata['compactedMessageIndexes'], [0]);
        expect(toolCall, {
          'displayName': 'Search documents',
          'resultStatus': 'success',
        });
        expect(attachment['dataBase64'], 'AQID');
        expect(attachment['displayName'], 'Report');
        expect(attachment, isNot(contains('localPath')));
        expect(
          ConversationArchiveCodec.encode(
            ConversationArchiveCodec.decode(encoded),
          ),
          encoded,
        );

        for (final privateValue in [
          'conversation-private-id',
          'workspace-private-id',
          'model-private-id',
          'agent-private-id',
          'message-private-id',
          'summary-private-id',
          'tool-call-private-id',
          'attachment-private-id',
          'MCP_SECRET',
          'mcp__private-server-id__search_docs',
          'tool-response-secret',
          'workspace-secret',
          'private-thinking',
          'file:///private/attachment/report.pdf',
        ]) {
          expect(encoded, isNot(contains(privateValue)));
        }
      },
    );

    test('rejects Windows separators in attachment file names', () {
      const archiveJson = r'''
{
  "format": "auravibes.conversation",
  "version": 1,
  "conversation": {
    "title": "Archive",
    "createdAt": "2025-01-02T00:00:00.000Z",
    "updatedAt": "2025-01-02T00:00:00.000Z",
    "modelLabel": null
  },
  "messages": [
    {
      "content": "Message",
      "messageType": "text",
      "isUser": true,
      "status": "sent",
      "createdAt": "2025-01-02T00:00:00.000Z",
      "metadata": {
        "promptTokens": null,
        "completionTokens": null,
        "totalTokens": null,
        "providerError": null,
        "a2uiRequiresUserAction": null,
        "a2uiMessages": [],
        "isCompactionSummary": false,
        "compactionKind": null,
        "compactedFromMessageIndex": null,
        "compactedThroughMessageIndex": null,
        "compactedMessageIndexes": [],
        "compactionCreatedAt": null,
        "toolCalls": []
      },
      "attachments": [
        {
          "fileName": "..\\private.txt",
          "displayName": "Private file",
          "mimeType": "text/plain",
          "modality": "file",
          "sizeBytes": 1,
          "dataBase64": "AQ=="
        }
      ]
    }
  ]
}
''';

      expect(
        () => ConversationArchiveCodec.decode(archiveJson),
        throwsA(isA<MalformedConversationArchiveException>()),
      );
    });
    test('rejects malformed archives and unknown versions', () {
      expect(
        () => ConversationArchiveCodec.decode(
          '{"format":"auravibes.conversation","version":1,"messages":{}}',
        ),
        throwsA(isA<MalformedConversationArchiveException>()),
      );
      expect(
        () => ConversationArchiveCodec.decode(
          '{"format":"auravibes.conversation","version":999}',
        ),
        throwsA(isA<UnsupportedArchiveVersionException>()),
      );
    });
  });
}
