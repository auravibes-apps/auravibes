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
    final draft = _useDraft();
    final ready = ref.watch(createWorkspaceFileUsecaseProvider(workspaceId));

    return _Form(.new(this, context, ref, state, draft, ready));
  }
}

class const _Draft(
  final ValueNotifier<WorkspaceAssetDraft?> source,
  final ValueNotifier<WorkspaceAsset?> uploaded,
  final String id,
);

_Draft _useDraft() => _Draft(
  useState(null),
  useState(null),
  useMemoized(() => const UuidV7().generate()),
);

class const _Form(final _Actions actions) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _Name(actions),
      _Choose(actions),
      _Source(actions.draft),
      _Create(actions),
      _Readiness(actions),
      _Failure(actions.state.error.value),
    ],
  );
}

class const _Name(final _Actions actions) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: actions.state.name,
    label: const TextLocale(LocaleKeys.workspace_assets_name),
    enabled:
        !actions.state.pending.value && actions.draft.uploaded.value == null,
    identifier: 'workspace_file_name',
  );
}

class const _Choose(final _Actions actions) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: actions.choose,
    child: const TextLocale(LocaleKeys.workspace_assets_choose),
    disabled:
        actions.state.pending.value || actions.draft.uploaded.value != null,
    identifier: 'workspace_file_choose',
  );
}

class const _Source(final _Draft draft) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (draft.source.value case final picked?) Text(picked.name),
      const TextLocale(LocaleKeys.workspace_assets_workspace_readable),
      if (draft.uploaded.value != null)
        const TextLocale(LocaleKeys.workspace_assets_uploaded_retry),
    ],
  );
}

class const _Create(final _Actions actions) extends StatelessWidget {
  bool get _disabled =>
      actions.draft.source.value == null ||
      actions.state.pending.value ||
      !actions.ready.hasValue ||
      actions.ready.isLoading;

  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: actions.create,
    child: const TextLocale(LocaleKeys.workspace_assets_create),
    isLoading: actions.state.pending.value,
    disabled: _disabled,
    identifier: 'workspace_file_create',
  );
}

class const _Readiness(final _Actions actions) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (actions.ready.error) {
    final Object error => Column(
      children: [
        WorkspaceItemFailure(error: error),
        AuraButton(
          onPressed: actions.reload,
          child: const TextLocale(LocaleKeys.common_reload),
          disabled: actions.state.pending.value,
        ),
      ],
    ),
    null => const SizedBox.shrink(),
  };
}

class const _Failure(final Object? error) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (error) {
    final Object value => WorkspaceItemFailure(error: value),
    null => const SizedBox.shrink(),
  };
}

class const _Actions(
  final WorkspaceFileCreation owner,
  final BuildContext context,
  final WidgetRef ref,
  final WorkspaceItemFormState state,
  final _Draft draft,
  final AsyncValue<CreateWorkspaceFileUsecase> ready,
) {
  void reload() {
    ref
      ..invalidate(workspaceAssetRepositoryProvider(owner.workspaceId))
      ..invalidate(workspaceFilesUsecaseProvider(owner.workspaceId))
      ..invalidate(createWorkspaceFileUsecaseProvider(owner.workspaceId));
  }

  void choose() => unawaited(state.run(context, pick));
  void create() => unawaited(state.run(context, save));

  Future<void> pick() async {
    final selected = await ref.read(chooseWorkspaceAssetUsecaseProvider)();
    if (!context.mounted || selected == null) return;
    draft.source.value = selected;
    if (state.name.text.trim().isEmpty) state.name.text = selected.name;
  }

  Future<void> save() async {
    final selected = draft.source.value;
    if (selected == null) return;
    final file = await _store(selected);
    _open(file.id);
  }

  Future<WorkspaceFile> _store(WorkspaceAssetDraft selected) async {
    try {
      return await ready.requireValue(_request(selected));
    } on WorkspaceFileCreationFailure catch (failure) {
      if (context.mounted) draft.uploaded.value = failure.uploaded;
      rethrow;
    }
  }

  WorkspaceFileUpload _request(WorkspaceAssetDraft selected) =>
      WorkspaceFileUpload(
        id: draft.id,
        name: state.name.text,
        source: selected,
        parentId: owner.parentId,
        uploaded: draft.uploaded.value,
      );

  void _open(String id) {
    if (!context.mounted) return;
    ref.invalidate(workspaceFilesProvider(owner.workspaceId, owner.parentId));
    owner.onOpenFile(id);
  }
}
