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
  final bool compact = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(workspaceFileProvider(workspaceId, fileId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!compact) _Back(onBack),
        _Status(this, file),
        if (!compact || file.hasError) _Reload(workspaceId, fileId, file),
      ],
    );
  }
}

class const _Back(final VoidCallback onBack) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.arrow_back),
    title: const TextLocale(LocaleKeys.workspace_assets_file),
    onTap: onBack,
  );
}

class const _Status(
  final WorkspaceFileScreen owner,
  final AsyncValue<WorkspaceFile> file,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (file.isLoading) return const Center(child: CircularProgressIndicator());

    return switch (file) {
      AsyncData(:final value) => _File(owner, value),
      AsyncError(:final error) => WorkspaceItemFailure(error: error),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

class const _Reload(
  final String workspaceId,
  final String fileId,
  final AsyncValue<WorkspaceFile> file,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => _reload(ref),
    child: const TextLocale(LocaleKeys.common_reload),
    identifier: 'workspace_file_reload',
  );

  void _reload(WidgetRef ref) {
    final assetId = file.asData?.value.assetId;
    if (assetId != null) {
      ref.invalidate(workspaceAssetPreviewProvider(workspaceId, assetId));
    }
    ref.invalidate(workspaceFileProvider(workspaceId, fileId));
  }
}

class const _File(final WorkspaceFileScreen owner, final WorkspaceFile file)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      if (!owner.compact) Text(file.name),
      WorkspaceAssetPreviewPanel(
        workspaceId: owner.workspaceId,
        assetId: file.assetId,
      ),
    ],
  );
}
