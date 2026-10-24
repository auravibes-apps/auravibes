import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message stores shared asset identity without cloning bytes', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    final created = await fixture.messages.createMessage(_message(_asset));
    expect(created.attachments.single.assetId, 'asset');
    expect(created.attachments.single.localPath, _asset.localPath);
    final read = await fixture.messages.getMessagesByConversation(
      'conversation',
    );
    expect(read.single.attachments.single.assetId, 'asset');
    expect(
      await fixture.database.select(fixture.database.workspaceAssets).get(),
      hasLength(1),
    );
  });

  test('message rejects cross-workspace, missing and forged asset references atomically', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.database.close);
    for (final invalid in [
      _asset.copyWith(
        localPath: 'workspace-asset://asset/asset-test/other/asset',
      ),
      _asset.copyWith(localPath: 'workspace-asset://asset/other/local/asset'),
      _asset.copyWith(assetId: 'missing'),
      _asset.copyWith(assetId: null),
      _asset.copyWith(sizeBytes: 9),
      _asset.copyWith(mimeType: 'image/png'),
    ]) {
      await expectLater(
        fixture.messages.createMessage(_message(invalid)),
        throwsA(isA<WorkspaceAssetException>()),
      );
      expect(
        await fixture.messages.getMessagesByConversation('conversation'),
        isEmpty,
      );
    }
  });
}

const _asset = MessageAttachmentToCreate(
  assetId: 'asset',
  localPath: 'workspace-asset://asset/asset-test/local/asset',
  fileName: 'notes.txt',
  displayName: 'notes.txt',
  mimeType: 'text/plain',
  modality: .file,
  sizeBytes: 5,
);
MessageToCreate _message(MessageAttachmentToCreate attachment) => .new(
  conversationId: 'conversation',
  content: 'See attachment',
  messageType: .text,
  isUser: true,
  status: .sent,
  attachments: [attachment],
);

class _Fixture {
  _Fixture(this.database);
  final AppDatabase database;
  MessageRepository get messages =>
      MessageRepository(database, attachmentFileStore: const _Store());
  static Future<_Fixture> create() async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('local'),
            name: 'Local',
            type: .local,
          ),
        );
    final _ = await database.conversationDao.insertConversation(
      .insert(
        id: const .new('conversation'),
        workspaceId: 'local',
        title: 'Chat',
      ),
    );
    final _ = await database
        .into(database.workspaceAssets)
        .insert(
          WorkspaceAssetsCompanion.insert(
            id: const .new('asset'),
            workspaceId: 'local',
            name: 'notes.txt',
            mimeType: 'text/plain',
            sizeBytes: 5,
            checksum: 'a' * 64,
            status: const .new('active'),
          ),
        );
    return _Fixture(database);
  }
}

class _Store extends AttachmentFileStore {
  const _Store() : super(storageNamespace: 'asset-test');
  @override
  Future<String> persistDraftFile(String path) async => path;
  @override
  Future<void> deleteFile(String path) async {}
}
