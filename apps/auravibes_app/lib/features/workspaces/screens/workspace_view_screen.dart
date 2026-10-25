import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_connected_view_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_data.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_duplication_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_chart.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_detail.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_history.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_summary.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_surface.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _Selection = ({String mode, WorkspaceViewData data});
const _refreshInterval = Duration(seconds: 10);

class const WorkspaceViewScreen({
  required final String workspaceId,
  required final String viewId,
  required final VoidCallback onBack,
  super.key,
}) extends StatelessWidget {
  void refresh(WidgetRef ref) {
    ref.invalidate(workspaceConnectedViewProvider(workspaceId, viewId));
    ref.invalidate(workspaceViewDataProvider);
  }

  @override
  Widget build(BuildContext context) => _ViewSession(
    this,
    key: ValueKey((workspaceId: workspaceId, viewId: viewId)),
  );
}

class const _ViewSession(final WorkspaceViewScreen owner, {super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<_Selection?>(null);
    _useRefresh(ref, selected);

    return Column(
      children: [
        _Toolbar(owner, selected),
        Expanded(child: _Contents(owner, selected)),
      ],
    );
  }

  void _useRefresh(WidgetRef ref, ValueNotifier<_Selection?> selected) =>
      useEffect(() => _subscribe(ref, selected), [
        owner.workspaceId,
        owner.viewId,
      ]);

  VoidCallback _subscribe(WidgetRef ref, ValueNotifier<_Selection?> selected) {
    final timer = Timer.periodic(_refreshInterval, (_) {
      if (selected.value == null) owner.refresh(ref);
    });

    return timer.cancel;
  }
}

class const _Toolbar(
  final WorkspaceViewScreen owner,
  final ValueNotifier<_Selection?> selected,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      _BackButton(owner),
      const Expanded(child: TextLocale(LocaleKeys.workspace_views_title)),
      _RefreshButton(owner),
      _Menu(owner, selected),
    ],
  );
}

class const _BackButton(final WorkspaceViewScreen owner)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: owner.onBack,
    identifier: 'workspace_view_back',
    tooltip: LocaleKeys.common_back.tr(),
  );
}

class const _RefreshButton(final WorkspaceViewScreen owner)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraIconButton(
    icon: Icons.refresh,
    onPressed: () => owner.refresh(ref),
    identifier: 'workspace_view_refresh',
    tooltip: LocaleKeys.common_reload.tr(),
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

    return _Popup(owner.workspaceId, data, selected);
  }

  WorkspaceViewData? _data(WidgetRef ref) => ref
      .watch(workspaceViewDataProvider(owner.workspaceId, owner.viewId))
      .value;
}

class const _Popup(
  final String workspaceId,
  final WorkspaceViewData data,
  final ValueNotifier<_Selection?> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    itemBuilder: _items,
    onSelected: (mode) => _select(context, mode),
  );

  void _select(BuildContext context, String mode) {
    if (mode == 'duplicate') {
      unawaited(
        WorkspaceItemDuplicationActions.open(context, workspaceId, data.view),
      );
    } else {
      selected.value = (mode: mode, data: data);
    }
  }

  List<PopupMenuEntry<String>> _items(BuildContext _) => [
    const PopupMenuItem(
      value: 'connected',
      child: TextLocale(LocaleKeys.workspace_connected_configure),
    ),
    const PopupMenuItem(
      value: 'edit',
      child: TextLocale(LocaleKeys.workspace_views_edit),
    ),
    const PopupMenuItem(
      value: 'duplicate',
      child: TextLocale(LocaleKeys.workspace_items_duplicate),
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

class const _LoadState(final WorkspaceViewScreen owner)
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = useState(0);
    final state = ref.watch(
      workspaceViewDataProvider(
        owner.workspaceId,
        owner.viewId,
        offset: offset.value,
      ),
    );

    return Column(
      children: [
        if (state.value?.view.isConnectedOnly != true)
          Expanded(child: _PageState(state, offset)),
        if (state.value?.view.connected != null)
          Flexible(
            child: SingleChildScrollView(
              child: WorkspaceConnectedData(
                workspaceId: owner.workspaceId,
                viewId: owner.viewId,
                data: state.value,
              ),
            ),
          ),
      ],
    );
  }
}

