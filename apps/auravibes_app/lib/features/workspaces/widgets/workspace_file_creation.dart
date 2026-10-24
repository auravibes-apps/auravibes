import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_file_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_form_state.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/v7.dart';

class const WorkspaceFileCreation({
  required final String workspaceId,
  required final String? parentId,
  required final ValueChanged<String> onOpenFile,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = WorkspaceItemFormState.use();
    final source = useState<WorkspaceAssetDraft?>(null);
    final uploaded = useState<WorkspaceAsset?>(null);
    final id = useMemoized(() => const UuidV7().generate());
    final ready = ref.watch(createWorkspaceFileUsecaseProvider(workspaceId));
    final actions = _Actions(
      this,
      context,
      ref,
      state,
      source,
      uploaded,
      id,
      ready,
    );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        AuraInput(
          controller: state.name,
          label: const TextLocale(LocaleKeys.workspace_assets_name),
          enabled: !state.pending.value && uploaded.value == null,
          identifier: 'workspace_file_name',
        ),
        AuraButton(
          onPressed: () => unawaited(state.run(context, actions.pick)),
          child: const TextLocale(LocaleKeys.workspace_assets_choose),
          disabled: state.pending.value || uploaded.value != null,
          identifier: 'workspace_file_choose',
        ),
        if (source.value case final picked?) Text(picked.name),
        const TextLocale(LocaleKeys.workspace_assets_workspace_readable),
        if (uploaded.value != null)
          const TextLocale(LocaleKeys.workspace_assets_uploaded_retry),
        AuraButton(
          onPressed: () => unawaited(state.run(context, actions.save)),
          child: const TextLocale(LocaleKeys.workspace_assets_create),
          isLoading: state.pending.value,
          disabled:
              source.value == null ||
              state.pending.value ||
              !ready.hasValue ||
              ready.isLoading,
          identifier: 'workspace_file_create',
        ),
        if (ready.error case final error?) ...[
          WorkspaceItemFailure(error: error),
          AuraButton(
            onPressed: actions.reload,
            child: const TextLocale(LocaleKeys.common_reload),
            disabled: state.pending.value,
          ),
        ],
        if (state.error.value case final error?)
          WorkspaceItemFailure(error: error),
      ],
    );
  }
}

class const _Actions(
  final WorkspaceFileCreation owner,
  final BuildContext context,
  final WidgetRef ref,
  final WorkspaceItemFormState state,
  final ValueNotifier<WorkspaceAssetDraft?> source,
  final ValueNotifier<WorkspaceAsset?> uploaded,
  final String id,
  final AsyncValue<CreateWorkspaceFileUsecase> ready,
) {
  void reload() {
    ref
      ..invalidate(workspaceAssetRepositoryProvider(owner.workspaceId))
      ..invalidate(workspaceFilesUsecaseProvider(owner.workspaceId))
      ..invalidate(createWorkspaceFileUsecaseProvider(owner.workspaceId));
  }

  Future<void> pick() async {
    final selected = await ref.read(chooseWorkspaceAssetUsecaseProvider)();
    if (!context.mounted || selected == null) return;
    source.value = selected;
    if (state.name.text.trim().isEmpty) state.name.text = selected.name;
  }

  Future<void> save() async {
    final selected = source.value;
    if (selected == null) return;
    final create = ready.requireValue;
    try {
      final file = await create(
        id: id,
        name: state.name.text,
        source: selected,
        parentId: owner.parentId,
        uploaded: uploaded.value,
      );
      if (!context.mounted) return;
      ref.invalidate(workspaceFilesProvider(owner.workspaceId, owner.parentId));
      owner.onOpenFile(file.id);
    } on WorkspaceFileCreationFailure catch (failure) {
      if (context.mounted) uploaded.value = failure.uploaded;
      rethrow;
    }
  }
}
