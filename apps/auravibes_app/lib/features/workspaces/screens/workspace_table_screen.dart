import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_references_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_column_type_label.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_csv_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_duplication_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_browser.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_access_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_actions.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_actions.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceTableScreen({
  required final String workspaceId,
  required final String tableId,
  required final VoidCallback onBack,
  final bool compact = false,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final draftOpen = useState(false);

    return PopScope(
      child: compact
          ? _TableState(screen: this, draftOpen: draftOpen)
          : AppScreen(
              child: _TableState(screen: this, draftOpen: draftOpen),
              appBar: _TableToolbar(screen: this, draftOpen: draftOpen),
            ),
      canPop: !draftOpen.value,
    );
  }
}

class const _TableToolbar({
  required final WorkspaceTableScreen screen,
  required final ValueNotifier<bool> draftOpen,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.workspace_items_table),
    actions: [_RefreshTableButton(screen: screen, draftOpen: draftOpen)],
  );
}

class const _RefreshTableButton({
  required final WorkspaceTableScreen screen,
  required final ValueNotifier<bool> draftOpen,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraIconButton(
    icon: Icons.refresh,
    onPressed: draftOpen.value
        ? null
        : () => _TableNavigationActions.refresh(
            ref,
            screen.workspaceId,
            screen.tableId,
          ),
  );
}

class const _TableState({
  required final WorkspaceTableScreen screen,
  required final ValueNotifier<bool> draftOpen,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(
      workspaceTableProvider(screen.workspaceId, screen.tableId),
    );

    if (table case AsyncError(:final error)) {
      return _TableFailure(screen: screen, error: error);
    }
    final current = table.value;
    if (current != null) {
      return _LoadedTable(screen: screen, table: current, draftOpen: draftOpen);
    }

    return _PendingTable(screen, table, draftOpen);
  }
}

class const _PendingTable(
  final WorkspaceTableScreen screen,
  final AsyncValue<WorkspaceTable> table,
  final ValueNotifier<bool> draftOpen,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (table) {
    AsyncData(:final value) => _LoadedTable(
      screen: screen,
      table: value,
      draftOpen: draftOpen,
    ),
    AsyncError(:final error) => _TableFailure(screen: screen, error: error),
    AsyncLoading() => const Center(child: CircularProgressIndicator()),
  };
}

class const _TableFailure({
  required final WorkspaceTableScreen screen,
  required final Object error,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: [
      if (!screen.compact) _TableFailureBack(screen: screen),
      WorkspaceItemFailure(error: error),
      if (screen.compact) _TableFailureRetry(screen: screen),
    ],
  );
}

class const _TableFailureBack({required final WorkspaceTableScreen screen})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.arrow_back),
    title: const TextLocale(LocaleKeys.workspace_items_title),
    onTap: screen.onBack,
  );
}

class const _TableFailureRetry({required final WorkspaceTableScreen screen})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => _TableNavigationActions.refresh(
      ref,
      screen.workspaceId,
      screen.tableId,
    ),
    child: const TextLocale(LocaleKeys.common_reload),
    identifier: 'workspace_table_retry',
  );
}

class const _TableContents({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onBack,
  required final ValueNotifier<bool> draftOpen,
  required final bool compact,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = _TableNavigationActions.use(ref, this);

    return _TableSelectionView(owner: this, navigation: navigation);
  }
}

typedef _TableNavigation = ({
  ValueNotifier<_Selection?> selected,
  VoidCallback close,
  VoidCallback refresh,
});

abstract final class _TableNavigationActions {
  static _TableNavigation use(WidgetRef ref, _TableContents owner) {
    final selected = useState<_Selection?>(null);
    void reload() => refresh(ref, owner.workspaceId, owner.table.id);
    void close() {
      selected.value = null;
      reload();
    }

    return (selected: selected, close: close, refresh: reload);
  }

  static void refresh(WidgetRef ref, String workspaceId, String tableId) {
    ref
      ..invalidate(workspaceTableProvider(workspaceId, tableId))
      ..invalidate(workspaceTableRecordsProvider(workspaceId, tableId))
      ..invalidate(workspaceReferencesUsecaseProvider(workspaceId))
      ..invalidate(workspaceRecordQueryProvider);
  }
}

sealed class _Selection {
  const new();
}

class const _RecordSelection(final WorkspaceRecord? record) extends _Selection;
class const _ColumnSelection(final WorkspaceColumn? column) extends _Selection;

