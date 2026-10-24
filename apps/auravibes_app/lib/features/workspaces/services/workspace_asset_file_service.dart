import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:file_picker/file_picker.dart';

class const WorkspaceAssetFileService() {
  Future<WorkspaceAssetDraft?> pick() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final length = await file.length();
    if (length != null &&
        length > ChatAttachmentModality.maxChatAttachmentBytes) {
      throw const WorkspaceAssetException(.invalid);
    }
    final bytes = await file.readAsBytes();

    return WorkspaceAssetDraft(name: file.name, bytes: bytes);
  }

  Future<bool> save(WorkspaceAssetPreview preview) async {
    final result = await FilePicker.saveFile(
      fileName: preview.asset.name,
      mimeType: preview.asset.mimeType,
      bytes: preview.bytes,
    );

    return result != null;
  }
}
