import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('workspace_items_screen');

class const WorkspaceItemsScreen({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = useState(<WorkspaceFolder>[]);
    final name = useTextEditingController();
    final pending = useState(false);
    final error = useState<Object?>(null);
    final parentId = path.value.lastOrNull?.id;
    final provider = workspaceFoldersProvider(workspaceId, parentId);
    final folders = ref.watch(provider);

    Future<void> create() async {
      if (pending.value) return;
      pending.value = true;
      error.value = null;
      try {
        final usecase = await ref.read(
          workspaceFolderUsecaseProvider(workspaceId).future,
        );
        final _ = await usecase.create(name: name.text, parentId: parentId);
        if (!context.mounted) return;
        name.clear();
        ref.invalidate(provider);
      } on Object catch (failure, stackTrace) {
        _logger.warning(
          'Folder creation failed: ${failure.runtimeType}',
          null,
          stackTrace,
        );
        if (context.mounted) error.value = failure;
      } finally {
        if (context.mounted) pending.value = false;
      }
    }

    return AppScreen(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (path.value.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(path.value.last.name),
              onTap: pending.value
                  ? null
                  : () {
                      path.value = path.value.sublist(0, path.value.length - 1);
                      error.value = null;
                    },
            ),
          AuraInput(
            controller: name,
            label: const TextLocale(LocaleKeys.workspace_items_folder_name),
            enabled: !pending.value,
            onSubmitted: (_) => unawaited(create()),
            identifier: 'workspace_folder_name',
          ),
          AuraButton(
            onPressed: () => unawaited(create()),
            child: const TextLocale(LocaleKeys.workspace_items_create_folder),
            isLoading: pending.value,
            disabled: pending.value,
            identifier: 'workspace_folder_create',
          ),
          if (error.value case final failure?) _FolderFailure(error: failure),
          switch (folders) {
            AsyncData(:final value) when value.isEmpty => const TextLocale(
              LocaleKeys.workspace_items_empty,
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final folder in value)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    onTap: pending.value
                        ? null
                        : () {
                            path.value = [...path.value, folder];
                            error.value = null;
                          },
                  ),
              ],
            ),
            AsyncError(:final error) => _FolderFailure(error: error),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
      appBar: AuraAppBarWithDrawer(
        title: const TextLocale(LocaleKeys.workspace_items_title),
        actions: [
          AuraIconButton(
            icon: Icons.refresh,
            onPressed: () => ref.invalidate(provider),
          ),
        ],
      ),
    );
  }
}

class const _FolderFailure({required final Object error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(switch (error) {
    WorkspaceFolderException(:final localizationKey) => localizationKey,
    _ => CloudAppErrors.localizationKey(error),
  });
}
