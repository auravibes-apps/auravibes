import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_chooser.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_preview_panel.dart';
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
    if (restricted) {
      return ListTile(
        title: Text(label),
        subtitle: const TextLocale(LocaleKeys.workspace_assets_unavailable),
      );
    }
    final ids = switch (value) {
      final List<Object?> values => values.whereType<String>().toList(),
      _ => <String>[],
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        CheckboxListTile(
          value: present,
          onChanged: disabled || action.pending
              ? null
              : (enabled) {
                  if (enabled == true) {
                    onChanged(<String>[]);
                  } else {
                    onUnset();
                  }
                },
          title: Text(label),
        ),
        if (present) ...[
          for (final id in ids)
            _AttachmentRow(this, id, ids, pending: action.pending),
          if (!disabled)
            AuraPopupMenuButton(
              items: [
                AuraPopupMenuItem(
                  title: const TextLocale(LocaleKeys.workspace_assets_upload),
                  onTap: action.pending
                      ? null
                      : () => unawaited(
                          action.run(() => _upload(context, ref, ids)),
                        ),
                ),
                AuraPopupMenuItem(
                  title: const TextLocale(LocaleKeys.workspace_assets_existing),
                  onTap: action.pending
                      ? null
                      : () =>
                            unawaited(action.run(() => _choose(context, ids))),
                ),
              ],
              icon: Icons.add,
              tooltip: LocaleKeys.workspace_assets_add.tr(),
            ),
        ],
        if (action.pending) const CircularProgressIndicator(),
        if (action.error case final error?) WorkspaceItemFailure(error: error),
      ],
    );
  }

  Future<void> _upload(
    BuildContext context,
    WidgetRef ref,
    List<String> ids,
  ) async {
    final choose = ref.read(chooseWorkspaceAssetUsecaseProvider);
    final source = await choose();
    if (source == null || !context.mounted) return;
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

class const _AttachmentRow(
  final WorkspaceAttachmentField field,
  final String id,
  final List<String> ids, {
  required final bool pending,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.watch(
      workspaceAssetDescriptorProvider(field.workspaceId, id),
    );

    return ListTile(
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: descriptor.isLoading
          ? const LinearProgressIndicator()
          : switch (descriptor) {
              AsyncData(:final value) => Text(value.name),
              AsyncError() => const TextLocale(
                LocaleKeys.workspace_assets_unavailable,
              ),
              AsyncLoading() => const LinearProgressIndicator(),
            },
      trailing: field.disabled || pending
          ? null
          : IconButton(
              onPressed: () =>
                  field.onChanged(ids.where((value) => value != id).toList()),
              tooltip: LocaleKeys.workspace_assets_remove.tr(),
              icon: const Icon(Icons.close),
            ),
      onTap: () => _preview(context),
    );
  }

  void _preview(BuildContext context) {
    final _ = showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 640,
          height: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: WorkspaceAssetPreviewPanel(
              workspaceId: field.workspaceId,
              assetId: id,
            ),
          ),
        ),
      ),
    );
  }
}
