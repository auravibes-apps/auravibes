import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_assets_usecase.dart';

class const SelectWorkspaceAssetAttachmentUsecase(
  final ManageWorkspaceAssetsUsecase assets,
  final ({String namespace, String workspaceId}) scope,
) {
  Future<MessageAttachmentToCreate> call(String assetId) async {
    final asset = await assets.describe(assetId);
    if (asset.id != assetId) throw const WorkspaceAssetException(.invalid);

    return _attachment(asset);
  }

  MessageAttachmentToCreate _attachment(WorkspaceAsset asset) {
    final name = asset.name;

    return MessageAttachmentToCreate(
      localPath: _location(asset.id),
      fileName: name,
      displayName: name,
      mimeType: asset.mimeType,
      modality: ChatAttachmentModality.forMimeType(asset.mimeType),
      sizeBytes: asset.sizeBytes,
      assetId: asset.id,
    );
  }

  String _location(String id) => WorkspaceAssetLocation.create(
    namespace: scope.namespace,
    workspaceId: scope.workspaceId,
    assetId: id,
  ).location;
}
