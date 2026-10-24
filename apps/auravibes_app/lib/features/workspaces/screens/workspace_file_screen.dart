import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceFileScreen({
  required final String workspaceId,
  required final String fileId,
  required final VoidCallback onBack,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(workspaceFileProvider(workspaceId, fileId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: const TextLocale(LocaleKeys.workspace_assets_file),
          onTap: onBack,
        ),
        switch (file) {
          AsyncData(:final value) => _File(this, value),
          AsyncError(:final error) => WorkspaceItemFailure(error: error),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
        },
        AuraButton(
          onPressed: () {
            ref.invalidate(workspaceFileProvider(workspaceId, fileId));
          },
          child: const TextLocale(LocaleKeys.common_reload),
        ),
      ],
    );
  }
}

class const _File(final WorkspaceFileScreen owner, final WorkspaceFile file)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Text(file.name),
      WorkspaceAssetPreviewPanel(
        workspaceId: owner.workspaceId,
        assetId: file.assetId,
      ),
    ],
  );
}
