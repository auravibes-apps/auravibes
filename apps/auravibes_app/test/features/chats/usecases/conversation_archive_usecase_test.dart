import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_archive_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show foldAgentTranscriptContext;
import 'package:collection/collection.dart';
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

  test('imports a legacy single archive through the archive usecase', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Archive test', type: .local),
    );
    final createdAt = DateTime.utc(2025, 1, 2);
    final legacy =
        jsonDecode(
            ConversationArchiveCodec.encode(
              .new(
                title: 'Legacy archive',
                createdAt: createdAt,
                updatedAt: createdAt,
                messages: [],
              ),
            ),
          ) as Map<String, dynamic>
          ..['version'] = ConversationArchiveCodec.legacyVersion
          ..remove('agentContext');

    final imported = await _usecase(
      database,
    ).importArchive(workspaceId: workspace.id, archiveJson: jsonEncode(legacy));

    expect(imported.single.title, 'Legacy archive');
    expect(imported.single.workspaceId, workspace.id);
  });

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

  test(
    'restores hidden trusted context and remaps compacted message IDs',
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
      final archive = ConversationArchive(
        title: 'Context chat',
        createdAt: createdAt,
        updatedAt: createdAt.add(const Duration(seconds: 3)),
        messages: [
          _archiveMessage('First message', createdAt),
          _archiveMessage(
            'Compacted summary',
            createdAt.add(const Duration(seconds: 2)),
            metadata: const ConversationArchiveMetadata(
              isCompactionSummary: true,
              compactedMessageIndexes: [0],
              compactedFromMessageIndex: 0,
              compactedThroughMessageIndex: 0,
            ),
          ),
        ],
        agentContext: .new(
          isComplete: true,
          entriesInput: [
            ConversationArchiveAgentContextEntry(
              afterMessageIndex: null,
              createdAt: createdAt.subtract(const Duration(seconds: 1)),
              updateJson: _contextUpdate(
                toolsAdded: ['tool_a', 'tool_b'],
                toolsRemoved: const [],
                contextMessages: const [
                  {'role': 'system', 'content': 'Trusted system context'},
                ],
                toolOrder: ['tool_a', 'tool_b'],
                approvalStates: {'tool_a': 'ask', 'tool_b': 'ask'},
              ),
            ),
            ConversationArchiveAgentContextEntry(
              afterMessageIndex: 0,
              createdAt: createdAt.add(const Duration(seconds: 1)),
              updateJson: _contextUpdate(
                toolsAdded: ['tool_c'],
                toolsRemoved: ['tool_a'],
                contextMessages: const [
                  {'role': 'system', 'content': 'Trusted system context'},
                  {
                    'role': 'skill',
                    'content': 'Trusted skill context',
                    'kind': 'skill',
                  },
                ],
                toolOrder: ['tool_c', 'tool_b'],
                approvalStates: {'tool_c': 'granted', 'tool_b': 'ask'},
              ),
            ),
          ],
          toolSelectionsInput: const [],
        ),
      );

      final imported = (await usecase.importArchive(
        workspaceId: workspace.id,
        archiveJson: ConversationArchiveCodec.encode(archive),
      )).single;
      final messageRepository = MessageRepository(database);
      final transcript = await messageRepository
          .getTranscriptMessagesByConversation(imported.id);
      final visibleMessages = await messageRepository.getMessagesByConversation(
        imported.id,
      );
      final contextUpdates = transcript
          .where((message) => message.isAgentTranscriptContextUpdate)
          .map(
            (message) =>
                AgentTranscriptContextCodec.decodeUpdate(message.content),
          )
          .toList();
      final context = foldAgentTranscriptContext(contextUpdates);

      expect(
        transcript.map((message) => message.isAgentTranscriptContextUpdate),
        [true, false, true, false],
      );
      expect(visibleMessages.map((message) => message.content), [
        'First message',
        'Compacted summary',
      ]);
      expect(context.tools.map((tool) => tool.name), ['tool_c', 'tool_b']);
      expect(context.approvalStates, {'tool_c': 'granted', 'tool_b': 'ask'});
      expect(context.contextMessages, hasLength(2));
      expect(context.contextMessages.last.content, 'Trusted skill context');
      expect(visibleMessages.last.metadata?.compactedMessageIds, [
        visibleMessages.firstOrNull?.id,
      ]);
      expect(
        visibleMessages.last.metadata?.compactedFromMessageId,
        visibleMessages.firstOrNull?.id,
      );
    },
  );

  test('remaps conversation tool settings by safe tool descriptor', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final sourceWorkspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Source', type: .local),
    );
    final targetWorkspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Target', type: .local),
    );
    final workspaceTools = WorkspaceToolsRepository(database);
    final _ = await workspaceTools.setWorkspaceToolEnabled(
      sourceWorkspace.id,
      'calculator',
      isEnabled: true,
    );
    final _ = await workspaceTools.setWorkspaceToolEnabled(
      targetWorkspace.id,
      'calculator',
      isEnabled: true,
    );
    final sourceTool = (await workspaceTools.getWorkspaceTools(
      sourceWorkspace.id,
    )).singleWhere((tool) => tool.toolId == 'calculator');
    final targetTool = (await workspaceTools.getWorkspaceTools(
      targetWorkspace.id,
    )).singleWhere((tool) => tool.toolId == 'calculator');
    final conversations = ConversationRepository(database);
    final sourceConversation = await conversations.createConversation(
      .new(title: 'Tool settings', workspaceId: sourceWorkspace.id),
    );
    final tools = ConversationToolsRepository(database, workspaceTools);
    final _ = await tools.setConversationToolEnabled(
      sourceConversation.id,
      sourceTool.id,
      isEnabled: false,
    );
    final _ = await tools.setConversationToolPermission(
      sourceConversation.id,
      sourceTool.id,
      permissionMode: .alwaysDeny,
    );
    final usecase = _usecase(database);
    final encoded = await usecase.exportConversation(
      conversationId: sourceConversation.id,
    );
    final archive = ConversationArchiveCodec.decode(encoded);
    final imported = (await usecase.importArchive(
      workspaceId: targetWorkspace.id,
      archiveJson: encoded,
    )).single;
    final restored = (await tools.getConversationTools(imported.id)).single;

    expect(sourceTool.id, isNot(targetTool.id));
    expect(encoded, isNot(contains(sourceTool.id)));
    expect(archive.agentContext?.toolSelections.single.toolName, 'calculator');
    expect(restored.toolId, targetTool.id);
    expect(restored.isEnabled, isFalse);
    expect(restored.permissionMode, ToolPermissionMode.alwaysDeny);
  });

  test('imports conversation when destination lacks archived tool', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Archive test', type: .local),
    );
    final createdAt = DateTime.utc(2025, 1, 2);
    final archive = ConversationArchiveCodec.encode(
      .new(
        title: 'Unavailable tool',
        createdAt: createdAt,
        updatedAt: createdAt,
        messages: [],
        agentContext: .new(
          isComplete: true,
          entriesInput: const [],
          toolSelectionsInput: [
            const ConversationArchiveToolSelection(
              groupName: null,
              toolName: 'workspace_only_tool',
              isEnabled: false,
              permissionMode: .alwaysDeny,
            ),
          ],
        ),
      ),
    );

    final imported = await _usecase(database)
        .importArchive(workspaceId: workspace.id, archiveJson: archive);

    expect(imported.single.title, 'Unavailable tool');
    expect(await database.select(database.conversations).get(), hasLength(1));
    expect(await database.select(database.conversationTools).get(), isEmpty);
  });

  test('rejects malformed later bundle entry before inserting rows', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await database.workspaceDao.insertWorkspace(
      .insert(name: 'Archive test', type: .local),
    );
    final createdAt = DateTime.utc(2025, 1, 2);
    final valid = ConversationArchiveCodec.encode(
      .new(
        title: 'Valid first item',
        createdAt: createdAt,
        updatedAt: createdAt,
        messages: [],
      ),
    );
    final invalidBundle = jsonEncode({
      'format': ConversationArchiveCodec.bundleFormat,
      'version': ConversationArchiveCodec.bundleVersion,
      'conversations': [
        jsonDecode(valid),
        {
          'format': ConversationArchiveCodec.format,
          'version': ConversationArchiveCodec.version,
          'conversation': <String, Object?>{},
          'messages': <Object?>[],
          'agentContext': null,
        },
      ],
    });

    await expectLater(
      _usecase(database)
          .importArchive(workspaceId: workspace.id, archiveJson: invalidBundle),
      throwsA(isA<MalformedConversationArchiveException>()),
    );

    expect(await database.select(database.conversations).get(), isEmpty);
    expect(await database.select(database.messages).get(), isEmpty);
  });

  test(
    'rejects invalid context state before importing any conversation',
    () async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspace = await database.workspaceDao.insertWorkspace(
        .insert(name: 'Archive test', type: .local),
      );
      final createdAt = DateTime.utc(2025, 1, 2);
      final invalid = ConversationArchiveCodec.encode(
        .new(
          title: 'Invalid context',
          createdAt: createdAt,
          updatedAt: createdAt,
          messages: [],
          agentContext: .new(
            isComplete: true,
            entriesInput: [
              ConversationArchiveAgentContextEntry(
                afterMessageIndex: null,
                createdAt: createdAt,
                updateJson: _contextUpdate(
                  toolsAdded: const [],
                  toolsRemoved: ['unknown_tool'],
                ),
              ),
            ],
            toolSelectionsInput: const [],
          ),
        ),
      );

      await expectLater(
        _usecase(database)
            .importArchive(workspaceId: workspace.id, archiveJson: invalid),
        throwsA(isA<MalformedConversationArchiveException>()),
      );

      expect(await database.select(database.conversations).get(), isEmpty);
      expect(await database.select(database.messages).get(), isEmpty);
    },
  );

  test(
    'rolls back rows and promoted attachments after bundle write failure',
    () async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'archive_rollback_draft_',
      );
      final supportDirectory = Directory.systemTemp.createTempSync(
        'archive_rollback_support_',
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
      final draftDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}archive_rollback_test'
        '${Platform.pathSeparator}chat_attachments_draft',
      )..createSync(recursive: true);
      const fileStore = AttachmentFileStore(
        storageNamespace: 'archive_rollback_test',
      );
      final firstStagedPath =
          '${draftDirectory.path}${Platform.pathSeparator}rollback.txt';
      final attachmentService = _FakeArchiveAttachmentService(
        draftDirectory,
        failDeletePath: firstStagedPath,
      );
      final messageRepository = _FailOnSecondMessageRepository(
        database,
        attachmentFileStore: fileStore,
      );
      final usecase = _usecase(
        database,
        attachmentService: attachmentService,
        messageRepository: messageRepository,
        attachmentFileStore: fileStore,
      );
      final createdAt = DateTime.utc(2025, 1, 2);
      final bundle = ConversationArchiveCodec.encodeMany([
        .new(
          title: 'First item',
          createdAt: createdAt,
          updatedAt: createdAt,
          messages: [
            _archiveMessage(
              'Attached first message',
              createdAt,
              attachments: [
                ConversationArchiveAttachment(
                  fileName: 'rollback.txt',
                  displayName: 'Rollback',
                  mimeType: 'text/plain',
                  modality: .file,
                  bytes: .fromList([1, 2, 3]),
                ),
                ConversationArchiveAttachment(
                  fileName: 'rollback-second.txt',
                  displayName: 'Rollback second',
                  mimeType: 'text/plain',
                  modality: .file,
                  bytes: .fromList([4, 5, 6]),
                ),
              ],
            ),
          ],
        ),
        .new(
          title: 'Second item',
          createdAt: createdAt,
          updatedAt: createdAt,
          messages: [_archiveMessage('Second message', createdAt)],
        ),
      ]);

      await expectLater(
        usecase.importArchive(workspaceId: workspace.id, archiveJson: bundle),
        throwsA(isA<StateError>()),
      );

      final persistedDirectory = Directory(
        '${supportDirectory.path}${Platform.pathSeparator}archive_rollback_test'
        '${Platform.pathSeparator}chat_attachments',
      );
      expect(await database.select(database.conversations).get(), isEmpty);
      expect(await database.select(database.messages).get(), isEmpty);
      expect(await database.select(database.messageAttachments).get(), isEmpty);
      expect(draftDirectory.listSync(), isEmpty);
      expect(persistedDirectory.existsSync(), isTrue);
      expect(persistedDirectory.listSync(), isEmpty);
      expect(attachmentService.deleteAttempts, hasLength(2));
      expect(
        attachmentService.deleteAttempts.last,
        endsWith('rollback-second.txt'),
      );
    },
  );
}

