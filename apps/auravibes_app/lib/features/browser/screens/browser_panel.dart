import 'dart:async';

import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/models/sidebar_tool_result_tab.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/providers/sidebar_workspace_tab_count.dart';
import 'package:auravibes_app/features/browser/screens/sidebar_directory.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:auravibes_app/features/workflows/notifiers/workflow_editor_notifier.dart';
import 'package:auravibes_app/features/workflows/providers/workflow_providers.dart';
import 'package:auravibes_app/features/workflows/screens/workflow_editor_screen.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_file_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const BrowserPanel({
  required final String workspaceId,
  required final String conversationId,
  required final List<SidebarToolResultTab> toolResultTabs,
  required final String? selectedToolResultTabId,
  required final ValueChanged<String?> onSelectToolResultTab,
  required final ValueChanged<String> onCloseToolResultTab,
  required final VoidCallback onCloseSidebar,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(
      browserSessionProvider(workspaceId, conversationId),
    );

    return switch (sessionAsync) {
      AsyncData(:final value) => _BrowserSessionView(
        request: _request(ref, value),
        key: ValueKey((
          workspaceId: workspaceId,
          conversationId: conversationId,
        )),
      ),
      AsyncError() => const Center(
        child: TextLocale(LocaleKeys.browser_load_error),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }

  _BrowserSessionViewRequest _request(
    WidgetRef ref,
    BrowserSessionState session,
  ) => (
    workspaceId: workspaceId,
    conversationId: conversationId,
    session: session,
    notifier: ref.read(
      browserSessionProvider(workspaceId, conversationId).notifier,
    ),
    toolResultTabs: toolResultTabs,
    selectedToolResultTabId: selectedToolResultTabId,
    onSelectToolResultTab: onSelectToolResultTab,
    onCloseToolResultTab: onCloseToolResultTab,
    onCloseSidebar: onCloseSidebar,
  );
}

typedef _BrowserSessionViewRequest = ({
  String workspaceId,
  String conversationId,
  BrowserSessionState session,
  BrowserSessionNotifier notifier,
  List<SidebarToolResultTab> toolResultTabs,
  String? selectedToolResultTabId,
  ValueChanged<String?> onSelectToolResultTab,
  ValueChanged<String> onCloseToolResultTab,
  VoidCallback onCloseSidebar,
});

typedef _BrowserPanelData = ({
  _BrowserSessionViewRequest request,
  BrowserWebViewService webViewService,
  BrowserTab? activeTab,
  SidebarToolResultTab? selectedToolResultTab,
  TextEditingController addressController,
  GlobalKey activeTabKey,
  _WorkspaceTabs workspaceTabs,
  VoidCallback onCloseSidebar,
});

typedef _BrowserPanelTabState = ({
  BrowserTab? activeTab,
  SidebarToolResultTab? selectedToolResultTab,
  TextEditingController addressController,
  GlobalKey activeTabKey,
});

typedef _BrowserPageStateUpdate = ({
  BrowserSessionNotifier notifier,
  BrowserWebViewService webViewService,
  String conversationId,
  String tabId,
  String? url,
});

class const _BrowserSessionView({
  required final _BrowserSessionViewRequest request,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = _WorkspaceTabs.use(request);
    _useTabCount(ref, tabs);
    _useSelectedTool(context, tabs);
    _useRequestedView(context, ref, tabs);

    return _BrowserSessionColumn(
      data: _createPanelData(
        ref,
        request,
        _usePanelTabState(request, tabs.selected.value),
        tabs,
      ),
    );
  }

  static _BrowserPanelTabState _usePanelTabState(
    _BrowserSessionViewRequest request,
    String? selectedWorkspace,
  ) {
    final activeTab = request.session.activeTab;
    final selectedToolResultTab = request.toolResultTabs
        .where((tab) => tab.id == request.selectedToolResultTabId)
        .firstOrNull;

    return (
      activeTab: activeTab,
      selectedToolResultTab: selectedToolResultTab,
      addressController: _useAddressController(activeTab),
      activeTabKey: _useActiveTabKey(
        activeTab,
        selectedToolResultTab,
        selectedWorkspace,
      ),
    );
  }

  static TextEditingController _useAddressController(BrowserTab? activeTab) =>
      useTextEditingController(
        text: activeTab?.url ?? '',
        keys: [activeTab?.id, activeTab?.url],
      );

  static GlobalKey _useActiveTabKey(
    BrowserTab? activeTab,
    SidebarToolResultTab? selectedToolResultTab,
    String? selectedWorkspace,
  ) {
    final activeTabKey = useMemoized(GlobalKey.new, const []);
    useEffect(() => _scrollToActiveBrowserTab(activeTabKey), [
      selectedWorkspace ?? selectedToolResultTab?.id ?? activeTab?.id,
    ]);

    return activeTabKey;
  }

  static _BrowserPanelData _createPanelData(
    WidgetRef ref,
    _BrowserSessionViewRequest request,
    _BrowserPanelTabState state,
    _WorkspaceTabs tabs,
  ) => (
    request: request,
    webViewService: ref.read(browserWebViewServiceProvider),
    activeTab: state.activeTab,
    selectedToolResultTab: state.selectedToolResultTab,
    addressController: state.addressController,
    activeTabKey: state.activeTabKey,
    workspaceTabs: tabs,
    onCloseSidebar: request.onCloseSidebar,
  );
}

