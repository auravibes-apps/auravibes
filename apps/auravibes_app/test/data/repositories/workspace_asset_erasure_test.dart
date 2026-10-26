import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_cleanup.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_erasure.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_credential_erasure.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/usecases/delete_workspace_use_case.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/legacy_api_key_storage.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  test(
    'failed byte write leaves retryable cleanup for its partial bytes',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final store = _InterruptedStore();
      final repository = WorkspaceRepository(
        database,
        attachmentFileStore: store,
      );
      final workspace = await repository.createWorkspace(
        const .new(name: 'One', type: .local),
      );
      await expectLater(
        LocalWorkspaceAssetRepository(
          database,
          workspace.id,
          store,
        ).upload('notes.txt', .fromList('hello'.codeUnits)),
        throwsStateError,
      );
      store.fail = true;
      await LocalWorkspaceAssetCleanup(database, workspace.id, store).flush();
      expect(store.stored, hasLength(1));
      store.fail = false;
      await LocalWorkspaceAssetCleanup(database, workspace.id, store).flush();
      expect(store.stored, isEmpty);
      expect(await database.select(database.workspaceAssets).get(), isEmpty);
    },
  );

  test(
    'completed upload is erased when workspace deletion follows it',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final store = _RacingStore(bytesBefore: false)..release.complete();
      final repository = WorkspaceRepository(
        database,
        attachmentFileStore: store,
      );
      final workspace = await repository.createWorkspace(
        const .new(name: 'One', type: .local),
      );
      final asset = await LocalWorkspaceAssetRepository(
        database,
        workspace.id,
        store,
      ).upload('notes.txt', .fromList('hello'.codeUnits));
      expect(store.stored, {asset.id});
      expect(await repository.deleteWorkspace(workspace.id), isTrue);
      final cleanup = LocalWorkspaceAssetErasure(database, store);
      await cleanup.flush();
      await cleanup.flush();
      expect(store.stored, isEmpty);
      expect(
        await database.select(database.workspaceAssetDeletions).get(),
        isEmpty,
      );
    },
  );

  test(
    'late upload cannot reactivate metadata already queued for deletion',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final store = _RacingStore(bytesBefore: false);
      final repository = WorkspaceRepository(
        database,
        attachmentFileStore: store,
      );
      final workspace = await repository.createWorkspace(
        const .new(name: 'One', type: .local),
      );
      final upload = LocalWorkspaceAssetRepository(
        database,
        workspace.id,
        store,
      ).upload('notes.txt', .fromList('hello'.codeUnits));
      await store.started.future;
      final _ = await database
          .update(database.workspaceAssets)
          .write(const WorkspaceAssetsCompanion(status: .new('deleting')));
      final denied = expectLater(
        upload,
        throwsA(isA<WorkspaceAssetException>()),
      );
      store.release.complete();
      await denied;
      expect(
        (await database.select(database.workspaceAssets).get()).single.status,
        'deleting',
      );
      await LocalWorkspaceAssetCleanup(database, workspace.id, store).flush();
      expect(store.stored, isEmpty);
    },
  );

  for (final before in [false, true]) {
    test('late upload queues cleanup: bytesBefore=$before', () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final store = _RacingStore(bytesBefore: before);
      final repository = WorkspaceRepository(
        database,
        attachmentFileStore: store,
      );
      final workspace = await repository.createWorkspace(
        const .new(name: 'One', type: .local),
      );
      final upload = LocalWorkspaceAssetRepository(
        database,
        workspace.id,
        store,
      ).upload('notes.txt', .fromList('hello'.codeUnits));
      await store.started.future;
      expect(await repository.deleteWorkspace(workspace.id), isTrue);
      final cleanup = LocalWorkspaceAssetErasure(database, store);
      await cleanup.flush();
      final denied = expectLater(
        upload,
        throwsA(isA<WorkspaceAssetException>()),
      );
      store.release.complete();
      await denied;
      expect(await database.select(database.workspaceAssets).get(), isEmpty);
      expect(
        await database.select(database.workspaceAssetDeletions).get(),
        hasLength(1),
      );
      expect(await cleanup.hasPendingCleanup(workspace.id), isTrue);
      expect(
        (await database.select(database.workspaceAssetDeletions).get())
            .single
            .workspaceId,
        workspace.id,
      );
      store.fail = true;
      await cleanup.flush();
      expect(
        await database.select(database.workspaceAssetDeletions).get(),
        hasLength(1),
      );
      store.fail = false;
      await cleanup.flush();
      await cleanup.flush();
      expect(store.stored, isEmpty);
      expect(
        await database.select(database.workspaceAssetDeletions).get(),
        isEmpty,
      );
    });
  }

  test('last workspace cleanup retries after database reopen', () async {
    final directory = await Directory.systemTemp.createTemp('asset-erasure-');
    addTearDown(() async {
      final _ = await directory.delete(recursive: true);
    });
    final path = File('${directory.path}/data.sqlite');
    final database = AppDatabase(connection: NativeDatabase(path));
    final store = _Store()..fail = true;
    final repository = WorkspaceRepository(
      database,
      attachmentFileStore: store,
    );
    final workspace = await repository.createWorkspace(
      const .new(name: 'One', type: .local),
    );
    await _asset(database, workspace.id, 'owned');
    expect(await repository.deleteWorkspace(workspace.id), isTrue);
    await LocalWorkspaceAssetErasure(database, store).flush();
    expect(store.deleted, isEmpty);
    await database.close();
    final reopened = AppDatabase(connection: NativeDatabase(path));
    addTearDown(reopened.close);
    store.fail = false;
    final cleanup = LocalWorkspaceAssetErasure(reopened, store);
    await cleanup.flush();
    await cleanup.flush();
    expect(store.deleted, ['owned']);
    expect(
      await reopened.select(reopened.workspaceAssetDeletions).get(),
      isEmpty,
    );
  });

  test('outer rollback never erases workspace asset bytes', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final store = _Store();
    final repository = WorkspaceRepository(
      database,
      attachmentFileStore: store,
    );
    final workspace = await repository.createWorkspace(
      const .new(name: 'One', type: .local),
    );
    await _asset(database, workspace.id, 'owned');
    await expectLater(
      database.transaction(() async {
        expect(await repository.deleteWorkspace(workspace.id), isTrue);
        throw StateError('Rollback the outer mutation');
      }),
      throwsStateError,
    );
    await LocalWorkspaceAssetErasure(database, store).flush();
    expect(store.deleted, isEmpty);
    expect(await repository.workspaceExists(workspace.id), isTrue);
    expect(
      (await database.select(database.workspaceAssets).get()).single.id,
      'owned',
    );
  });

  test('queued erasure cannot remove an asset with current metadata', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final store = _Store();
    final repository = WorkspaceRepository(
      database,
      attachmentFileStore: store,
    );
    final workspace = await repository.createWorkspace(
      const .new(name: 'One', type: .local),
    );
    await _asset(database, workspace.id, 'owned');
    final _ = await database
        .into(database.workspaceAssetDeletions)
        .insert(WorkspaceAssetDeletionsCompanion.insert(assetId: 'owned'));
    final cleanup = LocalWorkspaceAssetErasure(database, store);
    await cleanup.flush();
    expect(store.deleted, isEmpty);
    expect(await repository.deleteWorkspace(workspace.id), isTrue);
    await cleanup.flush();
    expect(store.deleted, ['owned']);
  });

  test('top-level workspace deletion flushes committed cleanup jobs', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final store = _Store();
    final repository = WorkspaceRepository(
      database,
      attachmentFileStore: store,
    );
    final workspace = await repository.createWorkspace(
      const .new(name: 'One', type: .local),
    );
    await _asset(database, workspace.id, 'owned');
    final delete = DeleteWorkspaceUseCase(
      repository: repository,
      prepareBackgroundWorkDeletion: (_) => Future<void>.value(),
      restoreBackgroundWorkAfterFailedDeletion: (_) =>
          fail('Deletion should succeed'),
      clearWorkspaceDrafts: (_) => Future<void>.value(),
      cleanupDeletedAssets: LocalWorkspaceAssetErasure(database, store).flush,
    );
    final _ = await delete(id: workspace.id, activeWorkspaceId: null);
    expect(store.deleted, ['owned']);
  });

  test(
    'workspace erasure releases owned hidden bytes after metadata cascade',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final store = _Store();
      final repository = WorkspaceRepository(
        database,
        attachmentFileStore: store,
      );
      final one = await repository.createWorkspace(
        const .new(name: 'One', type: .local),
      );
      final other = await repository.createWorkspace(
        const .new(name: 'Other', type: .local),
      );
      await _asset(database, one.id, 'owned');
      await _asset(database, one.id, 'pending', status: 'pending');
      await _asset(database, other.id, 'other');
      final _ = await database
          .into(database.workspaceFiles)
          .insert(
            WorkspaceFilesCompanion.insert(
              workspaceId: one.id,
              name: 'File',
              assetId: 'owned',
              creationHash: 'original',
            ),
          );
      expect(await repository.deleteWorkspace(one.id), isTrue);
      await LocalWorkspaceAssetCleanup(database, other.id, store).flush();
      expect(store.deleted, unorderedEquals(['owned', 'pending']));
      final retained = await database.select(database.workspaceAssets).get();
      expect(retained.single.id, 'other');
      expect(await repository.deleteWorkspace(one.id), isFalse);
      await LocalWorkspaceAssetCleanup(database, other.id, store).flush();
      expect(store.deleted, hasLength(2));
    },
  );

  Future<void> verifyCredentialErasure() async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    const ownedReference = 'service-credential:owned';
    const sharedReference = 'service-credential:shared';
    const legacyReference = '123e4567-e89b-42d3-a456-426614174000';
    var failOwnedCredential = true;
    final deletedSecureReferences = <String>[];
    final deletedLegacyReferences = <String>[];
    final encryptionService = _MockEncryptionService();
    when(() => encryptionService.deleteCredential(any()))
        .thenAnswer((invocation) async {
          final reference = invocation.positionalArguments.single as String?;
          if (reference == ownedReference && failOwnedCredential) {
            throw StateError('Transient secure-store failure');
          }
          final secureReference = reference;
          if (secureReference != null &&
              secureReference.startsWith('service-credential:')) {
            deletedSecureReferences.add(secureReference);
          }
        });
    final legacyStorage = _MockLegacyApiKeyStorage();
    when(() => legacyStorage.isLegacyReference(any())).thenReturn(false);
    when(() => legacyStorage.isLegacyReference(legacyReference))
        .thenReturn(true);
    when(() => legacyStorage.delete(legacyReference)).thenAnswer((_) {
      deletedLegacyReferences.add(legacyReference);

      return Future<void>.value();
    });
    final credentialErasure = LocalWorkspaceCredentialErasure(
      database,
      encryptionService,
      legacyApiKeyStorage: legacyStorage,
    );
    final repository = WorkspaceRepository(
      database,
      credentialErasure: credentialErasure,
    );
    final workspace = await repository.createWorkspace(
      const .new(name: 'Workspace to erase', type: .local),
    );
    final otherWorkspace = await repository.createWorkspace(
      const .new(name: 'Workspace retaining shared credential', type: .local),
    );
    await _serviceConnection(
      database,
      workspace.id,
      'owned-connection',
      ownedReference,
    );
    await _serviceConnection(
      database,
      workspace.id,
      'legacy-connection',
      legacyReference,
    );
    await _serviceConnection(
      database,
      workspace.id,
      'shared-connection-to-erase',
      sharedReference,
    );
    await _serviceConnection(
      database,
      otherWorkspace.id,
      'shared-connection-to-retain',
      sharedReference,
    );

    expect(await repository.deleteWorkspace(workspace.id), isTrue);
    expect(await repository.getWorkspaceById(workspace.id), isNull);
    expect(
      await credentialErasure.hasPendingForWorkspace(workspace.id),
      isTrue,
    );
    expect(
      (await database.select(database.workspaceCredentialDeletions).get()).map(
        (job) => job.credentialReference,
      ),
      containsAll([ownedReference, sharedReference, legacyReference]),
    );

    await credentialErasure.flush();

    expect(
      (await database.select(database.workspaceCredentialDeletions).get()).map(
        (job) => job.credentialReference,
      ),
      [ownedReference],
    );
    expect(
      await database.select(database.serviceConnections).get(),
      hasLength(1),
    );
    expect(deletedSecureReferences, isEmpty);
    expect(deletedLegacyReferences, [legacyReference]);

    failOwnedCredential = false;
    await credentialErasure.flush();

    expect(
      await database.select(database.workspaceCredentialDeletions).get(),
      isEmpty,
    );
    expect(deletedSecureReferences, [ownedReference]);
    expect(deletedLegacyReferences, [legacyReference]);
    expect(
      (await database.select(database.serviceConnections).get()).single.id,
      'shared-connection-to-retain',
    );
  }

  test(
    'credential erasure retries and preserves shared references',
    verifyCredentialErasure,
  );

  test('failed chat attachment deletion remains queued for retry', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final store = _Store()..failFileDeletion = true;
    final repository = WorkspaceRepository(
      database,
      attachmentFileStore: store,
    );
    final workspace = await repository.createWorkspace(
      const .new(name: 'Workspace with chat attachment', type: .local),
    );
    final conversation = await database.conversationDao.insertConversation(
      .new(workspaceId: .new(workspace.id), title: const .new('Conversation')),
    );
    final message = await database.messageDao.insertMessage(
      .new(
        conversationId: .new(conversation.id),
        content: const .new('Attachment'),
        messageType: const .new(MessagesTableType.text),
        isUser: const .new(true),
        status: const .new(MessageTableStatus.sent),
      ),
    );
    const localPath = '/support/chat-attachment.png';
    final _ = await database
        .into(database.messageAttachments)
        .insert(
          MessageAttachmentsCompanion.insert(
            messageId: message.id,
            localPath: localPath,
            fileName: 'chat-attachment.png',
            displayName: const .new('chat-attachment.png'),
            mimeType: 'image/png',
            modality: MessageAttachmentModality.image.name,
            sizeBytes: 10,
          ),
        );

    expect(await repository.deleteWorkspace(workspace.id), isTrue);
    expect(await repository.getWorkspaceById(workspace.id), isNull);
    expect(await database.select(database.messageAttachments).get(), isEmpty);
    expect(
      (await database.select(database.workspaceAttachmentDeletions).get())
          .single
          .localPath,
      localPath,
    );

    final erasure = LocalWorkspaceAssetErasure(database, store);
    await erasure.flush();
    expect(store.deletedFiles, isEmpty);
    expect(await erasure.hasPendingCleanup(workspace.id), isTrue);

    store.failFileDeletion = false;
    await erasure.flush();
    expect(store.deletedFiles, [localPath]);
    expect(
      await database.select(database.workspaceAttachmentDeletions).get(),
      isEmpty,
    );
    expect(await erasure.hasPendingCleanup(workspace.id), isFalse);
  });
}

