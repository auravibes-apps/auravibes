import 'dart:async';

import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/models/sidebar_tool_result_tab.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
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
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(
      browserSessionProvider(workspaceId, conversationId),
    );

    return switch (sessionAsync) {
      AsyncData(:final value) => _BrowserSessionView(
        conversationId: conversationId,
        session: value,
        notifier: ref.read(
          browserSessionProvider(workspaceId, conversationId).notifier,
        ),
        toolResultTabs: toolResultTabs,
        selectedToolResultTabId: selectedToolResultTabId,
        onSelectToolResultTab: onSelectToolResultTab,
        onCloseToolResultTab: onCloseToolResultTab,
      ),
      AsyncError() => const Center(
        child: TextLocale(LocaleKeys.browser_load_error),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

class const _BrowserSessionView({
  required final String conversationId,
  required final BrowserSessionState session,
  required final BrowserSessionNotifier notifier,
  required final List<SidebarToolResultTab> toolResultTabs,
  required final String? selectedToolResultTabId,
  required final ValueChanged<String?> onSelectToolResultTab,
  required final ValueChanged<String> onCloseToolResultTab,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webViewService = ref.read(browserWebViewServiceProvider);
    final activeTab = session.activeTab;
    final selectedToolResultTab = toolResultTabs
        .where((tab) => tab.id == selectedToolResultTabId)
        .firstOrNull;
    final activeTabKey = useMemoized(GlobalKey.new, const []);
    void Function()? scrollToActiveTab() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeTabContext = activeTabKey.currentContext;
        if (activeTabContext == null) return;
        Scrollable.ensureVisible(
          activeTabContext,
          duration: const Duration(milliseconds: 180),
        );
      });

      return null;
    }

    useEffect(scrollToActiveTab, [selectedToolResultTab?.id ?? activeTab?.id]);
    final addressController = useTextEditingController(
      text: activeTab?.url ?? '',
      keys: [activeTab?.id, activeTab?.url],
    );

    return Column(
      children: [
        _SidebarTabStrip(
          session: session,
          toolResultTabs: toolResultTabs,
          selectedToolResultTabId: selectedToolResultTab?.id,
          activeTabKey: activeTabKey,
          onSelectBrowserTab: (tabId) {
            onSelectToolResultTab(null);
            unawaited(notifier.selectTab(tabId));
          },
          onSelectToolResultTab: onSelectToolResultTab,
          onCloseBrowserTab: (tabId) => unawaited(notifier.closeTab(tabId)),
          onCloseToolResultTab: onCloseToolResultTab,
          onOpen: () => unawaited(notifier.openTab()),
        ),
        Expanded(
          child: Stack(
            fit: .expand,
            children: [
              if (session.isSuspended)
                Positioned.fill(
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
                ),
              if (activeTab != null && !session.isSuspended)
                Offstage(
                  offstage: selectedToolResultTab != null,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            AuraIconButton(
                              icon: Icons.arrow_back,
                              onPressed: session.canGoBack
                                  ? () => unawaited(
                                      _runBrowserCommand(
                                        context,
                                        () => webViewService.goBack(
                                          sessionId: conversationId,
                                          tabId: activeTab.id,
                                        ),
                                      ),
                                    )
                                  : null,
                              tooltip: LocaleKeys.browser_go_back.tr(),
                            ),
                            AuraIconButton(
                              icon: Icons.arrow_forward,
                              onPressed: session.canGoForward
                                  ? () => unawaited(
                                      _runBrowserCommand(
                                        context,
                                        () => webViewService.goForward(
                                          sessionId: conversationId,
                                          tabId: activeTab.id,
                                        ),
                                      ),
                                    )
                                  : null,
                              tooltip: LocaleKeys.browser_go_forward.tr(),
                            ),
                            AuraIconButton(
                              icon: session.isLoading
                                  ? Icons.close
                                  : Icons.refresh,
                              onPressed: () => unawaited(
                                _runBrowserCommand(
                                  context,
                                  () => session.isLoading
                                      ? webViewService.stopLoading(
                                          sessionId: conversationId,
                                          tabId: activeTab.id,
                                        )
                                      : webViewService.reload(
                                          sessionId: conversationId,
                                          tabId: activeTab.id,
                                        ),
                                ),
                              ),
                              tooltip: session.isLoading
                                  ? LocaleKeys.browser_stop.tr()
                                  : LocaleKeys.browser_reload.tr(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AuraInput(
                                controller: addressController,
                                prefixIcon: const AuraIcon(Icons.public),
                                textInputAction: .go,
                                onSubmitted: (url) => unawaited(
                                  _runBrowserCommand(
                                    context,
                                    () => notifier.navigate(url),
                                  ),
                                ),
                                identifier: 'browser_address_input',
                                semanticLabel: LocaleKeys.browser_address.tr(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            for (final tab in session.tabs)
                              Offstage(
                                key: ValueKey(tab.id),
                                offstage: tab.id != activeTab.id,
                                child: webViewService.buildView(
                                  sessionId: conversationId,
                                  tabId: tab.id,
                                  initialUrl: tab.url,
                                  onTitleChanged: (title) => unawaited(
                                    notifier.updateTab(tab.id, title: title),
                                  ),
                                  onLoadStart: (url) => unawaited(
                                    notifier.updateTab(
                                      tab.id,
                                      url: url,
                                      isLoading: true,
                                      hasError: false,
                                    ),
                                  ),
                                  onLoadStop: (url) => unawaited(
                                    _updatePageState(
                                      notifier,
                                      webViewService,
                                      conversationId,
                                      tab.id,
                                      url,
                                    ),
                                  ),
                                  onMainFrameError: () => unawaited(
                                    notifier.updateTab(
                                      tab.id,
                                      isLoading: false,
                                      hasError: true,
                                    ),
                                  ),
                                  onVisitedHistory: (url) => unawaited(
                                    notifier.updateTab(tab.id, url: url),
                                  ),
                                ),
                              ),
                            if (session.hasError)
                              const Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: TextLocale(
                                    LocaleKeys.browser_page_error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (session.agentActivity case final activity?)
                        _BrowserAgentActivity(activity: activity),
                    ],
                  ),
                ),
              if (activeTab == null &&
                  selectedToolResultTab == null &&
                  !session.isSuspended)
                const Center(child: TextLocale(LocaleKeys.browser_empty_state)),
              if (selectedToolResultTab case final resultTab?)
                Positioned.fill(
                  child: _SidebarToolResultContent(tab: resultTab),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _updatePageState(
  BrowserSessionNotifier notifier,
  BrowserWebViewService webViewService,
  String conversationId,
  String tabId,
  String? url,
) async {
  final page = await webViewService.pageStateIfAttached(
    sessionId: conversationId,
    tabId: tabId,
  );
  if (page == null ||
      !webViewService.hasController(sessionId: conversationId, tabId: tabId)) {
    return;
  }

  await notifier.updateTab(
    tabId,
    url: url ?? page.url,
    title: page.title,
    isLoading: false,
    hasError: false,
    canGoBack: page.canGoBack,
    canGoForward: page.canGoForward,
  );
}

class const _SidebarTabStrip({
  required final BrowserSessionState session,
  required final List<SidebarToolResultTab> toolResultTabs,
  required final String? selectedToolResultTabId,
  required final GlobalKey activeTabKey,
  required final ValueChanged<String> onSelectBrowserTab,
  required final ValueChanged<String?> onSelectToolResultTab,
  required final ValueChanged<String> onCloseBrowserTab,
  required final ValueChanged<String> onCloseToolResultTab,
  required final VoidCallback onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        Expanded(
          child: ListView(
            scrollDirection: .horizontal,
            children: [
              for (final tab in session.tabs)
                _SidebarTabChip(
                  keyId: 'browser_${tab.id}',
                  title: _tabLabel(tab),
                  selected:
                      selectedToolResultTabId == null &&
                      tab.id == session.activeTabId,
                  closeIdentifier: 'browser_close_tab_${tab.id}',
                  onSelect: () => onSelectBrowserTab(tab.id),
                  onClose: () => onCloseBrowserTab(tab.id),
                  key:
                      selectedToolResultTabId == null &&
                          tab.id == session.activeTabId
                      ? activeTabKey
                      : ValueKey('browser_sidebar_tab_${tab.id}'),
                ),
              for (final tab in toolResultTabs)
                _SidebarTabChip(
                  keyId: 'tool_result_${tab.id}',
                  title: tab.title,
                  selected: selectedToolResultTabId == tab.id,
                  closeIdentifier: 'close_tool_result_tab_${tab.id}',
                  onSelect: () => onSelectToolResultTab(tab.id),
                  onClose: () => onCloseToolResultTab(tab.id),
                  key: selectedToolResultTabId == tab.id
                      ? activeTabKey
                      : ValueKey('tool_result_sidebar_tab_${tab.id}'),
                ),
            ],
          ),
        ),
        AuraIconButton(
          icon: Icons.add,
          onPressed: onOpen,
          identifier: 'browser_new_tab_button',
          semanticLabel: LocaleKeys.browser_new_tab.tr(),
          tooltip: LocaleKeys.browser_new_tab.tr(),
        ),
      ],
    ),
  );

  String _tabLabel(BrowserTab tab) {
    if (tab.title.isNotEmpty) return tab.title;
    final host = Uri.tryParse(tab.url)?.host;

    if (host == null || host.isEmpty) return tab.url;

    return host;
  }
}

class const _SidebarTabChip({
  required final String keyId,
  required final String title,
  required final bool selected,
  required final String closeIdentifier,
  required final VoidCallback onSelect,
  required final VoidCallback onClose,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: AuraTile(
        child: Text(title, overflow: .ellipsis, maxLines: 1),
        onTap: onSelect,
        variant: selected ? .selected : .ghost,
        size: .small,
        trailing: AuraIconButton(
          icon: Icons.close,
          onPressed: onClose,
          size: .extraSmall,
          identifier: closeIdentifier,
          semanticLabel: LocaleKeys.browser_close_tab.tr(),
          tooltip: LocaleKeys.browser_close_tab.tr(),
        ),
        expand: false,
        identifier: 'sidebar_tab_$keyId',
        semanticLabel: title,
      ),
    ),
  );
}

class const _SidebarToolResultContent({required final SidebarToolResultTab tab})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (tab.status case final status?)
        Padding(
          padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              status,
              style: .new(color: context.auraColors.onSurfaceVariant),
            ),
          ),
        ),
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
          child: SelectableText(
            tab.content,
            style: .new(
              color: context.auraColors.onSurface,
              fontFamily: context.auraTheme.typography.monoFontFamily,
            ),
          ),
        ),
      ),
    ],
  );
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
            '${_activityLabel(activity).tr()}',
            overflow: .ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );

  String _activityLabel(String activity) => switch (activity) {
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
    _ => LocaleKeys.browser_agent_activity,
  };
}

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
