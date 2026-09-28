import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_archive_usecase.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'rejects malformed input and unknown versions before creating rows',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Archive test', type: .local),
      );
      final usecase = _usecase(database);

      await expectLater(
        usecase.importConversation(
          workspaceId: workspace.id,
          archiveJson: '''
          {"format":"auravibes.conversation","version":1,"messages":{}}
          ''',
        ),
        throwsA(isA<MalformedConversationArchiveException>()),
      );

      await expectLater(
        usecase.importConversation(
          workspaceId: workspace.id,
          archiveJson: '{"format":"auravibes.conversation","version":999}',
        ),
        throwsA(isA<UnsupportedArchiveVersionException>()),
      );

      expect(await database.select(database.conversations).get(), isEmpty);
      expect(await database.select(database.messages).get(), isEmpty);
    },
  );

  test(
    'imports repeated archive with fresh IDs and original timestamps',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Archive test', type: .local),
      );
      final usecase = _usecase(database);
      final createdAt = DateTime.utc(2025, 1, 2);
      final archiveJson = ConversationArchiveCodec.encode(
        .new(
          title: 'Imported chat',
          createdAt: createdAt,
          updatedAt: createdAt,
          messages: [
            .new(
              content: 'Transcript text',
              messageType: .text,
              isUser: true,
              status: .sent,
              createdAt: createdAt,
              metadata: const .new(
                toolCalls: [],
                a2uiMessages: [],
                isCompactionSummary: false,
                compactedMessageIndexes: [],
              ),
              attachments: [],
            ),
          ],
        ),
      );

      final first = await usecase.importConversation(
        workspaceId: workspace.id,
        archiveJson: archiveJson,
      );
      final second = await usecase.importConversation(
        workspaceId: workspace.id,
        archiveJson: archiveJson,
      );
      final firstMessages = await MessageRepository(database)
          .getMessagesByConversation(first.id);
      final secondMessages = await MessageRepository(database)
          .getMessagesByConversation(second.id);

      expect(first.id, isNot(second.id));
      expect(first.title, 'Imported chat');
      expect(first.createdAt.isAtSameMomentAs(createdAt), isTrue);
      expect(firstMessages.single.id, isNot(secondMessages.single.id));
      expect(firstMessages.single.content, 'Transcript text');
      expect(
        firstMessages.single.createdAt.isAtSameMomentAs(createdAt),
        isTrue,
      );
    },
  );

  test('keeps persisted attachment files after importing messages', () async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'archive_import_test_',
    );
    final supportDirectory = Directory.systemTemp.createTempSync(
      'archive_support_test_',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getTemporaryDirectory') return tempDirectory.path;
      if (call.method == 'getApplicationSupportDirectory') {
        return supportDirectory.path;
      }

      return null;
    });
    addTearDown(() async {
      messenger.setMockMethodCallHandler(channel, null);
      final _ = await tempDirectory.delete(recursive: true);
      final _ = await supportDirectory.delete(recursive: true);
    });
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Archive test', type: .local),
    );
    final attachmentDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}chat_attachments_draft',
    )..createSync(recursive: true);
    final attachmentService = _FakeArchiveAttachmentService(
      attachmentDirectory,
    );
    final usecase = _usecase(database, attachmentService: attachmentService);
    final createdAt = DateTime.utc(2025, 1, 2);
    final archiveJson = ConversationArchiveCodec.encode(
      .new(
        title: 'Imported chat',
        createdAt: createdAt,
        updatedAt: createdAt,
        messages: [
          .new(
            content: 'Attached file',
            messageType: .text,
            isUser: true,
            status: .sent,
            createdAt: createdAt,
            metadata: const .new(
              toolCalls: [],
              a2uiMessages: [],
              isCompactionSummary: false,
              compactedMessageIndexes: [],
            ),
            attachments: [
              .new(
                fileName: 'report.txt',
                displayName: 'Report',
                mimeType: 'text/plain',
                modality: .file,
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ],
          ),
        ],
      ),
    );

    final conversation = await usecase.importConversation(
      workspaceId: workspace.id,
      archiveJson: archiveJson,
    );
    final importedMessage = (await MessageRepository(
      database,
    ).getMessagesByConversation(conversation.id)).single;

    final importedAttachment = File(
      importedMessage.attachments.single.localPath,
    );
    expect(importedAttachment.existsSync(), isTrue);
    expect(importedAttachment.readAsBytesSync(), [1, 2, 3]);
    expect(attachmentDirectory.listSync(), isEmpty);
  });
}

ConversationArchiveUsecase _usecase(
  AppDatabase database, {
  LocalChatAttachmentService? attachmentService,
}) => .new(
  conversationRepository: .new(database),
  messageRepository: .new(database),
  attachmentService: attachmentService ?? LocalChatAttachmentService(),
);

class _FakeArchiveAttachmentService extends LocalChatAttachmentService {
  new(this._directory);

  final Directory _directory;

  @override
  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment attachment,
  ) async {
    final file = File(
      '${_directory.path}${Platform.pathSeparator}${attachment.fileName}',
    );
    final _ = await file.writeAsBytes(attachment.bytes);

    return .new(
      localPath: file.path,
      fileName: attachment.fileName,
      displayName: attachment.displayName,
      mimeType: attachment.mimeType,
      modality: attachment.modality,
      sizeBytes: attachment.bytes.length,
    );
  }

  @override
  Future<void> deleteAttachment(String localPath) async {
    final file = File(localPath);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
  }
}
