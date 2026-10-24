import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/directory_navigation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/directory_navigation_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_folder_metadata_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_creation.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_lists.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_table_metadata_editor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemsScreen({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(directoryNavigationProvider(workspaceId));
    final actions = ref.read(directoryNavigationProvider(workspaceId).notifier);

    return _Navigation(
      workspaceId,
      state,
      actions,
      useState<Set<String>?>(null),
    );
  }
}

class const _Navigation(
  final String workspaceId,
  final DirectoryNavigation state,
  final DirectoryNavigationNotifier actions,
  final ValueNotifier<Set<String>?> selection,
) extends ConsumerWidget {
  String? get _parentId => state.path.lastOrNull?.id;
  String? get _parentName => state.path.lastOrNull?.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopScope(
    child: _SelectedItem(this),
    canPop:
        state.selected == null && state.path.isEmpty && selection.value == null,
    onPopInvokedWithResult: (didPop, result) => _back(ref, didPop),
  );

  void _back(WidgetRef ref, bool didPop) {
    if (didPop) return;
    if (selection.value != null) {
      selection.value = null;

      return;
    }
    if (state.selected != null) {
      actions.open(null);
      _refresh(ref);

      return;
    }
    actions.ancestor(state.path.length - 1);
  }

  void _folder(WorkspaceFolder folder) {
    selection.value = null;
    actions.enter(folder);
  }

  void _refresh(WidgetRef ref) => unawaited(_reload(ref));
  Future<void> _reload(WidgetRef ref) async {
    await actions.refreshPath();
    if (!ref.context.mounted) return;
    final parent = ref
        .read(directoryNavigationProvider(workspaceId))
        .path
        .lastOrNull
        ?.id;
    ref
      ..invalidate(workspaceFoldersProvider(workspaceId, parent))
      ..invalidate(workspaceTablesProvider(workspaceId, parent));
  }
}

class const _SelectedItem(final _Navigation navigation) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (navigation.state.selected) {
        final WorkspaceFolder folder => _FolderEditor(navigation, folder),
        final WorkspaceTable table => _TableEditor(navigation, table),
        final String id => _OpenedTable(navigation,id),
    _ => _Browser(navigation),
      };
}

class const _OpenedTable(final _Navigation navigation,final String id) extends ConsumerWidget {
  @override
  Widget build(BuildContext context,WidgetRef ref) => WorkspaceTableScreen(workspaceId:navigation.workspaceId,tableId:id,onBack:() => _back(ref));
  void _back(WidgetRef ref) {
    navigation.actions.open(null);
    navigation._refresh(ref);
  }
}

class const _FolderEditor(
  final _Navigation navigation,
  final WorkspaceFolder folder,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: WorkspaceFolderMetadataEditor(
      workspaceId: navigation.workspaceId,
      folder: folder,
      parentName: navigation._parentName,
      onBack: () => navigation.actions.open(null),
    ),
  );
}

class const _TableEditor(
  final _Navigation navigation,
  final WorkspaceTable table,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: WorkspaceTableMetadataEditor(
      workspaceId: navigation.workspaceId,
      table: table,
      parentName: navigation._parentName,
      onBack: () => navigation.actions.open(null),
    ),
  );
}

class const _Browser(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: _BrowserBody(navigation, key: ValueKey(navigation._parentId)),
    appBar: _DirectoryToolbar(navigation),
  );
}

class const _DirectoryToolbar(final _Navigation navigation)
    extends ConsumerWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.workspace_items_title),
    actions: [
      if (navigation.selection.value == null) _CreateMenu(navigation),
      _DirectoryMore(navigation),
    ],
    leading: navigation.state.path.isEmpty ? null : _DirectoryBack(navigation),
  );
}

class const _DirectoryMore(final _Navigation navigation)
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      navigation.selection.value != null
      ? _SelectionButton(navigation)
      : AuraPopupMenuButton(items: [_select(), _reload(ref)]);
  AuraPopupMenuItem _select() => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.workspace_items_select),
    onTap: () => navigation.selection.value = <String>{},
  );
  AuraPopupMenuItem _reload(WidgetRef ref) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.common_reload),
    onTap: () => navigation._refresh(ref),
  );
}

class const _DirectoryBack(final _Navigation navigation)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () =>
        navigation.actions.ancestor(navigation.state.path.length - 1),
    icon: const Icon(Icons.arrow_back),
  );
}

class const _SelectionButton(final _Navigation navigation)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: _toggle,
    child: TextLocale(
      navigation.selection.value == null
          ? LocaleKeys.workspace_items_select
          : LocaleKeys.workspace_items_done,
    ),
  );
  void _toggle() => navigation.selection.value =
      navigation.selection.value == null ? <String>{} : null;
}