ConversationArchiveUsecase _usecase(
  AppDatabase database, {
  LocalChatAttachmentService? attachmentService,
  MessageRepository? messageRepository,
  AttachmentFileStore attachmentFileStore = const AttachmentFileStore(),
}) {
  final workspaceTools = WorkspaceToolsRepository(database);
  final messages =
      messageRepository ??
      MessageRepository(database, attachmentFileStore: attachmentFileStore);

  return .new(
    conversationRepository: ConversationRepository(database),
    messageRepository: messages,
    attachmentService: attachmentService ?? LocalChatAttachmentService(),
    conversationToolsRepository: ConversationToolsRepository(
      database,
      workspaceTools,
    ),
    workspaceToolsRepository: workspaceTools,
    toolsGroupsRepository: ToolsGroupsRepository(database),
    attachmentFileStore: attachmentFileStore,
  );
}

ConversationArchiveMessage _archiveMessage(
  String content,
  DateTime createdAt, {
  ConversationArchiveMetadata metadata = const ConversationArchiveMetadata(),
  List<ConversationArchiveAttachment> attachments = const [],
}) => ConversationArchiveMessage(
  content: content,
  messageType: .text,
  isUser: true,
  status: .sent,
  createdAt: createdAt,
  metadata: metadata,
  attachments: attachments,
);