class const _PageState(
  final AsyncValue<WorkspaceViewData> state,
  final ValueNotifier<int> offset,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return _Waiting(stale: state.hasValue);

    return switch (state) {
      AsyncData(:final value) => _Page(value, offset),
      AsyncError(:final error) => Center(
        child: WorkspaceItemFailure(error: error),
      ),
      AsyncLoading() => const _Waiting(stale: false),
    };
  }
}

class const _Waiting({required final bool stale}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      children: [
        const CircularProgressIndicator(),
        TextLocale(
          stale
              ? LocaleKeys.workspace_relational_stale
              : LocaleKeys.workspace_relational_loading,
        ),
      ],
    ),
  );
}

class const _Page(final WorkspaceViewData data, final ValueNotifier<int> offset)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: _Content(data)),
      _Pages(data, offset),
    ],
  );
}

class const _Pages(
  final WorkspaceViewData data,
  final ValueNotifier<int> offset,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => data.needsRepair
      ? const SizedBox.shrink()
      : Wrap(
          spacing: 8,
          children: [
            _Previous(data, offset),
            _PageRange(data),
            _Next(data, offset),
          ],
        );
}

class const _PageRange(final WorkspaceViewData data) extends StatelessWidget {
  int get _start => data.records.isEmpty ? 0 : data.offset + 1;
  int get _end => data.records.isEmpty ? 0 : data.offset + data.records.length;
  @override
  Widget build(BuildContext context) => Text('$_start - $_end');
}

class const _Previous(
  final WorkspaceViewData data,
  final ValueNotifier<int> offset,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: _previous,
    child: const TextLocale(LocaleKeys.workspace_relational_previous),
    disabled: offset.value == 0,
    identifier: 'workspace_view_previous',
  );
  void _previous() => offset.value = (offset.value - data.view.query.limit)
      .clamp(0, offset.value);
}

class const _Next(final WorkspaceViewData data, final ValueNotifier<int> offset)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: _next,
    child: const TextLocale(LocaleKeys.workspace_relational_next),
    disabled: !data.hasMore,
    identifier: 'workspace_view_next',
  );
  void _next() => offset.value += data.view.query.limit;
}

class const _Selected(
  final WorkspaceViewScreen owner,
  final _Selection selection,
  final VoidCallback done,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      selection.mode == 'connected' ||
          (selection.mode == 'edit' && selection.data.view.isConnectedOnly)
      ? WorkspaceConnectedEditor(
          workspaceId: owner.workspaceId,
          view: selection.data.view,
          onDone: done,
        )
      : selection.mode == 'history'
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

class const _Content(final WorkspaceViewData data) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selected = useState<String?>(null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(data.view.name),
        const TextLocale(LocaleKeys.workspace_views_display_only),
        _DataSurface(data, selected),
        WorkspaceViewSummary(data: data),
      ],
    );
  }
}

class const _DataSurface(
  final WorkspaceViewData data,
  final ValueNotifier<String?> selected,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _isDetail(data) && !data.needsRepair
      ? WorkspaceViewDetail(data: data, selected: selected)
      : _Surface(data);
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

    if (data.view.definition.components.any(_boundChart)) {
      return WorkspaceViewChart(data: data);
    }

    return WorkspaceViewSurface(data: data);
  }
}

bool _isDetail(WorkspaceViewData data) => data.view.definition.components.any(
  (component) => component['id'].toString().startsWith('detail_'),
);

bool _boundChart(Map<String, Object?> component) => switch (component) {
  {
    'component': 'Chart',
    'labels': {'path': '/chartLabels'},
    'series': {'path': '/chartSeries'},
  } =>
    true,
  _ => false,
};