class const _BrowserBody(final _Navigation navigation, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(
      workspaceFoldersProvider(navigation.workspaceId, navigation._parentId),
    );
    final tables = ref.watch(
      workspaceTablesProvider(navigation.workspaceId, navigation._parentId),
    );
    if (folders.isLoading || tables.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _DirectoryList(navigation);
  }
}

class const _DirectoryList(final _Navigation navigation)
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final parent = navigation._parentId;
    final scroll = useScrollController(
      initialScrollOffset: navigation.state.offsets[parent] ?? 0,
    );
    _rememberScroll(scroll, navigation, parent);

    return _DirectoryScroll(navigation,scroll);
  }
}

class const _DirectoryScroll(final _Navigation navigation,final ScrollController scroll) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(key:ValueKey(navigation._parentId),controller:scroll,padding:const EdgeInsets.all(16),children:[_Breadcrumb(navigation),_DirectoryStatus(navigation),_Items(navigation)]);
}

class const _DirectoryStatus(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(children:[
    if(navigation.state.recovered) const TextLocale(LocaleKeys.workspace_items_location_recovered),
    if(navigation.state.failure case final failure?) WorkspaceItemFailure(error:failure),
    if(navigation.selection.value case final selected?) Text(LocaleKeys.workspace_items_selected.tr(args:[selected.length.toString()])),
  ]);
}

void _rememberScroll(
  ScrollController scroll,
  _Navigation navigation,
  String? parent,
) {
  useEffect(() {
    void remember() => navigation.actions.rememberOffset(parent, scroll.offset);
    scroll.addListener(remember);

    return () => scroll.removeListener(remember);
  }, [scroll, parent]);
}

class const _Breadcrumb(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      TextButton(
        onPressed: () => navigation.actions.ancestor(0),
        child: const TextLocale(LocaleKeys.workspace_items_title),
      ),
      for (var index = 0; index < navigation.state.path.length; index++)
        _PathSegment(navigation, index),
    ],
  );
}

class const _PathSegment(final _Navigation navigation, final int index)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => navigation.actions.ancestor(index + 1),
    child: Text(navigation.state.path[index].name),
  );
}

class const _CreateMenu(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPopupMenuButton(
    items: [
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_folder),
        onTap: () => _show(context, false),
      ),
      AuraPopupMenuItem(
        title: const TextLocale(LocaleKeys.workspace_items_table),
        onTap: () => _show(context, true),
      ),
    ],
    key: const ValueKey('directory_create'),
    icon: Icons.add,
    tooltip: LocaleKeys.common_add.tr(),
  );

  void _show(BuildContext context, bool table) {
    if (MediaQuery.sizeOf(context).width < 600) {
      _sheet(context, table);
    } else {
      _dialog(context, table);
    }
  }

  void _sheet(BuildContext context, bool table) {
    final _ = showModalBottomSheet<void>(
      context: context,
      builder: (context) => _CreationSurface(navigation, table: table),
      isScrollControlled: true,
    );
  }

  void _dialog(BuildContext context, bool table) {
    final _ = showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 400,
          child: _CreationSurface(navigation, table: table),
        ),
      ),
    );
  }
}

class const _CreationSurface(
  final _Navigation navigation, {
  required final bool table,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: _formPadding,
      top: _formPadding,
      right: _formPadding,
      bottom: _formPadding + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(child: _Creation(navigation, table: table)),
  );
}

class const _Creation(final _Navigation navigation, {required final bool table})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceItemCreation(
    workspaceId: navigation.workspaceId,
    parentId: navigation._parentId,
    table: table,
    onOpenTable: (id) => _table(context, id),
    onOpenFolder: (folder) => _folder(context, folder),
    key: ValueKey((parentId: navigation._parentId, table: table)),
  );
  void _table(BuildContext context, String id) {
    Navigator.of(context).pop();
    navigation.actions.open(id);
  }

  void _folder(BuildContext context, WorkspaceFolder folder) {
    Navigator.of(context).pop();
    navigation._folder(folder);
  }
}

class const _Items(final _Navigation navigation) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceItemLists(
    workspaceId: navigation.workspaceId,
    parentId: navigation._parentId,
    onOpenFolder: navigation._folder,
    onOpenTable: navigation.actions.open,
    onEdit: navigation.actions.open,
    selection: navigation.selection.value,
    onSelect: _select,
  );
  void _select(String id) {
    final selected = navigation.selection.value?.toSet() ?? <String>{};
    if (!selected.add(id)) {
      final _ = selected.remove(id);
    }
    navigation.selection.value = selected;
  }
}

const _formPadding = 24.0;
