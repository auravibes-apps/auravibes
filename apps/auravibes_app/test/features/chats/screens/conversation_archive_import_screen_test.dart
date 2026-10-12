import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_decode_exception.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/providers/conversation_archive_provider.dart';
import 'package:auravibes_app/features/chats/screens/chat_conversation_screen.dart';
import 'package:auravibes_app/features/chats/services/conversation_archive_file_service.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/ux_validation_fixture.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  tearDownAll(UxValidationFixture.closeDatabase);

  testWidgets('cancel leaves conversations and attachment files untouched', (
    tester,
  ) async {
    final f = await UxValidationFixture.create();
    final before = await f.database.select(f.database.conversations).get();
    final attachmentService = _UnexpectedAttachmentStagingService();
    final archiveJson = ConversationArchiveCodec.encodeMany([
      _archive(
        'Affected conversation',
        isIncomplete: true,
        hasAttachment: true,
      ),
      _archive('Complete conversation', isIncomplete: false),
    ]);
    final _ = await f.pump(
      tester,
      ChatsRoute(workspaceId: f.workspaceId).location,
      overrides: [
        conversationArchiveFileServiceProvider.overrideWithValue(
          _FixedArchiveFileService(archiveJson),
        ),
        localChatAttachmentServiceProvider.overrideWithValue(attachmentService),
      ],
    );

    await tester.tap(find.byTooltip('Import archive'));
    await f.settle(tester);

    expect(
      find.text('Some conversations have incomplete agent context'),
      findsOneWidget,
    );
    expect(find.text('Affected conversation'), findsOneWidget);
    expect(find.text('Complete conversation'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await f.settle(tester);

    expect(
      await f.database.select(f.database.conversations).get(),
      hasLength(before.length),
    );
    expect(attachmentService.createCalls, 0);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  testWidgets('continuing shows a persistent warning and keeps replay closed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final f = await UxValidationFixture.create();
    final archiveJson = ConversationArchiveCodec.encode(
      _archive('Incomplete imported conversation', isIncomplete: true),
    );
    final _ = await f.pump(
      tester,
      ChatsRoute(workspaceId: f.workspaceId).location,
      overrides: [
        conversationArchiveFileServiceProvider.overrideWithValue(
          _FixedArchiveFileService(archiveJson),
        ),
      ],
    );

    await tester.tap(find.byTooltip('Import archive'));
    await f.settle(tester);
    await tester.tap(find.text('Continue import'));
    await f.settle(tester);

    expect(find.byType(ChatConversationScreen), findsOneWidget);
    expect(find.text('Incomplete agent context'), findsOneWidget);
    expect(
      find.textContaining(
        'This imported conversation has incomplete agent context.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>('chat_incomplete_agent_context_notice'),
            ),
          )
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();

    final imported =
        await (f.database.select(f.database.conversations)..where(
              (conversation) =>
                  conversation.title.equals('Incomplete imported conversation'),
            ))
            .getSingle();
    final transcript = await MessageRepository(f.database)
        .getTranscriptMessagesByConversation(imported.id);
    final sentinel = transcript.singleWhere(
      (message) => message.isAgentTranscriptContextUpdate,
    );

    expect(sentinel.content, '{"version":1}');
    expect(
      sentinel.metadata?.modelMetadata[MessageMetadataEntity
          .incompleteArchivedAgentContextMetadataKey],
      isTrue,
    );
    expect(
      () => AgentTranscriptContextCodec.decodeUpdate(sentinel.content),
      throwsA(isA<MalformedTranscriptContextException>()),
    );
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });
}

ConversationArchive _archive(
  String title, {
  required bool isIncomplete,
  bool hasAttachment = false,
}) {
  final createdAt = DateTime.utc(2026, 10, 11);

  return .new(
    title: title,
    createdAt: createdAt,
    updatedAt: createdAt,
    messages: [
      if (hasAttachment)
        .new(
          content: 'Visible message',
          messageType: .text,
          isUser: true,
          status: .sent,
          createdAt: createdAt,
          metadata: const .new(),
          attachments: [
            .new(
              fileName: 'context.txt',
              displayName: 'Context file',
              mimeType: 'text/plain',
              modality: .file,
              bytes: .fromList([1, 2, 3]),
            ),
          ],
        ),
    ],
    agentContext: .new(
      isComplete: !isIncomplete,
      entriesInput: const [],
      toolSelectionsInput: const [],
    ),
  );
}

class _FixedArchiveFileService extends ConversationArchiveFileService {
  new(this.archiveJson);

  final String archiveJson;

  @override
  Future<String?> pickArchiveJson() async => archiveJson;
}

class _UnexpectedAttachmentStagingService extends LocalChatAttachmentService {
  new();

  int createCalls = 0;

  @override
  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment _,
  ) async {
    createCalls++;
    throw StateError('Cancellation should prevent attachment staging.');
  }
}