extension _BrowserWorkspaceHooks on _BrowserSessionView {
  void _useTabCount(WidgetRef ref, _WorkspaceTabs tabs) {
    final count = ref.watch(
      sidebarWorkspaceTabCountProvider((
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
      )),
    );
    useEffect(
      () =>
          () => count.value = 0,
      [count],
    );
    final tabCount = _workspaceTabCount(tabs);
    useEffect(
      () => _trackTabCount(count, tabCount),
      [count, tabCount], // Update the badge when tabs change.
    );
  }

  void _useSelectedTool(BuildContext context, _WorkspaceTabs tabs) {
    final resultKeys = [request.selectedToolResultTabId];
    useEffect(
      () => _selectToolAfterFrame(context, tabs),
      resultKeys, // Follow the selected tool result.
    );
  }

  void _useRequestedView(
    BuildContext context,
    WidgetRef ref,
    _WorkspaceTabs tabs,
  ) {
    final provider = workspaceOpenViewProvider(
      request.workspaceId,
      request.conversationId,
    );
    final requested = ref.watch(provider);
    useEffect(
      () => _openViewAfterFrame(context, tabs, requested),
      [requested], // Open workspace requests in their own tab.
    );
    ref.listen(provider, (previous, next) => _openRequestedView(tabs, next));
  }

  VoidCallback _trackTabCount(ValueNotifier<int> count, int tabCount) {
    var mounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) count.value = tabCount;
    });

    return () => mounted = false;
  }

  VoidCallback? _selectToolAfterFrame(
    BuildContext context,
    _WorkspaceTabs tabs,
  ) {
    if (request.selectedToolResultTabId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) tabs.select(null);
      });
    }

    return null;
  }

  VoidCallback? _openViewAfterFrame(
    BuildContext context,
    _WorkspaceTabs tabs,
    WorkspaceChatItem? requested,
  ) {
    if (requested != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _openRequestedView(tabs, requested);
      });
    }

    return null;
  }

  void _openRequestedView(_WorkspaceTabs tabs, WorkspaceChatItem? requested) {
    if (requested == null) return;
    request.onSelectToolResultTab(null);
    tabs.open(requested);
  }
}

int _workspaceTabCount(_WorkspaceTabs tabs) =>
    tabs.items.value.length +
    (tabs.directoryOpen.value ? 1 : 0) +
    (tabs.selected.value == 'chooser' ? 1 : 0);

class const _BrowserSessionColumn({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SidebarTabStrip(data: data),
      Expanded(child: _BrowserPanelBody(data: data)),
    ],
  );
}

void Function()? _scrollToActiveBrowserTab(GlobalKey activeTabKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = activeTabKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 180),
    );
  });

  return null;
}

class const _BrowserPanelBody({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      _BrowserSuspendedSessionSlot(data: data),
      _BrowserActiveTabSlot(data: data),
      _BrowserEmptyStateSlot(data: data),
      _BrowserToolResultSlot(data: data),
      _WorkspaceTabSlot(data: data),
    ],
  );
}

class const _BrowserSuspendedSessionSlot({
  required final _BrowserPanelData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!data.request.session.isSuspended ||
        data.workspaceTabs.selected.value != null) {
      return const SizedBox.shrink();
    }

    return _BrowserSuspendedSession(notifier: data.request.notifier);
  }
}

class const _BrowserActiveTabSlot({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (data.request.session.isSuspended) return const SizedBox.shrink();
    final activeTab = data.activeTab;
    if (activeTab == null) return const SizedBox.shrink();

    return Offstage(
      offstage:
          data.selectedToolResultTab != null ||
          data.workspaceTabs.selected.value != null,
      child: _BrowserActiveTab(data: data, activeTab: activeTab),
    );
  }
}

class const _BrowserEmptyStateSlot({required final _BrowserPanelData data})
    extends StatelessWidget {
  bool get _shouldShow {
    final selected = data.workspaceTabs.selected.value;

    return ((data.activeTab == null && selected == null) ||
            selected == 'chooser') &&
        data.selectedToolResultTab == null &&
        (!data.request.session.isSuspended || selected == 'chooser');
  }

  @override
  Widget build(BuildContext context) =>
      _shouldShow ? _SidebarChooser(data: data) : const SizedBox.shrink();
}