class const _TableSelectionView({
  required final _TableContents owner,
  required final _TableNavigation navigation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      Offstage(
        offstage: navigation.selected.value != null,
        child: _BrowsingPage(owner: owner, navigation: navigation),
      ),
      if (navigation.selected.value != null)
        Positioned.fill(
          child: _EditingPage(owner: owner, navigation: navigation),
        ),
    ],
  );
}

class const _EditingPage({
  required final _TableContents owner,
  required final _TableNavigation navigation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (navigation.selected.value) {
    _RecordSelection(:final record) => _RecordPage(
      owner: owner,
      navigation: navigation,
      record: record,
    ),
    _ColumnSelection(:final column) => _ColumnPage(
      owner: owner,
      navigation: navigation,
      column: column,
    ),
    null => const SizedBox.shrink(),
  };
}

class const _RecordPage({
  required final _TableContents owner,
  required final _TableNavigation navigation,
  required final WorkspaceRecord? record,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceRecordEditor(
    workspaceId: owner.workspaceId,
    table: owner.table,
    record: record,
    onBack: navigation.close,
    key: .new(record?.id ?? 'new'),
  );
}

class const _ColumnPage({
  required final _TableContents owner,
  required final _TableNavigation navigation,
  required final WorkspaceColumn? column,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceColumnEditor(
    workspaceId: owner.workspaceId,
    table: owner.table,
    column: column,
    onBack: navigation.close,
    key: .new(column?.id ?? 'new-column'),
  );
}

class const _BrowsingPage({
  required final _TableContents owner,
  required final _TableNavigation navigation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _TableBrowser(
    workspaceId: owner.workspaceId,
    table: owner.table,
    onBack: owner.onBack,
    onChanged: navigation.refresh,
    onRecord: _recordCallback(context),
    onColumn: _column,
    onAddColumn: _columnCallback(context),
    draftOpen: owner.draftOpen,
    compact: owner.compact,
  );
  ValueChanged<WorkspaceRecord?> _recordCallback(BuildContext context) =>
      (record) => _record(context, record);
  ValueChanged<WorkspaceColumnType> _columnCallback(BuildContext context) =>
      (type) => _addColumn(context, type);
  void _record(BuildContext context, WorkspaceRecord? record) {
    if (record != null) {
      navigation.selected.value = _RecordSelection(record);

      return;
    }
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => _NewRecordDialog(owner: owner, navigation: navigation),
      ),
    );
  }

  void _column(WorkspaceColumn? column) {
    navigation.selected.value = _ColumnSelection(column);
  }

  void _addColumn(BuildContext context, WorkspaceColumnType type) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) =>
            _NewColumnDialog(owner: owner, navigation: navigation, type: type),
        barrierDismissible: false,
      ),
    );
  }
}

class const _NewRecordDialog({
  required final _TableContents owner,
  required final _TableNavigation navigation,
}) extends StatelessWidget {
  static const _size = 600.0;
  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: _size,
      height: _size,
      child: WorkspaceRecordEditor(
        workspaceId: owner.workspaceId,
        table: owner.table,
        record: null,
        onBack: () {
          Navigator.of(context).pop();
          navigation.refresh();
        },
      ),
    ),
  );
}

class const _NewColumnDialog({
  required final _TableContents owner,
  required final _TableNavigation navigation,
  required final WorkspaceColumnType type,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 550),
      child: WorkspaceColumnEditor(
        workspaceId: owner.workspaceId,
        table: owner.table,
        column: null,
        onBack: () {
          Navigator.of(context).pop();
          navigation.refresh();
        },
        initialType: type,
        compact: true,
      ),
    ),
  );
}

class const _TableBrowser({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onBack,
  required final VoidCallback onChanged,
  required final ValueChanged<WorkspaceRecord?> onRecord,
  required final ValueChanged<WorkspaceColumn?> onColumn,
  required final ValueChanged<WorkspaceColumnType> onAddColumn,
  required final ValueNotifier<bool> draftOpen,
  required final bool compact,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final settings = useState(false);
    final selectionMode = useState(false);

    return Column(
      children: [
        if (!compact)
          IgnorePointer(
            ignoring: draftOpen.value,
            child: _BrowserToolbar(this, settings, selectionMode),
          ),
        Expanded(child: _BrowserContent(this, settings, selectionMode)),
      ],
    );
  }
}

