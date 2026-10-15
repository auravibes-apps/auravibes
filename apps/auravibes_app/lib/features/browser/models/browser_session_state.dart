typedef BrowserTabUpdate = ({
  String? url,
  String? title,
  bool? isLoading,
  bool? hasError,
  bool? canGoBack,
  bool? canGoForward,
});
typedef _BrowserSessionUpdate = ({
  List<BrowserTab>? tabs,
  String? activeTabId,
  bool? isLoading,
  bool? hasError,
  bool? canGoBack,
  bool? canGoForward,
  bool? isSuspended,
  String? agentActivity,
  int? agentActionRevision,
  bool clearAgentActivity,
});
typedef _BrowserSessionTabs = ({List<BrowserTab> tabs, String activeTabId});
typedef _BrowserSessionMetadata = ({
  bool isSuspended,
  String? agentActivity,
  int agentActionRevision,
});

class const BrowserSessionState({
  required final List<BrowserTab> tabs,
  required final String activeTabId,
  final bool isLoading = false,
  final bool hasError = false,
  final bool canGoBack = false,
  final bool canGoForward = false,
  final bool isSuspended = false,
  final String? agentActivity,
  final int agentActionRevision = 0,
}) {
  factory initial() => const BrowserSessionState(tabs: [], activeTabId: '');

  factory fromJson(Map<String, dynamic> json) => _browserSessionFromJson(json);

  BrowserTab? get activeTab =>
      tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  Map<String, Object?> toJson() => {
    'tabs': tabs.map((tab) => tab.toJson()).toList(),
    'activeTabId': activeTabId,
    'isSuspended': isSuspended,
  };

  BrowserSessionState copyWith({
    List<BrowserTab>? tabs,
    String? activeTabId,
    bool? isLoading,
    bool? hasError,
    bool? canGoBack,
    bool? canGoForward,
    bool? isSuspended,
    String? agentActivity,
    int? agentActionRevision,
    bool clearAgentActivity = false,
  }) => _copyBrowserSession(this, (
    tabs: tabs,
    activeTabId: activeTabId,
    isLoading: isLoading,
    hasError: hasError,
    canGoBack: canGoBack,
    canGoForward: canGoForward,
    isSuspended: isSuspended,
    agentActivity: agentActivity,
    agentActionRevision: agentActionRevision,
    clearAgentActivity: clearAgentActivity,
  ));
}

BrowserSessionState _browserSessionFromJson(Map<String, dynamic> json) {
  _validateBrowserSessionJson(json);
  final tabs = _decodeBrowserTabs(json['tabs'] as List<Object?>);

  return _restoreBrowserSession(
    tabs,
    json['activeTabId'] as String?,
    json['isSuspended'] as bool? ?? false,
  );
}

BrowserSessionState _restoreBrowserSession(
  List<BrowserTab> tabs,
  String? activeTabId,
  bool isSuspended,
) {
  final fallbackTab = tabs.firstOrNull;
  if (fallbackTab == null) return BrowserSessionState.initial();
  final activeTab = tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  return BrowserSessionState(
    tabs: tabs,
    activeTabId: activeTab?.id ?? fallbackTab.id,
    isSuspended: isSuspended,
  );
}

BrowserSessionState _copyBrowserSession(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) {
  final tabs = _copyBrowserSessionTabs(current, update);
  final navigation = _copyBrowserNavigation(current, update);
  final metadata = _copyBrowserSessionMetadata(current, update);

  return _browserSessionFromUpdates(tabs, navigation, metadata);
}

BrowserSessionState _browserSessionFromUpdates(
  _BrowserSessionTabs tabs,
  ({bool isLoading, bool hasError, bool canGoBack, bool canGoForward})
  navigation,
  _BrowserSessionMetadata metadata,
) => BrowserSessionState(
  tabs: tabs.tabs,
  activeTabId: tabs.activeTabId,
  isLoading: navigation.isLoading,
  hasError: navigation.hasError,
  canGoBack: navigation.canGoBack,
  canGoForward: navigation.canGoForward,
  isSuspended: metadata.isSuspended,
  agentActivity: metadata.agentActivity,
  agentActionRevision: metadata.agentActionRevision,
);

_BrowserSessionTabs _copyBrowserSessionTabs(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) => (
  tabs: update.tabs ?? current.tabs,
  activeTabId: update.activeTabId ?? current.activeTabId,
);

({bool isLoading, bool hasError, bool canGoBack, bool canGoForward})
_copyBrowserNavigation(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) => (
  isLoading: update.isLoading ?? current.isLoading,
  hasError: update.hasError ?? current.hasError,
  canGoBack: update.canGoBack ?? current.canGoBack,
  canGoForward: update.canGoForward ?? current.canGoForward,
);

_BrowserSessionMetadata _copyBrowserSessionMetadata(
  BrowserSessionState current,
  _BrowserSessionUpdate update,
) => (
  isSuspended: update.isSuspended ?? current.isSuspended,
  agentActivity: update.clearAgentActivity
      ? null
      : update.agentActivity ?? current.agentActivity,
  agentActionRevision:
      update.agentActionRevision ?? current.agentActionRevision,
);

void _validateBrowserSessionJson(Map<String, dynamic> json) {
  final tabs = json['tabs'];
  final activeTabId = json['activeTabId'];
  final isSuspended = json['isSuspended'];
  if (tabs is! List ||
      activeTabId != null && activeTabId is! String ||
      isSuspended != null && isSuspended is! bool) {
    throw const FormatException('Invalid browser session.');
  }
}

List<BrowserTab> _decodeBrowserTabs(List<Object?> tabs) => tabs.map((item) {
  if (item is! Map<String, dynamic>) {
    throw const FormatException('Invalid browser tab.');
  }

  return BrowserTab.fromJson(item);
}).toList();

class const BrowserTab({
  required final String id,
  required final String url,
  final String title = '',
}) {
  factory fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final url = json['url'];
    final title = json['title'];
    if (id is! String || url is! String || title != null && title is! String) {
      throw const FormatException('Invalid browser tab.');
    }

    return BrowserTab(id: id, url: url, title: title is String ? title : '');
  }

  BrowserTab copyWith({String? url, String? title}) =>
      BrowserTab(id: id, url: url ?? this.url, title: title ?? this.title);

  Map<String, Object?> toJson() => {'id': id, 'url': url, 'title': title};
}