class const _BrowserToolResultSlot({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tab = data.selectedToolResultTab;
    if (tab == null || data.workspaceTabs.selected.value != null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(child: _SidebarToolResultContent(tab: tab));
  }
}

class const _BrowserSuspendedSession({
  required final BrowserSessionNotifier notifier,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          const TextLocale(
            LocaleKeys.browser_suspended_message,
            textAlign: .center,
          ),
          const SizedBox(height: 12),
          AuraButton(
            onPressed: () => unawaited(notifier.resume()),
            child: const TextLocale(LocaleKeys.browser_resume),
            size: .small,
          ),
        ],
      ),
    ),
  );
}

class const _BrowserActiveTab({
  required final _BrowserPanelData data,
  required final BrowserTab activeTab,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _BrowserAddressToolbar(data: data, tabId: activeTab.id),
      Expanded(
        child: _BrowserTabViews(data: data, activeTabId: activeTab.id),
      ),
      if (data.request.session.agentActivity case final activity?)
        _BrowserAgentActivity(activity: activity),
    ],
  );
}

class const _BrowserAddressToolbar({
  required final _BrowserPanelData data,
  required final String tabId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          _BrowserHistoryButton(data: data, tabId: tabId, backwards: true),
          _BrowserHistoryButton(data: data, tabId: tabId, backwards: false),
          _BrowserReloadButton(data: data, tabId: tabId),
          const SizedBox(width: 8),
          Expanded(child: _BrowserAddressInput(data: data)),
        ],
      ),
    );
  }
}

class const _BrowserHistoryButton({
  required final _BrowserPanelData data,
  required final String tabId,
  required final bool backwards,
}) extends StatelessWidget {
  bool get _enabled => backwards
      ? data.request.session.canGoBack
      : data.request.session.canGoForward;

  String get _label => backwards
      ? LocaleKeys.browser_go_back.tr()
      : LocaleKeys.browser_go_forward.tr();

  IconData get _icon => backwards ? Icons.arrow_back : Icons.arrow_forward;

  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: _icon,
    onPressed: _onPressed(context),
    tooltip: _label,
  );

  VoidCallback? _onPressed(BuildContext context) {
    if (!_enabled) return null;

    return () => unawaited(
      _runBrowserCommand(
        context,
        () => _browserHistoryOperation(data, tabId, backwards),
      ),
    );
  }
}

Future<void> _browserHistoryOperation(
  _BrowserPanelData data,
  String tabId,
  bool backwards,
) {
  final controller = data.webViewService.controller;
  final operation = backwards ? controller.goBack : controller.goForward;

  return operation(sessionId: data.request.conversationId, tabId: tabId);
}

class const _BrowserAddressInput({required final _BrowserPanelData data})
    extends StatelessWidget {
  String get _label => LocaleKeys.browser_address.tr();

  @override
  Widget build(BuildContext context) => AuraInput(
    controller: data.addressController,
    prefixIcon: const AuraIcon(Icons.public),
    textInputAction: .go,
    onSubmitted: (url) => _submit(context, url),
    identifier: 'browser_address_input',
    semanticLabel: _label,
  );

  void _submit(BuildContext context, String url) => unawaited(
    _runBrowserCommand(context, () => data.request.notifier.navigate(url)),
  );
}

class const _BrowserReloadButton({
  required final _BrowserPanelData data,
  required final String tabId,
}) extends StatelessWidget {
  bool get _isLoading => data.request.session.isLoading;

  String get _label => _isLoading
      ? LocaleKeys.browser_stop.tr()
      : LocaleKeys.browser_reload.tr();

  IconData get _icon => _isLoading ? Icons.close : Icons.refresh;

  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: _icon,
    onPressed: () => _onPressed(context),
    tooltip: _label,
  );

  void _onPressed(BuildContext context) => unawaited(
    _runBrowserCommand(
      context,
      () => _browserLoadingOperation(data, tabId, _isLoading),
    ),
  );
}

Future<void> _browserLoadingOperation(
  _BrowserPanelData data,
  String tabId,
  bool isLoading,
) {
  final controller = data.webViewService.controller;
  final operation = isLoading ? controller.stopLoading : controller.reload;

  return operation(sessionId: data.request.conversationId, tabId: tabId);
}

class const _BrowserTabViews({
  required final _BrowserPanelData data,
  required final String activeTabId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final tab in data.request.session.tabs)
          _BrowserTabWebView(data: data, tab: tab, activeTabId: activeTabId),
        if (data.request.session.hasError)
          const Align(
            alignment: .bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: TextLocale(LocaleKeys.browser_page_error),
            ),
          ),
      ],
    );
  }
}

typedef _BrowserTabUpdate = ({
  String? url,
  String? title,
  bool? isLoading,
  bool? hasError,
  bool? canGoBack,
  bool? canGoForward,
});

