import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_history.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _Selection = ({String mode, WorkspaceViewData data});
const _maximumVisibleRecords = 100;
const _refreshInterval = Duration(seconds: 10);

class const WorkspaceViewScreen({
  required final String workspaceId,
  required final String viewId,
  required final VoidCallback onBack,
  super.key,
}) extends HookConsumerWidget {
  void refresh(WidgetRef ref) =>
      ref.invalidate(workspaceViewDataProvider(workspaceId, viewId));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<_Selection?>(null);
    _useRefresh(ref, selected);

    return Column(
      children: [
        _Toolbar(this, selected),
        Expanded(child: _Contents(this, selected)),
      ],
    );
  }

  void _useRefresh(WidgetRef ref, ValueNotifier<_Selection?> selected) =>
      useEffect(() {
        final timer = Timer.periodic(_refreshInterval, (_) {
          if (selected.value == null) refresh(ref);
        });

        return timer.cancel;
      }, [workspaceId, viewId]);
}

class const _Toolbar(
  final WorkspaceViewScreen owner,
  final ValueNotifier<_Selection?> selected,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: owner.onBack,
        identifier: 'workspace_view_back',
        tooltip: LocaleKeys.common_back.tr(),
      ),
      const Expanded(child: TextLocale(LocaleKeys.workspace_views_title)),
      AuraIconButton(
        icon: Icons.refresh,
        onPressed: () => owner.refresh(ref),
        identifier: 'workspace_view_refresh',
        tooltip: LocaleKeys.common_reload.tr(),
      ),
      _Menu(owner, selected),
    ],
  );
}

class const _Menu(
  final WorkspaceViewScreen owner,
  final ValueNotifier<_Selection?> selected,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = _data(ref);
    if (data == null || !data.table.canManage) return const SizedBox.shrink();

    return _Popup(data, selected);
  }

  WorkspaceViewData? _data(WidgetRef ref) => ref
      .watch(workspaceViewDataProvider(owner.workspaceId, owner.viewId))
      .value;
}

class const _Popup(
  final WorkspaceViewData data,
  final ValueNotifier<_Selection?> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    itemBuilder: _items,
    onSelected: (mode) => selected.value = (mode: mode, data: data),
  );

  List<PopupMenuEntry<String>> _items(BuildContext _) => [
    const PopupMenuItem(
      value: 'edit',
      child: TextLocale(LocaleKeys.workspace_views_edit),
    ),
    const PopupMenuItem(
      value: 'history',
      child: TextLocale(LocaleKeys.workspace_views_history),
    ),
  ];
}

class const _Contents(
  final WorkspaceViewScreen owner,
  final ValueNotifier<_Selection?> selected,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = selected.value;
    if (selection != null) return _Selected(owner, selection, () => _done(ref));

    return _LoadState(owner);
  }

  void _done(WidgetRef ref) {
    selected.value = null;
    owner.refresh(ref);
  }
}

class const _LoadState(final WorkspaceViewScreen owner) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    workspaceViewDataProvider(owner.workspaceId, owner.viewId),
  )) {
    AsyncData(:final value) => _Content(value),
    AsyncError(:final error) => Center(
      child: WorkspaceItemFailure(error: error),
    ),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _Selected(
  final WorkspaceViewScreen owner,
  final _Selection selection,
  final VoidCallback done,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => selection.mode == 'history'
      ? WorkspaceViewHistory(
          workspaceId: owner.workspaceId,
          current: selection.data.view,
          onDone: done,
        )
      : WorkspaceViewEditor(
          workspaceId: owner.workspaceId,
          data: selection.data,
          onDone: done,
        );
}

class const _Content(final WorkspaceViewData data) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(data.view.name),
      const TextLocale(LocaleKeys.workspace_views_display_only),
      _Surface(data),
      _Limit(data),
    ],
  );
}

class const _Surface(final WorkspaceViewData data) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (data.needsRepair) {
      return const TextLocale(LocaleKeys.workspace_views_repair);
    }
    if (data.records.isEmpty) {
      return const TextLocale(LocaleKeys.workspace_views_empty);
    }

    return WorkspaceViewSurface(data: data);
  }
}

class const _Limit(final WorkspaceViewData data) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      data.records.length >= _maximumVisibleRecords
      ? const TextLocale(LocaleKeys.workspace_views_limit)
      : const SizedBox.shrink();
}
