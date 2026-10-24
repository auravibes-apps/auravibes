import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Selecting an existing File reuses its stable asset; it never copies bytes.
class const WorkspaceAssetChooser({
  required final String workspaceId,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = useState<List<WorkspaceFolder>>([]);
    final parent = path.value.lastOrNull?.id;
    final folders = ref.watch(workspaceFoldersProvider(workspaceId, parent));
    final files = ref.watch(workspaceFilesProvider(workspaceId, parent));

    return Dialog(
      child: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                onPressed: path.value.isEmpty
                    ? () => Navigator.of(context).pop()
                    : () {
                        path.value = path.value
                            .take(path.value.length - 1)
                            .toList();
                      },
                icon: const Icon(Icons.arrow_back),
              ),
              title: const TextLocale(LocaleKeys.workspace_assets_existing),
              trailing: IconButton(
                onPressed: () => _reload(ref, parent),
                tooltip: LocaleKeys.common_reload.tr(),
                icon: const Icon(Icons.refresh),
              ),
            ),
            if (path.value.lastOrNull case final folder?) Text(folder.name),
            Expanded(
              child: ListView(
                children: [
                  switch (folders) {
                    AsyncData(:final value) => Column(
                      children: [
                        for (final folder in value)
                          ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(folder.name),
                            onTap: () => path.value = [...path.value, folder],
                          ),
                      ],
                    ),
                    AsyncError(:final error) => WorkspaceItemFailure(
                      error: error,
                    ),
                    AsyncLoading() => const CircularProgressIndicator(),
                  },
                  switch (files) {
                    AsyncData(:final value) => _Choices(value),
                    AsyncError(:final error) => WorkspaceItemFailure(
                      error: error,
                    ),
                    AsyncLoading() => const CircularProgressIndicator(),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reload(WidgetRef ref, String? parent) {
    ref
      ..invalidate(workspaceFoldersProvider(workspaceId, parent))
      ..invalidate(workspaceFilesProvider(workspaceId, parent));
  }
}

class const _Choices(final List<WorkspaceFile> files) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final file in files)
        ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(file.name),
          subtitle: file.asset == null
              ? const TextLocale(LocaleKeys.workspace_assets_unavailable)
              : null,
          enabled: file.asset != null,
          onTap: file.asset == null
              ? null
              : () => Navigator.of(context).pop(file.asset),
        ),
    ],
  );
}