class const _BrowserTabWebView({
  required final _BrowserPanelData data,
  required final BrowserTab tab,
  required final String activeTabId,
}) extends StatelessWidget {
  String get _tabId => tab.id;

  BrowserWebViewRequest get _request => (
    sessionId: data.request.conversationId,
    tabId: _tabId,
    initialUrl: tab.url,
    onTitleChanged: _onTitleChanged,
    onLoadStart: _onLoadStart,
    onLoadStop: _onLoadStop,
    onMainFrameError: _onMainFrameError,
    onVisitedHistory: _onVisitedHistory,
  );

  @override
  Widget build(BuildContext context) => Offstage(
    key: ValueKey(_tabId),
    offstage: _tabId != activeTabId,
    child: data.webViewService.host.buildView(_request),
  );

  void _updateTab(_BrowserTabUpdate update) =>
      unawaited(data.request.notifier.updateTab(_tabId, update));

  void _onTitleChanged(String? title) => _updateTab((
    url: null,
    title: title,
    isLoading: null,
    hasError: null,
    canGoBack: null,
    canGoForward: null,
  ));

  void _onLoadStart(String? url) => _updateTab((
    url: url,
    title: null,
    isLoading: true,
    hasError: false,
    canGoBack: null,
    canGoForward: null,
  ));

  void _onLoadStop(String? url) => unawaited(
    _updatePageState((
      notifier: data.request.notifier,
      webViewService: data.webViewService,
      conversationId: data.request.conversationId,
      tabId: _tabId,
      url: url,
    )),
  );

  void _onMainFrameError() => _updateTab((
    url: null,
    title: null,
    isLoading: false,
    hasError: true,
    canGoBack: null,
    canGoForward: null,
  ));

  void _onVisitedHistory(String? url) => _updateTab((
    url: url,
    title: null,
    isLoading: null,
    hasError: null,
    canGoBack: null,
    canGoForward: null,
  ));
}

Future<void> _updatePageState(_BrowserPageStateUpdate update) async {
  final page = await update.webViewService.host.pageStateIfAttached(
    sessionId: update.conversationId,
    tabId: update.tabId,
  );
  if (page == null) return;

  await update.notifier.updateTab(update.tabId, _pageStateUpdate(update, page));
}

_BrowserTabUpdate _pageStateUpdate(
  _BrowserPageStateUpdate update,
  BrowserPageState page,
) => (
  url: update.url ?? page.url,
  title: page.title,
  isLoading: false,
  hasError: false,
  canGoBack: page.canGoBack,
  canGoForward: page.canGoForward,
);

class const _SidebarTabStrip({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        Expanded(child: _BrowserTabList(data: data)),
        _BrowserNewTabButton(data: data),
      ],
    ),
  );
}

class const _BrowserTabList({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    scrollDirection: .horizontal,
    children: [
      _BrowserTabChipRow(data: data),
      _ToolResultTabChipRow(data: data),
      _WorkspaceTabChipRow(data: data),
    ],
  );
}

class const _BrowserTabChipRow({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      for (final tab in data.request.session.tabs)
        _SidebarBrowserTabChip(data: data, tab: tab),
    ],
  );
}

class const _ToolResultTabChipRow({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      for (final tab in data.request.toolResultTabs)
        _SidebarToolResultTabChip(data: data, tab: tab),
    ],
  );
}

class const _BrowserNewTabButton({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.browser_new_tab.tr();

    return AuraIconButton(
      icon: Icons.add,
      onPressed: _openTab,
      identifier: 'browser_new_tab_button',
      semanticLabel: label,
      tooltip: label,
    );
  }

  void _openTab() {
    if (data.selectedToolResultTab != null) {
      data.request.onSelectToolResultTab(null);
    }
    data.workspaceTabs.select('chooser');
  }
}

class const _SidebarTabChip({
  required final _SidebarTabTileData data,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
    child: _SidebarTabTile(data: data),
  );

  static _SidebarTabIdentifiers _browserTabIdentifiers(String tabId) => (
    tile: 'sidebar_tab_browser_$tabId',
    closeButton: 'browser_close_tab_$tabId',
  );

  static _SidebarTabIdentifiers _toolResultTabIdentifiers(String tabId) => (
    tile: 'sidebar_tab_tool_result_$tabId',
    closeButton: 'close_tool_result_tab_$tabId',
  );
}

typedef _SidebarTabTileData = ({
  _SidebarTabIdentifiers identifiers,
  String title,
  Widget child,
  bool selected,
  VoidCallback onSelect,
  VoidCallback onClose,
});
typedef _SidebarTabIdentifiers = ({String tile, String closeButton});
typedef _SidebarTabActions = ({VoidCallback onSelect, VoidCallback onClose});
typedef _SidebarTabRef = ({String kind, String id});

List<_SidebarTabRef> _sidebarTabs(_BrowserPanelData data) => [
  for (final tab in data.request.session.tabs) (kind: 'browser', id: tab.id),
  for (final tab in data.request.toolResultTabs) (kind: 'tool', id: tab.id),
  ..._workspaceSidebarTabs(data.workspaceTabs),
];

