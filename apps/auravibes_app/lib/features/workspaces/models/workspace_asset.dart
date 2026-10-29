import 'dart:typed_data';

import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceAsset({
  required final String id,
  required final String name,
  required final String mimeType,
  required final int sizeBytes,
  required final String checksum,
});

class const WorkspaceFile({
  required final String id,
  required final String name,
  required final String assetId,
  required final int revision,
  final WorkspaceAsset? asset,
  final String? parentId,
  final bool canManage = true,
});

class const WorkspaceFileDraft({
  required final String id,
  required final String name,
  required final String assetId,
  final String? parentId,
});

enum WorkspaceAssetFailure {
  invalid,
  unavailable,
  denied,
  conflict,
  referenced,
}

class const WorkspaceAssetException(final WorkspaceAssetFailure failure)
    implements Exception {
  String get localizationKey => switch (failure) {
    .denied => LocaleKeys.cloud_errors_permission_denied,
    .conflict => LocaleKeys.cloud_errors_conflict,
    .invalid => LocaleKeys.workspace_assets_invalid,
    .referenced => LocaleKeys.workspace_assets_referenced,
    .unavailable => LocaleKeys.workspace_assets_unavailable,
  };
  @override
  String toString() => 'WorkspaceAssetException(${failure.name})';
}

abstract interface class WorkspaceAssetRepository {
  Future<WorkspaceAsset> upload(String name, Uint8List bytes);
  Future<WorkspaceAsset> asset(String id);
  Future<Uint8List> bytes(String id);
}

abstract interface class WorkspaceFileRepository {
  Future<List<WorkspaceFile>> list({String? parentId});
  Future<WorkspaceFile> file(String id);
  Future<WorkspaceFile> create(
    WorkspaceFileDraft draft, {
    bool sharingApproved = false,
  });
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  });
}

enum WorkspaceAssetPreviewKind { image, text, downloadOnly }

class const WorkspaceAssetPreview({
  required final WorkspaceAsset asset,
  required final Uint8List bytes,
  required final WorkspaceAssetPreviewKind kind,
});