class const _BrowserContent(
  final _TableBrowser browser,
  final ValueNotifier<bool> settings,
  final ValueNotifier<bool> selectionMode,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      Offstage(
        offstage: settings.value,
        child: _BrowserRecords(browser, selectionMode),
      ),
      if (settings.value)
        Positioned.fill(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [_TableManagement(browser: browser)],
          ),
        ),
    ],
  );
}

class const _BrowserRecords(
  final _TableBrowser browser,
  final ValueNotifier<bool> selectionMode,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceRecordBrowser(
    workspaceId: browser.workspaceId,
    table: browser.table,
    onRecord: browser.onRecord,
    selectionMode: selectionMode,
    draftOpen: browser.draftOpen,
    onAddRow: () => browser.onRecord(null),
    onAddColumn: browser.onAddColumn,
  );
}

class const _BrowserToolbar(
  final _TableBrowser browser,
  final ValueNotifier<bool> settings,
  final ValueNotifier<bool> selectionMode,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _TableBackButton(browser, settings),
      Expanded(child: Text(browser.table.name)),
      if (browser.table.canEditRecords) _NewRecordButton(browser, settings),
      _TableMenu(browser, settings, selectionMode),
    ],
  );
}

class const _TableBackButton(
  final _TableBrowser browser,
  final ValueNotifier<bool> settings,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.arrow_back,
    onPressed: _back,
    identifier: 'workspace_table_back',
    semanticLabel: LocaleKeys.workspace_items_title.tr(),
    tooltip: LocaleKeys.workspace_items_title.tr(),
  );
  void _back() {
    if (settings.value) {
      settings.value = false;
    } else {
      browser.onBack();
    }
  }
}

class const _NewRecordButton(
  final _TableBrowser browser,
  final ValueNotifier<bool> settings,
) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = WorkspaceTableActions.use(context);

    return AuraIconButton(
      icon: Icons.add,
      onPressed: action.pending ? null : () => _create(ref, action),
      identifier: 'workspace_record_create',
      tooltip: LocaleKeys.workspace_items_create_record.tr(),
    );
  }

  void _create(WidgetRef ref, WorkspaceTableAction action) {
    settings.value = false;
    unawaited(
      action.run(
        () => createEmptyWorkspaceRecord(
          ref,
          workspaceId: browser.workspaceId,
          table: browser.table,
        ),
      ),
    );
  }
}

class const _TableMenu(
  final _TableBrowser browser,
  final ValueNotifier<bool> settings,
  final ValueNotifier<bool> selectionMode,
) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraPopupMenuButton(
    items: _items(context, ref),
    identifier: 'workspace_table_overflow',
    tooltip: LocaleKeys.common_show_more.tr(),
  );

  List<AuraPopupMenuEntry> _items(BuildContext context, WidgetRef ref) => [
    if (browser.table.canEditRecords && !selectionMode.value) _select(),
    if (browser.table.canManage) ...[_settings(), _duplicate(context)],
    _TableHistoryMenu.item(context, browser),
    if (browser.table.canEditRecords) _import(context, ref),
    _export(context),
    if (browser.table.canManage) ...[
      const AuraPopupMenuDivider(),
      _trash(context, ref),
    ],
  ];

  AuraPopupMenuItem _select() => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_bulk_select),
    onTap: _startSelection,
    identifier: 'workspace_records_select',
  );
  void _startSelection() {
    settings.value = false;
    selectionMode.value = true;
  }

  AuraPopupMenuItem _duplicate(BuildContext context) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_duplicate),
    onTap: () => unawaited(
      WorkspaceItemDuplicationActions.open(
        context,
        browser.workspaceId,
        browser.table,
      ),
    ),
    identifier: 'workspace_table_duplicate',
  );

  AuraPopupMenuItem _settings() => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_settings),
    onTap: () => settings.value = !settings.value,
  );
  AuraPopupMenuItem _import(BuildContext context, WidgetRef ref) =>
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_csv_import),
        onTap: () => unawaited(
          WorkspaceCsvDialog.openImport(
            context,
            ref,
            browser.workspaceId,
            browser.table,
          ),
        ),
        identifier: 'workspace_csv_import',
      );
  AuraPopupMenuItem _export(BuildContext context) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_csv_export),
    onTap: () => unawaited(
      WorkspaceCsvDialog.openExport(
        context,
        browser.workspaceId,
        browser.table,
      ),
    ),
    identifier: 'workspace_csv_export',
  );
  AuraPopupMenuItem _trash(BuildContext context, WidgetRef ref) =>
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_trash_action),
        onTap: () => unawaited(_delete(context, ref)),
        variant: .error,
        identifier: 'workspace_table_trash',
      );
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final table = browser.table;
    final deleted = await WorkspaceTrashActions.trash(
      context,
      ref,
      browser.workspaceId,
      .new(kind: .table, id: table.id, revision: table.revision),
    );
    if (context.mounted && deleted) browser.onBack();
  }
}

