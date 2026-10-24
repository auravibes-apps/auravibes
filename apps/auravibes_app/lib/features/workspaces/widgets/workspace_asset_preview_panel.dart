import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceAssetPreviewPanel({
  required final String workspaceId,
  required final String assetId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      workspaceAssetPreviewProvider(workspaceId, assetId),
    );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AuraButton(
            onPressed: () => ref.invalidate(
              workspaceAssetPreviewProvider(workspaceId, assetId),
            ),
            child: const TextLocale(LocaleKeys.common_reload),
            identifier: 'workspace_asset_reload',
          ),
        ),
        if (value.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          switch (value) {
            AsyncData(:final value) => _PreviewContent(this, value),
            AsyncError(:final error) => WorkspaceItemFailure(error: error),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
          },
      ],
    );
  }
}

class const _PreviewContent(
  final WorkspaceAssetPreviewPanel owner,
  final WorkspaceAssetPreview preview,
) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);
    final saved = useState(false);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Text(preview.asset.name),
        Text(preview.asset.mimeType),
        switch (preview.kind) {
          .image => Image.memory(
            preview.bytes,
            errorBuilder: (_, _, _) =>
                const TextLocale(LocaleKeys.workspace_assets_unavailable),
            fit: .contain,
          ),
          .text => _TextPreview(utf8.decode(preview.bytes)),
          .downloadOnly => const TextLocale(
            LocaleKeys.workspace_assets_download_only,
          ),
        },
        AuraButton(
          onPressed: () => unawaited(
            action.run(() async {
              final save = await ref.read(
                saveWorkspaceAssetUsecaseProvider(owner.workspaceId).future,
              );
              final copied = await save(owner.assetId);
              if (context.mounted) saved.value = copied;
            }),
          ),
          child: const TextLocale(LocaleKeys.workspace_assets_save),
          isLoading: action.pending,
          disabled: action.pending,
          identifier: 'workspace_asset_save',
        ),
        if (saved.value) const TextLocale(LocaleKeys.workspace_assets_saved),
        if (action.error case final error?) WorkspaceItemFailure(error: error),
      ],
    );
  }
}

class const _TextPreview(final String value) extends StatelessWidget {
  // Bound rendered text; the explicit save action retains the complete asset.
  static const _maximumPreviewCharacters = 16384;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      SelectableText(
        .fromCharCodes(value.runes.take(_maximumPreviewCharacters)),
      ),
      if (value.runes.length > _maximumPreviewCharacters)
        const TextLocale(LocaleKeys.workspace_assets_text_truncated),
    ],
  );
}