List<_SidebarTabRef> _workspaceSidebarTabs(_WorkspaceTabs tabs) => [
  if (tabs.selected.value == 'chooser') (kind: 'workspace', id: 'chooser'),
  if (tabs.directoryOpen.value) (kind: 'workspace', id: 'directory'),
  for (final item in tabs.items.value)
    (kind: 'workspace', id: _WorkspaceTabs.key(item)),
];

_SidebarTabRef? _activeSidebarTab(_BrowserPanelData data) {
  final selectedWorkspace = data.workspaceTabs.selected.value;
  final selectedToolResult = data.selectedToolResultTab;
  if (selectedToolResult != null) {
    return (kind: 'tool', id: selectedToolResult.id);
  }
  if (selectedWorkspace != null) {
    return (kind: 'workspace', id: selectedWorkspace);
  }
  final activeBrowser = data.activeTab;

  return activeBrowser == null ? null : (kind: 'browser', id: activeBrowser.id);
}

Future<void> _closeSidebarTab(
  _BrowserPanelData data,
  _SidebarTabRef closing,
) async {
  final isActive = _activeSidebarTab(data) == closing;
  final next = isActive ? _nextSidebarTab(_sidebarTabs(data), closing) : null;

  await _removeSidebarTab(data, closing, isActive, next);

  if (!isActive) return;

  await _selectNextSidebarTab(data, next);
}

Future<void> _removeSidebarTab(
  _BrowserPanelData data,
  _SidebarTabRef closing,
  bool isActive,
  _SidebarTabRef? next,
) async {
  switch (closing.kind) {
    case 'browser':
      await data.request.notifier.closeTab(closing.id);
    case 'tool':
      data.request.onCloseToolResultTab(closing.id);
    case 'workspace':
      final selectAfterClose = isActive && next?.kind == 'workspace'
          ? next?.id
          : null;
      data.workspaceTabs.close(closing.id, selectAfterClose: selectAfterClose);
  }
}

Future<void> _selectNextSidebarTab(
  _BrowserPanelData data,
  _SidebarTabRef? next,
) async {
  if (next == null) {
    _closeEmptySidebar(data);

    return;
  }

  switch (next.kind) {
    case 'browser':
      data.workspaceTabs.select(null);
      data.request.onSelectToolResultTab(null);
      await data.request.notifier.selectTab(next.id);
    case 'tool':
      data.workspaceTabs.select(null);
      data.request.onSelectToolResultTab(next.id);
    case 'workspace':
      data.request.onSelectToolResultTab(null);
      data.workspaceTabs.select(next.id);
  }
}

void _closeEmptySidebar(_BrowserPanelData data) {
  data.workspaceTabs.select(null);
  data.request.onSelectToolResultTab(null);
  data.onCloseSidebar();
}

_SidebarTabRef? _nextSidebarTab(List<_SidebarTabRef> tabs, _SidebarTabRef tab) {
  final index = tabs.indexOf(tab);
  if (index > 0) return tabs[index - 1];
  if (index == 0 && tabs.length > 1) return tabs[1];

  return null;
}

class const _SidebarTabTile({required final _SidebarTabTileData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 180),
    child: _SidebarTabAuraTile(data: data),
  );
}

class const _SidebarTabAuraTile({required final _SidebarTabTileData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: data.child,
      onTap: data.onSelect,
      variant: data.selected ? .selected : .ghost,
      size: .small,
      trailing: _SidebarTabCloseButton(
        identifier: data.identifiers.closeButton,
        onClose: data.onClose,
      ),
      expand: false,
      identifier: data.identifiers.tile,
      semanticLabel: data.title,
    );
  }
}

class const _SidebarBrowserTabChip({
  required final _BrowserPanelData data,
  required final BrowserTab tab,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabId = tab.id;
    final isSelected =
        data.selectedToolResultTab == null &&
        data.workspaceTabs.selected.value == null &&
        tabId == data.request.session.activeTabId;

    return _SidebarTabChip(
      data: _tileData(tabId, isSelected),
      key: isSelected
          ? data.activeTabKey
          : ValueKey('browser_sidebar_tab_$tabId'),
    );
  }

  _SidebarTabTileData _tileData(String tabId, bool isSelected) {
    final title = _tabLabel(tab);
    final actions = _tabActions(tabId);

    return (
      identifiers: _SidebarTabChip._browserTabIdentifiers(tabId),
      title: title,
      child: Text(title, overflow: .ellipsis, maxLines: 1),
      selected: isSelected,
      onSelect: actions.onSelect,
      onClose: actions.onClose,
    );
  }

  _SidebarTabActions _tabActions(String tabId) => (
    onSelect: () => _selectTab(tabId),
    onClose: () =>
        unawaited(_closeSidebarTab(data, (kind: 'browser', id: tabId))),
  );

  void _selectTab(String tabId) {
    data.request.onSelectToolResultTab(null);
    data.workspaceTabs.select(null);
    unawaited(data.request.notifier.selectTab(tabId));
  }
}

