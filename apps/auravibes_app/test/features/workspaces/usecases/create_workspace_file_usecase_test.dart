import 'dart:typed_data';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_file_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'File retry reuses upload and stable identity after container failure',
    () async {
      final assets = _Assets();
      final files = _Files();
      final create = CreateWorkspaceFileUsecase(.new(assets), .new(files));
      final source = WorkspaceAssetDraft(
        name: 'notes.txt',
        bytes: .fromList('hello'.codeUnits),
      );
      WorkspaceAsset? uploaded;
      try {
        final _ = await create(
          .new(
            id: 'stable-file',
            name: 'Notes',
            source: source,
            parentId: null,
          ),
        );
        fail('Expected a recoverable container failure');
      } on WorkspaceFileCreationFailure catch (failure) {
        uploaded = failure.uploaded;
      }
      expect(uploaded, isNotNull);
      final retried = await create(
        .new(
          id: 'stable-file',
          name: 'Notes',
          source: source,
          parentId: null,
          uploaded: uploaded,
        ),
      );
      expect(retried.id, 'stable-file');
      expect(retried.assetId, 'asset');
      expect(files.ids, ['stable-file', 'stable-file']);
      expect(assets.uploads, 1);
      await expectLater(
        create(.new(id: 'invalid', name: ' ', source: source, parentId: null)),
        throwsA(isA<WorkspaceAssetException>()),
      );
      expect(assets.uploads, 1);
    },
  );
}

class _Assets implements WorkspaceAssetRepository {
  int uploads = 0;
  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) async {
    uploads++;

    return WorkspaceAsset(
      id: 'asset',
      name: name,
      mimeType: 'text/plain',
      sizeBytes: bytes.length,
      checksum: 'unused',
    );
  }

  @override
  Future<WorkspaceAsset> asset(String id) => throw UnimplementedError();
  @override
  Future<Uint8List> bytes(String id) => throw UnimplementedError();
}

class _Files implements WorkspaceFileRepository {
  final ids = <String>[];
  @override
  Future<WorkspaceFile> create(
    WorkspaceFileDraft draft, {
    bool sharingApproved = false,
  }) async {
    final id = draft.id;
    final name = draft.name;
    final assetId = draft.assetId;
    ids.add(id);
    if (ids.length == 1) throw const WorkspaceAssetException(.unavailable);

    return WorkspaceFile(id: id, name: name, assetId: assetId, revision: 1);
  }

  @override
  Future<WorkspaceFile> file(String id) => throw UnimplementedError();
  @override
  Future<List<WorkspaceFile>> list({String? parentId}) =>
      throw UnimplementedError();
  @override
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) => throw UnimplementedError();
}
