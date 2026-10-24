import 'dart:async';

import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_dialog.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ChatSharedAsset({
  required final String workspaceId,
  required final String assetId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      workspaceAssetDescriptorProvider(workspaceId, assetId),
    );
    if (value.isLoading) return const CircularProgressIndicator();

    return switch (value) {
      AsyncData(:final value) => _ReadyAsset(this, value),
      AsyncError() || AsyncLoading() => const Chip(
        label: TextLocale(LocaleKeys.workspace_assets_unavailable),
      ),
    };
  }
}

class const _ReadyAsset(final ChatSharedAsset owner, final WorkspaceAsset asset)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (asset.mimeType.startsWith('image/')) {
      return InkWell(
        child: _AssetPicture(owner),
        onTap: () => _open(context, ref),
      );
    }

    return ActionChip(
      avatar: const Icon(Icons.insert_drive_file_outlined),
      label: Text(asset.name),
      onPressed: () => _open(context, ref),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    ref.invalidate(
      workspaceAssetPreviewProvider(owner.workspaceId, owner.assetId),
    );
    unawaited(
      WorkspaceAssetPreviewDialog.show(
        context,
        workspaceId: owner.workspaceId,
        assetId: owner.assetId,
      ),
    );
  }
}

class const _AssetPicture(final ChatSharedAsset owner) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ChatAttachmentImage(
    localPath: WorkspaceAssetLocation.create(
      namespace: ref.watch(appStorageNamespaceProvider),
      workspaceId: owner.workspaceId,
      assetId: owner.assetId,
    ).location,
  );
}