String _tabLabel(BrowserTab tab) {
  if (tab.title.isNotEmpty) return tab.title;
  final host = Uri.tryParse(tab.url)?.host;

  if (host == null || host.isEmpty) return tab.url;

  return host;
}

class const _SidebarToolResultTabChip({
  required final _BrowserPanelData data,
  required final SidebarToolResultTab tab,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabId = tab.id;
    final isSelected =
        data.workspaceTabs.selected.value == null &&
        data.selectedToolResultTab?.id == tabId;

    return _SidebarTabChip(
      data: _tileData(tabId, isSelected),
      key: isSelected
          ? data.activeTabKey
          : ValueKey('tool_result_sidebar_tab_$tabId'),
    );
  }

  _SidebarTabTileData _tileData(String tabId, bool isSelected) => (
    identifiers: _SidebarTabChip._toolResultTabIdentifiers(tabId),
    title: tab.title,
    child: Text(tab.title, overflow: .ellipsis, maxLines: 1),
    selected: isSelected,
    onSelect: _select,
    onClose: _close,
  );

  void _select() {
    data.workspaceTabs.select(null);
    data.request.onSelectToolResultTab(tab.id);
  }

  void _close() =>
      unawaited(_closeSidebarTab(data, (kind: 'tool', id: tab.id)));
}

class const _SidebarTabCloseButton({
  required final String identifier,
  required final VoidCallback onClose,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys.browser_close_tab.tr();

    return AuraIconButton(
      icon: Icons.close,
      onPressed: onClose,
      size: .extraSmall,
      identifier: identifier,
      semanticLabel: label,
      tooltip: label,
    );
  }
}

class const _SidebarToolResultContent({required final SidebarToolResultTab tab})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (tab.status case final status?) _SidebarToolResultStatus(text: status),
      Expanded(child: _SidebarToolResultText(content: tab.content)),
    ],
  );
}

class const _SidebarToolResultStatus({required final String text})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: .new(color: context.auraColors.onSurfaceVariant),
      ),
    ),
  );
}

class const _SidebarToolResultText({required final String content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.md);
    final style = TextStyle(
      color: context.auraColors.onSurface,
      fontFamily: context.auraTheme.typography.monoFontFamily,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing),
      child: SelectableText(content, style: style),
    );
  }
}

