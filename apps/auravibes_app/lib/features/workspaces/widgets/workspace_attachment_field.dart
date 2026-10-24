import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_draft.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_chooser.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceAttachmentField({
  required final String workspaceId,
  required final String label,
  required final Object? value,
  required final bool present,
  required final bool disabled,
  required final bool restricted,
  required final ValueChanged<Object?> onChanged,
  required final VoidCallback onUnset,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);
    if (restricted) return _RestrictedAttachment(label);

    return _AttachmentContent(this, action, _ids(value));
  }

  Future<void> _upload(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final choose = ref.read(chooseWorkspaceAssetUsecaseProvider);
    final source = await choose();
    if (source == null || !context.mounted) return;
    await _uploadAsset(context, ref, source, ids);
  }

  Future<void> _uploadAsset(
    BuildContext context,
    WidgetRef ref,
    WorkspaceAssetDraft source,
    List<String> ids,
  ) async {
    final assets = await ref.read(
      workspaceAssetsUsecaseProvider(workspaceId).future,
    );
    final asset = await assets.upload(source.name, source.bytes);
    if (context.mounted) _add(ids, asset);
  }

  Future<void> _choose(BuildContext context, List<String> ids) async {
    final asset = await showDialog<WorkspaceAsset>(
      context: context,
      builder: (_) => WorkspaceAssetChooser(workspaceId: workspaceId),
    );
    if (asset != null && context.mounted) _add(ids, asset);
  }

  void _add(List<String> ids, WorkspaceAsset asset) =>
      onChanged([...ids.toSet(), if (!ids.contains(asset.id)) asset.id]);
}

class const _RestrictedAttachment(final String label) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: const TextLocale(LocaleKeys.workspace_assets_unavailable),
  );
}

class const _AttachmentContent(
  final WorkspaceAttachmentField field,
  final WorkspaceTableAction action,
  final List<String> ids,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _AttachmentPresence(field, pending: action.pending),
      if (field.present) _AttachmentValues(field, action, ids),
      _AttachmentStatus(action),
    ],
  );
}

class const _AttachmentPresence(
  final WorkspaceAttachmentField field, {
  required final bool pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: field.present,
    onChanged: field.disabled || pending ? null : _toggle,
    title: Text(field.label),
  );

  void _toggle(bool? enabled) {
    if (enabled == true) {
      field.onChanged(<String>[]);
    } else {
      field.onUnset();
    }
  }
}

class const _AttachmentValues(
  final WorkspaceAttachmentField field,
  final WorkspaceTableAction action,
  final List<String> ids,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _AttachmentRows(field, ids, pending: action.pending),
      if (!field.disabled) _AttachmentAdd(field, action, ids),
    ],
  );
}

class const _AttachmentRows(
  final WorkspaceAttachmentField field,
  final List<String> ids, {
  required final bool pending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final id in ids) _AttachmentRow(field, id, ids, pending: pending),
    ],
  );
}

class const _AttachmentStatus(final WorkspaceTableAction action)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (action.pending) const CircularProgressIndicator(),
      if (action.error case final error?) WorkspaceItemFailure(error: error),
    ],
  );
}

class const _AttachmentAdd(
  final WorkspaceAttachmentField field,
  final WorkspaceTableAction action,
  final List<String> ids,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraPopupMenuButton(
    items: [_uploadMenu(context, ref), _chooseMenu(context)],
    icon: Icons.add,
    tooltip: LocaleKeys.workspace_assets_add.tr(),
  );

  AuraPopupMenuItem _uploadMenu(BuildContext context, WidgetRef ref) =>
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_assets_upload),
        onTap: action.pending ? null : () => _upload(context, ref),
      );

  AuraPopupMenuItem _chooseMenu(BuildContext context) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_assets_existing),
    onTap: action.pending ? null : () => _choose(context),
  );

  void _upload(BuildContext context, WidgetRef ref) =>
      unawaited(action.run(() => field._upload(context, ref, ids)));
  void _choose(BuildContext context) =>
      unawaited(action.run(() => field._choose(context, ids)));
}

List<String> _ids(Object? value) =>
    value is List ? value.whereType<String>().toList() : [];

class const _AttachmentRow(
  final WorkspaceAttachmentField field,
  final String id,
  final List<String> ids, {
  required final bool pending,
}) extends ConsumerWidget {
  bool get _canRemove => !field.disabled && !pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.insert_drive_file_outlined),
    title: _AssetName(field.workspaceId, id),
    trailing: _canRemove ? _RemoveAsset(field, id, ids) : null,
    onTap: () => _preview(context, ref),
  );

  void _preview(BuildContext context, WidgetRef ref) {
    ref.invalidate(workspaceAssetPreviewProvider(field.workspaceId, id));
    unawaited(
      WorkspaceAssetPreviewDialog.show(
        context,
        workspaceId: field.workspaceId,
        assetId: id,
      ),
    );
  }
}

class const _AssetName(final String workspaceId, final String id)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(workspaceAssetDescriptorProvider(workspaceId, id));
    if (value.isLoading) return const LinearProgressIndicator();

    return _NameValue(value);
  }
}

class const _NameValue(final AsyncValue<WorkspaceAsset> state)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncData(:final value) => Text(value.name),
    AsyncError() ||
    AsyncLoading() => const TextLocale(LocaleKeys.workspace_assets_unavailable),
  };
}

class const _RemoveAsset(
  final WorkspaceAttachmentField field,
  final String id,
  final List<String> ids,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () =>
        field.onChanged(ids.where((value) => value != id).toList()),
    tooltip: LocaleKeys.workspace_assets_remove.tr(),
    icon: const Icon(Icons.close),
  );
}
