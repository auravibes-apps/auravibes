import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const SharedChatAttachmentImage({
  required final String localPath,
  final double width = 180,
  final double height = 140,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = _location(localPath);
    if (location == null) {
      return ChatAttachmentImage(
        localPath: localPath,
        width: width,
        height: height,
      );
    }

    return SizedBox(width: width, height: height, child: _AssetImage(location));
  }
}

class const _AssetImage(final WorkspaceAssetLocation location)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (location.namespace != ref.watch(appStorageNamespaceProvider)) {
      return const Icon(Icons.broken_image_outlined);
    }
    final value = ref.watch(
      workspaceAssetPreviewProvider(location.workspaceId, location.assetId),
    );
    if (value.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _ImageState(value);
  }
}

class const _ReadyImage(final WorkspaceAssetPreview preview)
    extends StatelessWidget {
  static const _decodeWidth = 640;

  @override
  Widget build(BuildContext context) {
    if (preview.kind != .image) return const Icon(Icons.broken_image_outlined);

    return Image.memory(
      preview.bytes,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
      fit: .cover,
      cacheWidth: _decodeWidth,
    );
  }
}

WorkspaceAssetLocation? _location(String value) {
  try {
    return WorkspaceAssetLocation.parse(value);
  } on WorkspaceAssetException {
    return null;
  }
}

class const _ImageState(final AsyncValue<WorkspaceAssetPreview> state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncData(:final value) => _ReadyImage(value),
    AsyncError() || AsyncLoading() => const Icon(Icons.broken_image_outlined),
  };
}