Future<void> _serviceConnection(
  AppDatabase database,
  String workspaceId,
  String id,
  String credentialReference,
) async {
  final _ = await database
      .into(database.serviceConnections)
      .insert(
        ServiceConnectionsCompanion.insert(
          id: .new(id),
          name: id,
          serviceId: 'test',
          kind: .customHttp,
          authenticationType: .apiKey,
          encryptedAuthValue: .new(credentialReference),
          workspaceId: workspaceId,
        ),
      );
}

Future<void> _asset(
  AppDatabase database,
  String workspaceId,
  String id, {
  String status = 'active',
}) async {
  final _ = await database
      .into(database.workspaceAssets)
      .insert(
        WorkspaceAssetsCompanion.insert(
          id: .new(id),
          workspaceId: workspaceId,
          name: 'notes.txt',
          mimeType: 'text/plain',
          sizeBytes: 5,
          checksum: 'a' * 64,
          status: .new(status),
        ),
      );
}

class _Store extends AttachmentFileStore {
  final deleted = <String>[];
  final deletedFiles = <String>[];
  bool fail = false;
  bool failFileDeletion = false;

  @override
  Future<void> deleteAsset(String id) async {
    if (fail) throw StateError('Transient byte removal failure');
    deleted.add(id);
  }

  @override
  Future<void> deleteFile(String localPath) async {
    if (failFileDeletion) throw StateError('Transient file deletion failure');
    deletedFiles.add(localPath);
  }
}

class _RacingStore extends _Store {
  new({required this.bytesBefore});
  final bool bytesBefore;
  final stored = <String>{};
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> writeAsset(String id, Uint8List bytes) async {
    if (bytesBefore) {
      final _ = stored.add(id);
    }
    started.complete();
    await release.future;
    if (!bytesBefore) {
      final _ = stored.add(id);
    }
  }

  @override
  Future<void> deleteAsset(String id) async {
    await super.deleteAsset(id);
    final _ = stored.remove(id);
  }
}

class _InterruptedStore extends _RacingStore {
  new() : super(bytesBefore: false) {
    release.complete();
  }

  @override
  Future<void> writeAsset(String id, Uint8List bytes) async {
    await super.writeAsset(id, bytes);
    throw StateError('Interrupted byte writer');
  }
}

class _MockEncryptionService extends Mock implements EncryptionService;

class _MockLegacyApiKeyStorage extends Mock implements LegacyApiKeyStorage;
