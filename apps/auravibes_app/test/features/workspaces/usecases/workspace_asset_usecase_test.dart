import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_file_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_files_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  test('uploaded local asset survives database and storage reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'workspace-assets-',
    );
    final channel =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    channel.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => directory.path,
    );
    addTearDown(() async {
      channel.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      final _ = await directory.delete(recursive: true);
    });
    final file = File('${directory.path}/data.sqlite');
    final database = AppDatabase(connection: NativeDatabase(file));
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('local'),
            name: 'Local',
            type: .local,
          ),
        );
    const store = AttachmentFileStore(storageNamespace: 'asset-test');
    final repository = ManageWorkspaceAssetsUsecase(
      LocalWorkspaceAssetRepository(database, 'local', store),
    );
    final asset = await repository.upload(
      'notes.txt',
      .fromList('hello'.codeUnits),
    );
    expect(asset.name, 'notes.txt');
    expect(asset.mimeType, 'text/plain');
    expect(asset.sizeBytes, 5);
    await database.close();
    final reopened = AppDatabase(connection: NativeDatabase(file));
    addTearDown(reopened.close);
    final next = ManageWorkspaceAssetsUsecase(
      LocalWorkspaceAssetRepository(reopened, 'local', store),
    );
    final preview = await next.preview(asset.id);
    expect(
      preview.asset.checksum,
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
    expect(preview.bytes, 'hello'.codeUnits);
    final files = OrganizeWorkspaceFilesUsecase(
      LocalWorkspaceFileRepository(
        reopened,
        'local',
        LocalWorkspaceAssetRepository(reopened, 'local', store),
      ),
    );
    final first = await files.create(name: 'First', assetId: asset.id);
    final second = await files.create(name: 'Second', assetId: asset.id);
    expect(first.id, isNot(second.id));
    expect(second.asset.id, first.asset.id);
    final renamed = await files.updateMetadata(
      file: first,
      name: 'Renamed',
      parentId: null,
    );
    expect(renamed.id, first.id);
    expect(renamed.asset.id, asset.id);
    final _ = await expectLater(
      files.updateMetadata(file: first, name: 'Stale', parentId: null),
      throwsA(
        isA<WorkspaceAssetException>().having(
          (error) => error.failure,
          'failure',
          WorkspaceAssetFailure.conflict,
        ),
      ),
    );
    final _ = await expectLater(
      () => next.upload(
        'active.html',
        .fromList('<script>alert(1)</script>'.codeUnits),
      ),
      throwsA(isA<WorkspaceAssetException>()),
    );
    final _ = await reopened
        .into(reopened.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const .new('other'),
            name: 'Other',
            type: .local,
          ),
        );
    final other = ManageWorkspaceAssetsUsecase(
      LocalWorkspaceAssetRepository(reopened, 'other', store),
    );
    final _ = await expectLater(
      other.preview(asset.id),
      throwsA(isA<WorkspaceAssetException>()),
    );
    await store.writeAsset(asset.id, .fromList('wrong'.codeUnits));
    final _ = await expectLater(
      next.preview(asset.id),
      throwsA(
        isA<WorkspaceAssetException>().having(
          (error) => error.failure,
          'failure',
          WorkspaceAssetFailure.invalid,
        ),
      ),
    );
  });
}
