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
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final path = useState<List<WorkspaceFolder>>([]);

    return _Frame(
      Column(
        children: [
          _Navigation(workspaceId, path),
          if (path.value.lastOrNull case final folder?) Text(folder.name),
          Expanded(child: _Contents(workspaceId, path)),
        ],
      ),
    );
  }
}

class const _Frame(final Widget child) extends StatelessWidget {
  static const _extent = 560.0;

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(width: _extent, height: _extent, child: child),
  );
}

class const _Navigation(
  final String workspaceId,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: _Back(path),
    title: const TextLocale(LocaleKeys.workspace_assets_existing),
    trailing: _Reload(workspaceId, path.value.lastOrNull?.id),
  );
}

class const _Back(final ValueNotifier<List<WorkspaceFolder>> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () => _back(context),
    icon: const Icon(Icons.arrow_back),
  );

  void _back(BuildContext context) {
    final current = path.value;
    if (current.isEmpty) {
      Navigator.of(context).pop();

      return;
    }
    path.value = current.take(current.length - 1).toList();
  }
}

class const _Reload(final String workspaceId, final String? parent)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    onPressed: () => _reload(ref),
    tooltip: LocaleKeys.common_reload.tr(),
    icon: const Icon(Icons.refresh),
  );

  void _reload(WidgetRef ref) {
    ref
      ..invalidate(workspaceFoldersProvider(workspaceId, parent))
      ..invalidate(workspaceFilesProvider(workspaceId, parent));
  }
}

class const _Contents(
  final String workspaceId,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final parent = path.value.lastOrNull?.id;

    return ListView(
      children: [
        _FolderContents(workspaceId, parent, path),
        _FileContents(workspaceId, parent),
      ],
    );
  }
}

class const _FolderContents(
  final String workspaceId,
  final String? parent,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _Folders(
    ref.watch(workspaceFoldersProvider(workspaceId, parent)),
    (folder) => path.value = [...path.value, folder],
  );
}

class const _FileContents(final String workspaceId, final String? parent)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _Files(ref.watch(workspaceFilesProvider(workspaceId, parent)));
}

class const _Folders(
  final AsyncValue<List<WorkspaceFolder>> folders,
  final ValueChanged<WorkspaceFolder> enter,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (folders) {
    AsyncData(:final value) => Column(
      children: [for (final folder in value) _Folder(folder, enter)],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _Folder(
  final WorkspaceFolder folder,
  final ValueChanged<WorkspaceFolder> enter,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: () => enter(folder),
  );
}

class const _Files(final AsyncValue<List<WorkspaceFile>> files)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (files) {
    AsyncData(:final value) => Column(
      children: [for (final file in value) _File(file)],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
}

class const _File(final WorkspaceFile file) extends StatelessWidget {
  Widget? get _status => file.asset == null
      ? const TextLocale(LocaleKeys.workspace_assets_unavailable)
      : null;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.insert_drive_file_outlined),
    title: Text(file.name),
    subtitle: _status,
    enabled: file.asset != null,
    onTap: () => _open(context),
  );

  void _open(BuildContext context) {
    final asset = file.asset;
    if (asset != null) Navigator.of(context).pop(asset);
  }
}
