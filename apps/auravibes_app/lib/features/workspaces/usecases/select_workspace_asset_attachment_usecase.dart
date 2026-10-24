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
    final location = WorkspaceAssetLocation.create(
      namespace: scope.namespace,
      workspaceId: scope.workspaceId,
      assetId: asset.id,
    );

    return MessageAttachmentToCreate(
      assetId: asset.id,
      localPath: location.location,
      fileName: asset.name,
      displayName: asset.name,
      mimeType: asset.mimeType,
      modality: ChatAttachmentModality.forMimeType(asset.mimeType),
      sizeBytes: asset.sizeBytes,
    );
  }
}