class const _TableManagement({required final _TableBrowser browser})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _LabelEditor(
        workspaceId: browser.workspaceId,
        table: browser.table,
        onChanged: browser.onChanged,
      ),
      _ColumnList(table: browser.table, onColumn: browser.onColumn),
      if (browser.table.supportsSharing) _TableSharing(browser: browser),
    ],
  );
}

class const _TableSharing({required final _TableBrowser browser})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceTableAccessPanel(
    workspaceId: browser.workspaceId,
    table: browser.table,
    onChanged: browser.onChanged,
  );
}

class const _LabelEditor({
  required final String workspaceId,
  required final WorkspaceTable table,
  required final VoidCallback onChanged,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _LabelActions.use(context, table);

    return _LabelForm(
      draft: draft,
      onSave: () => _LabelActions.save(ref, this, draft),
    );
  }
}

typedef _LabelDraft = ({
  TextEditingController name,
  WorkspaceTableAction action,
});

abstract final class _LabelActions {
  static _LabelDraft use(BuildContext context, WorkspaceTable table) => (
    name: useTextEditingController(
      text: table.columns
          .firstWhere((column) => column.id == table.labelColumnId)
          .name,
    ),
    action: WorkspaceTableActions.use(context),
  );
  static Future<void> save(
    WidgetRef ref,
    _LabelEditor editor,
    _LabelDraft draft,
  ) async {
    final usecase = await ref.read(
      workspaceTableUsecaseProvider(editor.workspaceId).future,
    );
    final _ = await usecase.renameLabel(
      table: editor.table,
      name: draft.name.text,
    );
    if (ref.context.mounted) editor.onChanged();
  }
}

class const _LabelForm({
  required final _LabelDraft draft,
  required final Future<void> Function() onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _LabelInput(draft: draft),
      _LabelSave(draft: draft, onSave: onSave),
      if (draft.action.error case final error?)
        WorkspaceItemFailure(error: error),
    ],
  );
}

class const _LabelInput({required final _LabelDraft draft})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: draft.name,
    label: const TextLocale(LocaleKeys.workspace_items_label_column),
    enabled: !draft.action.pending,
    identifier: 'workspace_label_column',
  );
}

class const _LabelSave({
  required final _LabelDraft draft,
  required final Future<void> Function() onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(draft.action.run(onSave)),
    child: const TextLocale(LocaleKeys.workspace_items_save_column),
    isLoading: draft.action.pending,
    disabled: draft.action.pending,
    identifier: 'workspace_label_save',
  );
}

class const _ColumnList({
  required final WorkspaceTable table,
  required final ValueChanged<WorkspaceColumn?> onColumn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AuraButton(
        onPressed: () => onColumn(null),
        child: const TextLocale(LocaleKeys.workspace_items_create_column),
        identifier: 'workspace_column_create',
      ),
      for (final column in table.columns)
        ListTile(
          title: Text(column.name),
          subtitle: WorkspaceColumnTypeLabel(type: column.type),
          onTap: () => onColumn(column),
        ),
    ],
  );
}

class const _LoadedTable({
  required final WorkspaceTableScreen screen,
  required final WorkspaceTable table,
  required final ValueNotifier<bool> draftOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _TableContents(
    workspaceId: screen.workspaceId,
    table: table,
    onBack: screen.onBack,
    draftOpen: draftOpen,
    compact: screen.compact,
    key: ValueKey(table.id),
  );
}

abstract final class _TableHistoryMenu {
  static AuraPopupMenuItem item(BuildContext context, _TableBrowser browser) =>
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_history_title),
        onTap: () => unawaited(_open(context, browser)),
        identifier: 'workspace_table_history',
      );

  static Future<bool?> _open(BuildContext context, _TableBrowser browser) =>
      WorkspaceHistoryPanel.open(context, (
        workspaceId: browser.workspaceId,
        target: .new(
          kind: .table,
          id: browser.table.id,
          revision: browser.table.revision,
        ),
        canRestore: browser.table.canManage,
      ));
}
