import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _pickerExtent = 400.0;

class const WorkspaceViewChatButton({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraIconButton(
    icon: Icons.dashboard_outlined,
    onPressed: () => unawaited(_pick(context, ref)),
    tooltip: LocaleKeys.workspace_views_title.tr(),
  );
  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _ViewPicker(workspaceId),
    );
    if (!context.mounted || id == null) return;
    ref
            .read(
              workspaceOpenViewProvider(workspaceId, conversationId).notifier,
            )
            .selected =
        id;
  }
}

class const _ViewPicker(final String workspaceId) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(LocaleKeys.workspace_views_title),
    content: SizedBox(
      width: _pickerExtent,
      height: _pickerExtent,
      child: _Choices(workspaceId),
    ),
  );
}

class const _Choices(final String workspaceId) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(workspaceViewChoicesProvider(workspaceId))) {
        AsyncData(:final value) => _Views(value),
        AsyncError(:final error) => WorkspaceItemFailure(error: error),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      };
}

class const _Views(final List<WorkspaceView> views) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => views.isEmpty
      ? const TextLocale(LocaleKeys.workspace_views_no_views)
      : ListView(children: [for (final view in views) _View(view)]);
}

class const _View(final WorkspaceView view) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(view.name),
    onTap: () => Navigator.of(context).pop(view.id),
  );
}