class const _BrowserAgentActivity({required final String activity})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    child: Row(
      children: [
        const Icon(Icons.smart_toy_outlined, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${LocaleKeys.browser_agent_activity.tr()}: '
            '${_browserActivityLabel(activity).tr()}',
            overflow: .ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

String _browserActivityLabel(String activity) =>
    _browserNavigationActivityLabel(activity) ??
    _browserPageActivityLabel(activity) ??
    LocaleKeys.browser_agent_activity;

String? _browserNavigationActivityLabel(String activity) => switch (activity) {
  'listing_tabs' => LocaleKeys.browser_agent_list_tabs,
  'open_tab' => LocaleKeys.browser_agent_open_tab,
  'close_tab' => LocaleKeys.browser_agent_close_tab,
  'select_tab' => LocaleKeys.browser_agent_select_tab,
  'going_back' => LocaleKeys.browser_agent_going_back,
  'went_back' => LocaleKeys.browser_agent_went_back,
  'going_forward' => LocaleKeys.browser_agent_going_forward,
  'went_forward' => LocaleKeys.browser_agent_went_forward,
  'reloading' => LocaleKeys.browser_agent_reloading,
  'reloaded' => LocaleKeys.browser_agent_reloaded,
  'navigating' => LocaleKeys.browser_agent_navigating,
  'navigated' => LocaleKeys.browser_agent_navigated,
  'running_javascript' => LocaleKeys.browser_agent_running_javascript,
  'ran_javascript' => LocaleKeys.browser_agent_ran_javascript,
  _ => null,
};

String? _browserPageActivityLabel(String activity) => switch (activity) {
  'snapshotting' => LocaleKeys.browser_agent_snapshotting,
  'snapshot_ready' => LocaleKeys.browser_agent_snapshot_ready,
  'finding' => LocaleKeys.browser_agent_finding,
  'found' => LocaleKeys.browser_agent_found,
  'waiting' => LocaleKeys.browser_agent_waiting,
  'waited' => LocaleKeys.browser_agent_waited,
  'wait_timed_out' => LocaleKeys.browser_agent_wait_timed_out,
  'scrolling' => LocaleKeys.browser_agent_scrolling,
  'scrolled' => LocaleKeys.browser_agent_scrolled,
  'capturing_screenshot' => LocaleKeys.browser_agent_capturing_screenshot,
  'screenshot_fallback' => LocaleKeys.browser_agent_screenshot_fallback,
  'screenshot_captured' => LocaleKeys.browser_agent_screenshot_captured,
  _ => null,
};

Future<void> _runBrowserCommand(
  BuildContext context,
  Future<void> Function() command,
) async {
  try {
    await command();
  } on Object {
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: const TextLocale(LocaleKeys.browser_action_error),
      variant: .error,
    );
  }
}

class _WorkspaceTabs {
  const new(
    this.items,
    this.selected,
    this.directoryOpen,
    this.names,
    this.notifier,
  );
  factory use(_BrowserSessionViewRequest request) => .new(
    useState([
      for (final tab in request.session.workspaceTabs)
        WorkspaceChatItem(id: tab.id, kind: tab.kind),
    ]),
    useState(request.session.selectedWorkspaceTabId),
    useState(
      request.session.workspaceTabs.any((tab) => tab.kind == 'directory'),
    ),
    useState({}),
    request.notifier,
  );

  final ValueNotifier<List<WorkspaceChatItem>> items;
  final ValueNotifier<String?> selected;
  final ValueNotifier<bool> directoryOpen;
  final ValueNotifier<Map<String, String>> names;
  final BrowserSessionNotifier notifier;
  static String key(WorkspaceChatItem item) => '${item.kind}:${item.id}';
  void select(String? id) {
    selected.value = id;
    _persist();
  }

  void open(WorkspaceChatItem item, [String? name]) {
    if (item.kind == 'directory') {
      directoryOpen.value = true;
      selected.value = 'directory';
      _persist();

      return;
    }
    _openItem(item, name);
    _persist();
  }

  void close(String id, {String? selectAfterClose}) {
    items.value = items.value.where((item) => key(item) != id).toList();
    if (id == 'directory') directoryOpen.value = false;
    if (selected.value == id) selected.value = selectAfterClose;
    _persist();
  }

  void _openItem(WorkspaceChatItem item, String? name) {
    final id = key(item);
    if (name != null) names.value = {...names.value, id: name};
    items.value = [
      ...items.value.where((existing) => key(existing) != id),
      item,
    ];
    selected.value = id;
  }

  void _persist() => unawaited(
    notifier.saveWorkspaceTabs(
      tabs: [
        for (final item in items.value)
          WorkspaceContentTab(id: item.id, kind: item.kind),
        if (directoryOpen.value)
          const WorkspaceContentTab(id: '', kind: 'directory'),
      ],
      selectedTabId: selected.value,
    ),
  );
}

const _sidebarChooserSpacing = 12.0;

class const _SidebarChooser({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      spacing: _sidebarChooserSpacing,
      runSpacing: _sidebarChooserSpacing,
      children: [
        AuraButton(
          onPressed: _openDirectory,
          child: const TextLocale(LocaleKeys.workspace_items_title),
          identifier: 'sidebar_open_directory',
        ),
        AuraButton(
          onPressed: _openBrowser,
          child: const TextLocale(LocaleKeys.app_skills_browser_title),
          identifier: 'sidebar_open_browser',
        ),
      ],
    ),
  );

  void _openDirectory() {
    data.workspaceTabs.open(const WorkspaceChatItem(id: '', kind: 'directory'));
  }

  void _openBrowser() {
    data.workspaceTabs.select(null);
    unawaited(data.request.notifier.openTab());
  }
}

class const _WorkspaceTabChipRow({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workspaceTabs = data.workspaceTabs;

    return Row(
      mainAxisSize: .min,
      children: [
        if (workspaceTabs.selected.value == 'chooser')
          _WorkspaceChooserChip(data: data),
        if (workspaceTabs.directoryOpen.value)
          _WorkspaceDirectoryChip(data: data),
        for (final item in workspaceTabs.items.value)
          _WorkspaceItemChip(data: data, item: item),
      ],
    );
  }
}

class const _WorkspaceChooserChip({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkspaceChip(
    data: data,
    id: 'chooser',
    title: LocaleKeys.browser_new_tab.tr(),
  );
}

class const _WorkspaceDirectoryChip({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkspaceChip(
    data: data,
    id: 'directory',
    title: LocaleKeys.workspace_items_title.tr(),
  );
}

class const _WorkspaceItemChip({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkspaceChip(
    data: data,
    id: _WorkspaceTabs.key(item),
    title:
        data.workspaceTabs.names.value[_WorkspaceTabs.key(item)] ??
        _title(item.kind),
    tableId: item.kind == 'table' ? item.id : null,
    workflowId: item.kind == 'workflow' ? item.id : null,
  );

  String _title(String kind) => switch (kind) {
    'table' => LocaleKeys.workspace_items_table.tr(),
    'file' => LocaleKeys.workspace_assets_file.tr(),
    'view' => LocaleKeys.workspace_views_title.tr(),
    'workflow' => LocaleKeys.workflow_editor_title.tr(),
    _ => LocaleKeys.workspace_items_title.tr(),
  };
}

class const _WorkspaceChip({
  required final _BrowserPanelData data,
  required final String id,
  required final String title,
  final String? tableId,
  final String? workflowId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _label(ref);
    final selected = data.workspaceTabs.selected.value == id;

    return _SidebarTabChip(
      data: _tileData(label, selected, context, ref),
      key: selected ? data.activeTabKey : null,
    );
  }

  String _label(WidgetRef ref) {
    final tableIdentifier = tableId;
    if (tableIdentifier != null) {
      return switch (ref.watch(
        workspaceTableProvider(data.request.workspaceId, tableIdentifier),
      )) {
        AsyncData(:final value) => value.name,
        AsyncLoading() || AsyncError() => title,
      };
    }
    final workflowIdentifier = workflowId;
    if (workflowIdentifier == null) return title;

    return switch (ref.watch(
      workflowProvider(data.request.workspaceId, workflowIdentifier),
    )) {
      AsyncData(:final value?) => value.name,
      AsyncData() || AsyncLoading() || AsyncError() => title,
    };
  }

  _SidebarTabTileData _tileData(
    String label,
    bool selected,
    BuildContext context,
    WidgetRef ref,
  ) => (
    identifiers: (
      tile: 'sidebar_workspace_$id',
      closeButton: 'sidebar_close_workspace_$id',
    ),
    title: label,
    child: Text(label, overflow: .ellipsis, maxLines: 1),
    selected: selected,
    onSelect: _select,
    onClose: () => _close(context, ref),
  );

  void _select() {
    data.request.onSelectToolResultTab(null);
    data.workspaceTabs.select(id);
  }

  void _close(BuildContext context, WidgetRef ref) =>
      unawaited(_closeAfterConfirmation(context, ref));

  Future<void> _closeAfterConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final workflowIdentifier = workflowId;
    if (workflowIdentifier != null &&
        ref
            .read(
              workflowEditorProvider(
                data.request.workspaceId,
                workflowIdentifier,
              ),
            )
            .isDirty &&
        await UnsavedChangesDialog.confirm(context) != true) {
      return;
    }
    if (!context.mounted) return;
    await _closeSidebarTab(data, (kind: 'workspace', id: id));
  }
}

class const _WorkspaceTabSlot({required final _BrowserPanelData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workspaceTabs = data.workspaceTabs;
    final selected = workspaceTabs.selected.value;

    return Stack(
      children: [
        if (workspaceTabs.directoryOpen.value)
          _WorkspaceDirectorySlot(data: data, selected: selected),
        for (final item in workspaceTabs.items.value)
          _WorkspaceTabEntry(data: data, item: item, selected: selected),
      ],
    );
  }
}

class const _WorkspaceDirectorySlot({
  required final _BrowserPanelData data,
  required final String? selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Offstage(
    offstage: selected != 'directory',
    child: SidebarDirectory(
      workspaceId: data.request.workspaceId,
      onOpen: data.workspaceTabs.open,
    ),
  );
}

class const _WorkspaceTabEntry({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
  required final String? selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final id = _WorkspaceTabs.key(item);
    final active = id == selected;

    return Positioned.fill(
      child: Offstage(
        offstage: !active,
        child: TickerMode(
          enabled: active,
          child: KeyedSubtree(
            key: ValueKey(id),
            child: _WorkspaceTabContent(data: data, item: item),
          ),
        ),
      ),
    );
  }
}

class const _WorkspaceTabContent({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (item.kind) {
      'view' => _WorkspaceViewTab(data: data, item: item),
      'table' => _WorkspaceTableTab(data: data, item: item),
      'file' => _WorkspaceFileTab(data: data, item: item),
      'workflow' => _WorkspaceWorkflowTab(data: data, item: item),
      _ => const SizedBox.shrink(),
    };
  }
}

void _closeWorkspaceContent(_BrowserPanelData data, WorkspaceChatItem item) =>
    unawaited(
      _closeSidebarTab(data, (kind: 'workspace', id: _WorkspaceTabs.key(item))),
    );

class const _WorkspaceViewTab({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceViewScreen(
    workspaceId: data.request.workspaceId,
    viewId: item.id,
    onBack: () => _closeWorkspaceContent(data, item),
    compact: true,
  );
}

class const _WorkspaceTableTab({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceTableScreen(
    workspaceId: data.request.workspaceId,
    tableId: item.id,
    onBack: () => _closeWorkspaceContent(data, item),
    compact: true,
  );
}

class const _WorkspaceFileTab({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkspaceFileScreen(
    workspaceId: data.request.workspaceId,
    fileId: item.id,
    onBack: () => _closeWorkspaceContent(data, item),
    compact: true,
  );
}

class const _WorkspaceWorkflowTab({
  required final _BrowserPanelData data,
  required final WorkspaceChatItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WorkflowEditorScreen(
    workspaceId: data.request.workspaceId,
    workflowId: item.id,
    compact: true,
    onBack: () => _closeWorkspaceContent(data, item),
  );
}
