import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_input.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef WorkspaceAssetUpload = Future<ObjectResult> Function({
  required MessageAttachmentToCreate attachment,
  required Uint8List bytes,
});
typedef WorkspaceAssetDownload = Future<Uri> Function({required int objectId});
typedef WorkspaceAssetBytes = Future<Uint8List> Function(
  Uri uri,
  int sizeBytes,
);

class const CloudWorkspaceAssetRepository({
  required final CloudWorkspaceStateGateway gateway,
  required final WorkspaceAssetUpload uploadBytes,
  required final WorkspaceAssetDownload getDownload,
  required final WorkspaceAssetBytes fetchBytes,
}) implements WorkspaceAssetRepository {
  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) async {
    final mime = WorkspaceAssetInput.validate(name, bytes);
    final uploaded = await uploadBytes(
      attachment: MessageAttachmentToCreate(
        localPath: '',
        fileName: name,
        displayName: name,
        mimeType: mime,
        modality: ChatAttachmentModality.forMimeType(mime),
        sizeBytes: bytes.length,
      ),
      bytes: bytes,
    );

    return _asset(uploaded);
  }

  @override
  Future<WorkspaceAsset> asset(String id) =>
      CloudAppErrors.guardCall(.object, () async {
        final objectId = _id(id);
        final result = await gateway.client.object.describe(
          .new(
            workspaceId: gateway.workspace.cloudWorkspaceId,
            objectId: objectId,
          ),
        );
        if (result.objectId != objectId) {
          throw const WorkspaceAssetException(.invalid);
        }

        return _asset(result);
      });

  @override
  Future<Uint8List> bytes(String id) async {
    final metadata = await asset(id);
    final uri = await getDownload(objectId: _id(id));

    return await fetchBytes(uri, metadata.sizeBytes);
  }

  WorkspaceAsset _asset(ObjectResult object) {
    if (object.workspaceId != gateway.workspace.cloudWorkspaceId ||
        object.sizeBytes <= 0 ||
        object.objectId <= 0 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(object.checksumSha256)) {
      throw const WorkspaceAssetException(.invalid);
    }

    return WorkspaceAsset(
      id: '${object.objectId}',
      name: object.displayName,
      mimeType: object.mimeType,
      sizeBytes: object.sizeBytes,
      checksum: object.checksumSha256,
    );
  }
}

int _id(String id) {
  final value = int.tryParse(id);
  if (value == null || value <= 0) throw const WorkspaceAssetException(.denied);

  return value;
}