String _contextUpdate({
  required List<String> toolsAdded,
  required List<String> toolsRemoved,
  List<Map<String, Object?>>? contextMessages,
  List<String>? toolOrder,
  Map<String, String>? approvalStates,
}) => jsonEncode({
  'version': 1,
  'toolsAdded': [
    for (final name in toolsAdded)
      {
        'name': name,
        'description': 'Tool $name',
        'inputJsonSchema': {'type': 'object'},
        'requiresCredential': false,
      },
  ],
  'toolsRemoved': toolsRemoved,
  'contextMessages': ?contextMessages,
  'toolOrder': ?toolOrder,
  'approvalStates': ?approvalStates,
});

class _FailOnSecondMessageRepository extends MessageRepository {
  new(super.database, {required super.attachmentFileStore});

  var _calls = 0;

  @override
  Future<MessageEntity> createMessage(MessageToCreate message) async {
    _calls++;
    if (_calls == 2) throw StateError('Injected write failure');

    return await super.createMessage(message);
  }
}

class _FakeArchiveAttachmentService extends LocalChatAttachmentService {
  new(this._directory, {this.failDeletePath});

  final String? failDeletePath;
  final deleteAttempts = <String>[];
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
    deleteAttempts.add(localPath);
    if (localPath == failDeletePath) {
      throw FileSystemException('Injected staged cleanup failure', localPath);
    }
    final file = File(localPath);
    if (file.existsSync()) {
      final _ = await file.delete();
    }
  }
}
