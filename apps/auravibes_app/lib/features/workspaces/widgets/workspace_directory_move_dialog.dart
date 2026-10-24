import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_directory_move_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/move_workspace_directory_items_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceDirectoryMoveDialog({
  required final String workspaceId,
  required final List<WorkspaceDirectoryMoveItem> items,
  required final ValueChanged<String?> onMoved,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) => _MoveBody(
    this,
    WorkspaceTableActions.use(context),
    useState<List<WorkspaceFolder>>(const []),
  );
}

class const _MoveBody(
  final WorkspaceDirectoryMoveDialog owner,
  final WorkspaceTableAction action,
  final ValueNotifier<List<WorkspaceFolder>> path,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PopScope(
    child: SizedBox(
      width: 480,
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: _MoveContent(this),
    ),
    canPop: !action.pending,
  );
}

class const _MoveContent(final _MoveBody state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const TextLocale(LocaleKeys.workspace_items_move),
        _Navigation(state),
        Expanded(child: SingleChildScrollView(child: _Destinations(state))),
        if (state.action.error case final error?)
          WorkspaceItemFailure(error: error),
        _Actions(state),
      ],
    ),
  );
}

class const _Navigation(final _MoveBody state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final path = state.path.value;

    return Row(
      children: [
        if (path.isNotEmpty)
          AuraIconButton(
            icon: Icons.arrow_back,
            onPressed: _back,
            disabled: state.action.pending,
            identifier: 'directory_destination_back',
          ),
        Expanded(child: _DestinationName(path)),
      ],
    );
  }

  void _back() => state.path.value = state.path.value.sublist(
    0,
    state.path.value.length - 1,
  );
}

class const _Destinations(final _MoveBody state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceFoldersProvider(
      state.owner.workspaceId,
      state.path.value.lastOrNull?.id,
    ),
  )) {
    AsyncData(:final value) => Column(
      children: [
        for (final folder in value.where(_allowed)) _Destination(state, folder),
      ],
    ),
    AsyncError(:final error) => WorkspaceItemFailure(error: error),
    AsyncLoading() => const CircularProgressIndicator(),
  };
  bool _allowed(WorkspaceFolder folder) => !state.owner.items.any(
    (item) => item.key.kind == .folder && item.key.id == folder.id,
  );
}

class const _Destination(final _MoveBody state, final WorkspaceFolder folder)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('directory_destination_${folder.id}'),
    leading: const Icon(Icons.folder_outlined),
    title: Text(folder.name),
    onTap: state.action.pending
        ? null
        : () => state.path.value = [...state.path.value, folder],
  );
}

class const _Actions(final _MoveBody state) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      _Submit(state),
      AuraButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const TextLocale(LocaleKeys.common_cancel),
        disabled: state.action.pending,
      ),
    ],
  );
}

class const _Submit(final _MoveBody state) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref
        .watch(workspaceDirectoryMoveUsecaseProvider(state.owner.workspaceId))
        .isLoading;
    final busy = state.action.pending || loading;

    return _SubmitButton(busy: busy, onPressed: () => _submit(context, ref));
  }

  void _submit(BuildContext context, WidgetRef ref) =>
      unawaited(state.action.run(() => _move(context, ref)));
  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final usecase = await _ready(ref);
    if (!context.mounted) return;
    final destination = state.path.value.lastOrNull?.id;
    await usecase(state.owner.items, destination);
    if (!context.mounted) return;
    state.owner.onMoved(destination);
    Navigator.of(context).pop();
  }

  Future<MoveWorkspaceDirectoryItemsUsecase> _ready(WidgetRef ref) {
    final provider = workspaceDirectoryMoveUsecaseProvider(
      state.owner.workspaceId,
    );
    if (ref.read(provider).hasError) ref.invalidate(provider);

    return ref.read(provider.future);
  }
}

class const _SubmitButton({
  required final bool busy,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.workspace_items_move_here),
    isLoading: busy,
    disabled: busy,
    identifier: 'directory_move_submit',
  );
}

class const _DestinationName(final List<WorkspaceFolder> path)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => path.isEmpty
      ? const TextLocale(LocaleKeys.workspace_items_root)
      : Text(path.last.name);
}
