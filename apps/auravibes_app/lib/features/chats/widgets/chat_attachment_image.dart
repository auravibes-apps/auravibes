import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'chat_attachment_image_web.dart'
    if (dart.library.io) 'chat_attachment_image_io.dart'
    as platform;

class const ChatAttachmentImage({
  required final String localPath,
  final double width = 180,
  final double height = 140,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = _location(localPath);
    if (location == null) {
      return platform.ChatAttachmentImage(
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
  static const _decodeWidth = 640;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (location.namespace != ref.watch(appStorageNamespaceProvider)) {
      return _unavailable();
    }
    final value = ref.watch(
      workspaceAssetPreviewProvider(location.workspaceId, location.assetId),
    );
    if (value.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return switch (value) {
      AsyncData(:final value) => _image(value),
      _ => _unavailable(),
    };
  }

  Widget _image(WorkspaceAssetPreview preview) {
    if (preview.kind != .image) return _unavailable();

    return Image.memory(
      preview.bytes,
      fit: .cover,
      cacheWidth: _decodeWidth,
      errorBuilder: (_, _, _) => _unavailable(),
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

Widget _unavailable() => const Icon(Icons.broken_image_outlined);
